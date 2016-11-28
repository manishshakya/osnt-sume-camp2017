//
// Copyright (c) 2016 University of Cambridge
// Copyright (c) 2016 Jong Hun Han
// All rights reserved.
//
// This software was developed by University of Cambridge Computer Laboratory
// under the ENDEAVOUR project (grant agreement 644960) as part of
// the European Union's Horizon 2020 research and innovation programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA Open Systems C.I.C. (NetFPGA) under one or more
// contributor license agreements. See the NOTICE file distributed with this
// work for additional information regarding copyright ownership. NetFPGA
// licenses this file to you under the NetFPGA Hardware-Software License,
// Version 1.0 (the License); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at:
//
// http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@


`timescale 1ns/1ps

module osnt_sume_10g_tx_queue
#(
   // Master AXI Stream Data Width
   parameter   C_M_AXIS_DATA_WIDTH  = 64,
   parameter   C_S_AXIS_DATA_WIDTH  = 64,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXI_DATA_WIDTH   = 32,
   parameter   TS_WIDTH             = 64
)
(
   //Global Ports
   input                                           axis_aclk,
   input                                           axis_resetn,

   // Master Stream Ports
   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]        m_axis_tdata,
   output   reg   [(C_M_AXIS_DATA_WIDTH/8)-1:0]    m_axis_tkeep,
   output   reg                                    m_axis_tuser,
   output   reg                                    m_axis_tvalid,
   input                                           m_axis_tready,
   output   reg                                    m_axis_tlast,

   // Slave Stream Ports
   input          [C_S_AXIS_DATA_WIDTH-1:0]        s_axis_tdata,
   input          [(C_S_AXIS_DATA_WIDTH/8)-1:0]    s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]       s_axis_tuser,
   input                                           s_axis_tvalid,
   output                                          s_axis_tready,
   input                                           s_axis_tlast,

   input                                           clear,
   output   reg   [C_S_AXIS_DATA_WIDTH-1:0]        tx_pkt_count,

   // tx timestamp position 
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_ts_pos,
   input          [TS_WIDTH-1:0]                   timestamp_156
);

function integer log2;
   input integer number;
   begin
      log2=0;
      while(2**log2<number) begin
         log2=log2+1;
      end
   end
endfunction//log2

localparam  MAX_PKT_SIZE = 4000; // In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_S_AXIS_DATA_WIDTH/8));

localparam  SIGNATURE = 32'hefbeadde;

`define  IDLE     0
`define  HEAD     1
`define  SEND     2
`define  WAIT     3
`define  DROP     4

`define  TX_IDLE  0
`define  TX_WRITE 1
`define  TX_DROP  2

wire  [C_S_AXIS_DATA_WIDTH-1:0]        tx0_fifo_out_tdata;
wire  [(C_S_AXIS_DATA_WIDTH/8)-1:0]    tx0_fifo_out_tkeep;
wire  [C_S_AXIS_TUSER_WIDTH-1:0]       tx0_fifo_out_tuser;
wire                                   tx0_fifo_out_tlast;
wire  tx0_fifo_nearly_full;
wire  tx0_fifo_empty;
reg   tx0_fifo_rden;

reg   [C_S_AXIS_DATA_WIDTH-1:0]        tx1_fifo_in_tdata;
reg   [(C_S_AXIS_DATA_WIDTH/8)-1:0]    tx1_fifo_in_tkeep;
reg   [C_S_AXIS_TUSER_WIDTH-1:0]       tx1_fifo_in_tuser;
reg                                    tx1_fifo_in_tlast;

wire  [C_S_AXIS_DATA_WIDTH-1:0]        tx1_fifo_out_tdata;
wire  [(C_S_AXIS_DATA_WIDTH/8)-1:0]    tx1_fifo_out_tkeep;
wire  [C_S_AXIS_TUSER_WIDTH-1:0]       tx1_fifo_out_tuser;
wire                                   tx1_fifo_out_tlast;

wire  tx1_fifo_nearly_full;
wire  tx1_fifo_empty;
reg   tx1_fifo_wren;
reg   tx1_fifo_rden;

localparam TLAST_WIDTH = 1;

wire  tx0_last_out;
wire  tx0_last_nearly_full;
wire  tx0_last_empty;
reg   tx0_last_rden;
wire  tx0_last_wren;

reg   [TLAST_WIDTH:0]    tx1_last_in;
wire  [TLAST_WIDTH:0]    tx1_last_out;
wire  tx1_last_nearly_full;
wire  tx1_last_empty;
reg   tx1_last_rden;
reg   tx1_last_wren;

reg   [31:0]   pkt_cnt, pkt_cnt_next;

assign tx0_last_wren = s_axis_tlast & s_axis_tvalid & ~tx0_fifo_nearly_full;

assign s_axis_tready = ~tx0_fifo_nearly_full;

reg   r_m_axis_tlast;
always @(posedge axis_aclk)
   if (~axis_resetn) begin
      r_m_axis_tlast    <= 0;
   end
   else begin
      r_m_axis_tlast    <= m_axis_tlast & m_axis_tvalid & m_axis_tready;
   end

wire  w_m_axis_tlast = (m_axis_tlast & m_axis_tvalid & m_axis_tready) & ~r_m_axis_tlast;

always @(posedge axis_aclk)
   if (~axis_resetn) begin
      tx_pkt_count   <= 0;
   end
   else if (clear) begin
      tx_pkt_count   <= 0;
   end
   else if (w_m_axis_tlast) begin
      tx_pkt_count   <= tx_pkt_count + 1;
   end

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_S_AXIS_DATA_WIDTH/8)+C_S_AXIS_DATA_WIDTH                  ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                                   )
)
tx0_fifo
(
   //Outputs
   .dout             (  {tx0_fifo_out_tlast, tx0_fifo_out_tuser, tx0_fifo_out_tkeep, tx0_fifo_out_tdata}    ),
   .full             (                                                                                      ),
   .nearly_full      (  tx0_fifo_nearly_full                                                                ),
   .prog_full        (                                                                                      ),
   .empty            (  tx0_fifo_empty                                                                      ),
   //Inputs
   .din              (  {s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}                            ),
   .wr_en            (  s_axis_tvalid & ~tx0_fifo_nearly_full                                               ),
   .rd_en            (  tx0_fifo_rden                                                                       ),
   .reset            (  ~axis_resetn                                                                        ),
   .clk              (  axis_aclk                                                                           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  TLAST_WIDTH                                           ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                     )
)
tx0_last
(
   //Outputs
   .dout             (  tx0_last_out                                          ),
   .full             (                                                        ),
   .nearly_full      (  tx0_last_nearly_full                                  ),
   .prog_full        (                                                        ),
   .empty            (  tx0_last_empty                                        ),
   //Inputs
   .din              (  s_axis_tlast                                          ),
   .wr_en            (  tx0_last_wren                                         ),
   .rd_en            (  tx0_last_rden                                         ),
   .reset            (  ~axis_resetn                                          ),
   .clk              (  axis_aclk                                             )
);

//Start laste machine for sending to next modules.
//States : idle, write data and tuser, write data, drop.
reg   [3:0]    current_st, next_st;
reg   [C_S_AXI_DATA_WIDTH-1:0]   ts_cnt, ts_cnt_next;
always @(posedge axis_aclk)
   if (~axis_resetn) begin
      current_st  <= `IDLE;
      ts_cnt      <= 1;
      pkt_cnt     <= 0;
   end
   else begin
      current_st  <= next_st;
      ts_cnt      <= ts_cnt_next;
      pkt_cnt     <= pkt_cnt_next;
   end

reg   [TS_WIDTH-1:0] r_ts_value;
always @(posedge axis_aclk)
   if (~axis_resetn)
      r_ts_value  <= 0;
   else if (next_st == `HEAD)
      r_ts_value  <= timestamp_156;


always @(*) begin
   m_axis_tdata   = 0;
   m_axis_tkeep   = 0;
   m_axis_tuser   = 0;
   m_axis_tlast   = 0;
   m_axis_tvalid  = 0;
   pkt_cnt_next   = pkt_cnt;
   ts_cnt_next    = 1;
   tx0_fifo_rden  = 0;
   tx0_last_rden  = 0;
   next_st        = `IDLE;
   case (current_st)
      // IDLE makes a gap between packets.
      `IDLE : begin
         m_axis_tdata   = 0;
         m_axis_tkeep   = 0;
         m_axis_tuser   = 0;
         m_axis_tlast   = 0;
         m_axis_tvalid  = 0;
         pkt_cnt_next   = pkt_cnt;
         ts_cnt_next    = 1;
         tx0_fifo_rden  = 0;
         tx0_last_rden  = 0;
         next_st        = (~tx0_last_empty & ~tx0_fifo_empty) ? `HEAD : `IDLE;
      end
      `HEAD : begin
         if (tx_ts_pos != 0 && ts_cnt == tx_ts_pos) begin
            m_axis_tdata   = r_ts_value;
         end
         else begin
            m_axis_tdata   = tx0_fifo_out_tdata;
         end
         m_axis_tkeep   = tx0_fifo_out_tkeep;
         m_axis_tuser   = 0;
         m_axis_tlast   = tx0_fifo_out_tlast;
         // m_axis_tready wait until tvlaid is asserted.
         m_axis_tvalid  = (~tx0_last_empty & ~tx0_fifo_empty);
         pkt_cnt_next   = (~tx0_last_empty & ~tx0_fifo_empty & m_axis_tready) ? pkt_cnt + 1 : pkt_cnt;
         ts_cnt_next    = (~tx0_last_empty & ~tx0_fifo_empty & m_axis_tready) ? ts_cnt + 1 : 1;
         tx0_fifo_rden  = (~tx0_last_empty & ~tx0_fifo_empty & m_axis_tready);
         tx0_last_rden  = (~tx0_last_empty & ~tx0_fifo_empty & m_axis_tready);
         next_st        = (~tx0_last_empty & ~tx0_fifo_empty & m_axis_tready & tx0_fifo_out_tlast) ? `IDLE :
                          (~tx0_last_empty & ~tx0_fifo_empty & m_axis_tready                     ) ? `SEND : `HEAD;
      end
      `SEND : begin
         if (tx_ts_pos != 0 && ts_cnt == tx_ts_pos) begin
            m_axis_tdata   = r_ts_value;
         end
         else if (tx_ts_pos != 0 && ts_cnt == (tx_ts_pos + 1)) begin
            m_axis_tdata   = {pkt_cnt, SIGNATURE};
         end
         else begin
            m_axis_tdata   = tx0_fifo_out_tdata;
         end
         m_axis_tkeep   = tx0_fifo_out_tkeep;
         m_axis_tuser   = 0;
         m_axis_tlast   = tx0_fifo_out_tlast;
         m_axis_tvalid  =  ~tx0_fifo_empty;
         pkt_cnt_next   = pkt_cnt;
         ts_cnt_next    = (~tx0_fifo_empty & m_axis_tready) ? ts_cnt + 1 : ts_cnt;
         tx0_fifo_rden  = (~tx0_fifo_empty & m_axis_tready);
         next_st        = (~tx0_fifo_empty & m_axis_tready & tx0_fifo_out_tlast) ? `IDLE : `SEND;
      end
   endcase
end

endmodule
