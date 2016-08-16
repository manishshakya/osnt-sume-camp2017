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

module osnt_sume_10g_rx_queue
#(
   // Master AXI Stream Data Width
   parameter   C_M_AXIS_DATA_WIDTH  = 64,
   parameter   C_S_AXIS_DATA_WIDTH  = 64,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXI_DATA_WIDTH   = 32,
   parameter   SRC_PORT_VAL         = 8'h00,
   parameter   SRC_PORT_POS         = 16,
   parameter   PKT_SIZE_POS         = 0,
   parameter   TS_WIDTH             = 64,
   parameter   META_DATA_WIDTH      = 30
)
(
   //Global Ports
   input                                           axis_aclk,
   input                                           axis_resetn,

   // Master Stream Ports
   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]        m_axis_tdata,
   output   reg   [(C_M_AXIS_DATA_WIDTH/8)-1:0]    m_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]       m_axis_tuser,
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

   // Async fifo for meta data stats
   input                                           rx_stat_valid,
   input          [META_DATA_WIDTH-1:0]            rx_stat_vector,

   input                                           clear,
   output   reg   [C_S_AXIS_DATA_WIDTH-1:0]        rx_pkt_count,

   // rx timestamp position 
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_ts_pos,
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

localparam  MAX_PKT_SIZE = 9100; // In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_S_AXIS_DATA_WIDTH/8));

`define  IDLE     0
`define  HEAD     1
`define  SEND     2
`define  DROP     3

`define  RX_IDLE  0
`define  RX_WRITE 1
`define  RX_DROP  2

assign s_axis_tready = 1;

wire  [C_S_AXIS_DATA_WIDTH-1:0]        rx0_fifo_out_tdata;
wire  [(C_S_AXIS_DATA_WIDTH/8)-1:0]    rx0_fifo_out_tkeep;
wire  [C_S_AXIS_TUSER_WIDTH-1:0]       rx0_fifo_out_tuser;
wire                                   rx0_fifo_out_tlast;
wire  rx0_fifo_nearly_full;
wire  rx0_fifo_empty;
reg   rx0_fif0_wren;
reg   rx0_fifo_rden;

reg   [C_S_AXIS_DATA_WIDTH-1:0]        rx1_fifo_in_tdata;
reg   [(C_S_AXIS_DATA_WIDTH/8)-1:0]    rx1_fifo_in_tkeep;
reg   [C_S_AXIS_TUSER_WIDTH-1:0]       rx1_fifo_in_tuser;
reg                                    rx1_fifo_in_tlast;

wire  [C_S_AXIS_DATA_WIDTH-1:0]        rx1_fifo_out_tdata;
wire  [(C_S_AXIS_DATA_WIDTH/8)-1:0]    rx1_fifo_out_tkeep;
wire  [C_S_AXIS_TUSER_WIDTH-1:0]       rx1_fifo_out_tuser;
wire                                   rx1_fifo_out_tlast;

wire  rx1_fifo_nearly_full;
wire  rx1_fifo_empty;
reg   rx1_fifo_wren;
reg   rx1_fifo_rden;

localparam META_TS_WIDTH = META_DATA_WIDTH + TS_WIDTH;

wire  [META_TS_WIDTH-1:0]  rx0_stat_out;
wire  rx0_stat_nearly_full;
wire  rx0_stat_empty;
reg   rx0_stat_rden;
wire  rx0_stat_wren;

reg   [META_TS_WIDTH:0]    rx1_stat_in;
wire  [META_TS_WIDTH:0]    rx1_stat_out;
wire  rx1_stat_nearly_full;
wire  rx1_stat_empty;
reg   rx1_stat_rden;
reg   rx1_stat_wren;


reg   r_rx_stat_valid;
always @(posedge axis_aclk)
   if (~axis_resetn)
      r_rx_stat_valid   <= 0;
   else
      r_rx_stat_valid   <= rx_stat_valid;

assign rx0_stat_wren = rx_stat_valid & ~r_rx_stat_valid;

reg   r_rx_timestamp_en;
always @(posedge axis_aclk)
   if (~axis_resetn)
      r_rx_timestamp_en <= 0;
   else if ((s_axis_tvalid & s_axis_tready & s_axis_tlast) || rx0_stat_wren)
      r_rx_timestamp_en <= 0;
   else if (s_axis_tvalid & s_axis_tready)
      r_rx_timestamp_en <= 1;

assign w_rx_timestamp_en = (s_axis_tvalid & s_axis_tready) & ~r_rx_timestamp_en;

reg   [TS_WIDTH-1:0]    r_timestamp_value;
always @(posedge axis_aclk)
   if (~axis_resetn)
      r_timestamp_value <= 0;
   else if (w_rx_timestamp_en)
      r_timestamp_value <= timestamp_156;

always @(posedge axis_aclk)
   if (~axis_resetn) begin
      rx_pkt_count   <= 0;
   end
   else if (clear) begin
      rx_pkt_count   <= 0;
   end
   else if (rx0_stat_wren) begin
      rx_pkt_count   <= rx_pkt_count + 1;
   end


fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_S_AXIS_DATA_WIDTH/8)+C_S_AXIS_DATA_WIDTH                  ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                                   )
)
rx0_fifo
(
   //Outputs
   .dout             (  {rx0_fifo_out_tlast, rx0_fifo_out_tuser, rx0_fifo_out_tkeep, rx0_fifo_out_tdata}    ),
   .full             (                                                                                      ),
   .nearly_full      (  rx0_fifo_nearly_full                                                                ),
   .prog_full        (                                                                                      ),
   .empty            (  rx0_fifo_empty                                                                      ),
   //Inputs
   .din              (  {s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}                            ),
   .wr_en            (  s_axis_tvalid & ~rx0_fifo_nearly_full                                               ),
   .rd_en            (  rx0_fifo_rden                                                                       ),
   .reset            (  ~axis_resetn                                                                        ),
   .clk              (  axis_aclk                                                                           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  META_TS_WIDTH                             ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                         )
)
rx0_stat
(
   //Outputs
   .dout             (  rx0_stat_out                              ),
   .full             (                                            ),
   .nearly_full      (  rx0_stat_nearly_full                      ),
   .prog_full        (                                            ),
   .empty            (  rx0_stat_empty                            ),
   //Inputs
   .din              (  {r_timestamp_value, rx_stat_vector}       ),
   .wr_en            (  rx0_stat_wren & ~rx0_stat_nearly_full     ),
   .rd_en            (  rx0_stat_rden                             ),
   .reset            (  ~axis_resetn                              ),
   .clk              (  axis_aclk                                 )
);

//States : idle, write data and meta-data, drop enable, wait flush.
reg   [3:0]    current_rx_st, next_rx_st;
always @(posedge axis_aclk)
   if (~axis_resetn)
      current_rx_st  <= `RX_IDLE;
   else
      current_rx_st  <= next_rx_st;

always @(*) begin
   rx1_fifo_in_tdata    = 0;
   rx1_fifo_in_tkeep    = 0;
   rx1_fifo_in_tuser    = 0;
   rx1_fifo_in_tlast    = 0;
   rx1_fifo_wren        = 0;
   rx0_fifo_rden        = 0;
   rx1_stat_in          = 0;
   rx1_stat_wren        = 0;
   rx0_stat_rden        = 0;
   next_rx_st           = 0;
   case (current_rx_st)
      `RX_IDLE : begin
         rx1_fifo_in_tdata    = 0;
         rx1_fifo_in_tkeep    = 0;
         rx1_fifo_in_tuser    = 0;
         rx1_fifo_in_tlast    = 0;
         rx1_fifo_wren        = 0;
         rx0_fifo_rden        = 0;
         rx1_stat_in          = 0;
         rx1_stat_wren        = 0;
         rx0_stat_rden        = (~rx0_stat_empty & ~rx0_fifo_empty &  rx1_fifo_nearly_full) ? 1 : 0;
         next_rx_st           = (~rx0_stat_empty & ~rx0_fifo_empty &  rx1_fifo_nearly_full) ? `RX_DROP :
                                (~rx0_stat_empty & ~rx0_fifo_empty & ~rx1_fifo_nearly_full) ? `RX_WRITE : `RX_IDLE;
      end
      `RX_WRITE : begin
         rx1_fifo_in_tdata    = rx0_fifo_out_tdata;
         rx1_fifo_in_tkeep    = rx0_fifo_out_tkeep;
         rx1_fifo_in_tuser    = rx0_fifo_out_tuser;
         rx1_fifo_in_tlast    = (rx1_fifo_nearly_full || (rx0_fifo_out_tlast & ~rx0_fifo_empty)) ? 1 : 0;
         rx1_fifo_wren        = ~rx0_fifo_empty;
         rx0_fifo_rden        = ~rx0_fifo_empty;
         rx1_stat_in          = (rx1_fifo_nearly_full) ? {1'b1, rx0_stat_out} : (rx0_fifo_out_tlast & ~rx0_fifo_empty) ? {1'b0, rx0_stat_out} : 0;
         rx1_stat_wren        = (rx1_fifo_nearly_full) ? 1                    : (rx0_fifo_out_tlast & ~rx0_fifo_empty) ? 1 : 0;
         rx0_stat_rden        = (rx1_fifo_nearly_full) ? 1                    : (rx0_fifo_out_tlast & ~rx0_fifo_empty) ? 1 : 0;
         if (rx1_fifo_nearly_full)
            next_rx_st  = (rx0_fifo_out_tlast                  ) ? `RX_IDLE : `RX_DROP;
         else
            next_rx_st  = (rx0_fifo_out_tlast & ~rx0_fifo_empty) ? `RX_IDLE : `RX_WRITE;
      end
      `RX_DROP : begin
         rx0_fifo_rden  = (                     ~rx0_fifo_empty) ? 1 : 0;
         next_rx_st     = (rx0_fifo_out_tlast & ~rx0_fifo_empty) ? `RX_IDLE : `RX_DROP;
      end
   endcase
end

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_S_AXIS_DATA_WIDTH/8)+C_S_AXIS_DATA_WIDTH                  ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                                   )
)
rx1_fifo
(
   //Outputs
   .dout             (  {rx1_fifo_out_tlast, rx1_fifo_out_tuser, rx1_fifo_out_tkeep, rx1_fifo_out_tdata}    ),
   .full             (                                                                                      ),
   .nearly_full      (  rx1_fifo_nearly_full                                                                ),
   .prog_full        (                                                                                      ),
   .empty            (  rx1_fifo_empty                                                                      ),
   //Inputs
   .din              (  {rx1_fifo_in_tlast, rx1_fifo_in_tuser, rx1_fifo_in_tkeep, rx1_fifo_in_tdata}        ),
   .wr_en            (  rx1_fifo_wren                                                                       ),
   .rd_en            (  rx1_fifo_rden                                                                       ),
   .reset            (  ~axis_resetn                                                                        ),
   .clk              (  axis_aclk                                                                           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  1+META_TS_WIDTH            ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT          )
)
rx1_stat
(
   //Outputs
   .dout             (  rx1_stat_out               ),
   .full             (                             ),
   .nearly_full      (  rx1_stat_nearly_full       ),
   .prog_full        (                             ),
   .empty            (  rx1_stat_empty             ),
   //Inputs
   .din              (  rx1_stat_in                ),
   .wr_en            (  rx1_stat_wren              ),
   .rd_en            (  rx1_stat_rden              ),
   .reset            (  ~axis_resetn               ),
   .clk              (  axis_aclk                  )
);

//Start state machine for sending to next modules.
//States : idle, write data and tuser, write data, drop.
reg   [3:0]    current_st, next_st;
reg   [C_S_AXI_DATA_WIDTH-1:0]   ts_cnt, ts_cnt_next;
always @(posedge axis_aclk)
   if (~axis_resetn) begin
      current_st  <= `IDLE;
      ts_cnt      <= 1;
   end
   else begin
      current_st  <= next_st;
      ts_cnt      <= ts_cnt_next;
   end

wire  [15:0]   pkt_length = {1'b0,rx1_stat_out[5+:15]} - 4;

//
wire  [C_M_AXIS_TUSER_WIDTH-1:0]    w_m_axis_tuser = {96'b0, 8'h0, SRC_PORT_VAL, pkt_length};

wire  pkt_error = (pkt_length == 0) || rx1_stat_out[META_TS_WIDTH];

reg   [TS_WIDTH-1:0] r_ts_value;
always @(posedge axis_aclk)
   if (~axis_resetn)
      r_ts_value  <= 0;
   else if (next_st == `HEAD && ~rx1_stat_empty && ~rx1_fifo_empty && m_axis_tready)
      r_ts_value  <= rx1_stat_out[30+:64];


always @(*) begin
   m_axis_tdata   = 0;
   m_axis_tkeep   = 0;
   m_axis_tuser   = 0;
   m_axis_tlast   = 0;
   m_axis_tvalid  = 0;
   ts_cnt_next    = 1;
   rx1_fifo_rden  = 0;
   rx1_stat_rden  = 0;
   next_st        = 0;
   case (current_st)
      `IDLE : begin
         m_axis_tdata   = 0;
         m_axis_tkeep   = 0;
         m_axis_tuser   = 0;
         m_axis_tlast   = 0;
         m_axis_tvalid  = 0;
         ts_cnt_next    = 1;
         rx1_fifo_rden  = 0;
         rx1_stat_rden  = (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready & pkt_error) ? 1 : 0;
         next_st        = (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready & pkt_error) ? `DROP :
                          (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready            ) ? `HEAD : `IDLE;
      end
      `HEAD : begin
         if (rx_ts_pos != 0 && ts_cnt == rx_ts_pos) begin
            m_axis_tdata   = r_ts_value;
         end
         else begin
            m_axis_tdata   = rx1_fifo_out_tdata;
         end
         m_axis_tkeep   = rx1_fifo_out_tkeep;
         m_axis_tuser   = w_m_axis_tuser;
         m_axis_tlast   = rx1_fifo_out_tlast;
         m_axis_tvalid  = ~rx1_fifo_empty;
         ts_cnt_next    = (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready) ? ts_cnt + 1 : ts_cnt;
         rx1_fifo_rden  = (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready);
         rx1_stat_rden  = (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready);
         next_st        = (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready & rx1_fifo_out_tlast) ? `IDLE :
                          (~rx1_stat_empty & ~rx1_fifo_empty & m_axis_tready                     ) ? `SEND : `HEAD;
      end
      `SEND : begin
         if (rx_ts_pos != 0 && ts_cnt == rx_ts_pos) begin
            m_axis_tdata   = r_ts_value;
         end
         else begin
            m_axis_tdata   = rx1_fifo_out_tdata;
         end
         m_axis_tkeep   = rx1_fifo_out_tkeep;
         m_axis_tuser   = 0;
         m_axis_tlast   = rx1_fifo_out_tlast;
         m_axis_tvalid  = ~rx1_fifo_empty;
         ts_cnt_next    = (~rx1_fifo_empty & m_axis_tready) ? ts_cnt + 1 : ts_cnt;
         rx1_fifo_rden  = (~rx1_fifo_empty & m_axis_tready);
         next_st        = (~rx1_fifo_empty & m_axis_tready & rx1_fifo_out_tlast) ? `IDLE : `SEND;
      end
      `DROP : begin
         rx1_fifo_rden  = ~rx1_fifo_empty;
         next_st        = (~rx1_fifo_empty & rx1_fifo_out_tlast) ? `IDLE : `DROP;
      end
   endcase
end

endmodule
