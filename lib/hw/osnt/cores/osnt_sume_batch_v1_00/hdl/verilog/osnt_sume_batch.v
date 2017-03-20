//
// Copyright (c) 2017 University of Cambridge
// Copyright (c) 2017 Jong Hun Han
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

module osnt_sume_batch
#(
   // Master AXI Stream Data Width
   parameter   C_M_AXIS_DATA_WIDTH  = 128,
   parameter   C_S_AXIS_DATA_WIDTH  = 128,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128
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
   input                                           s_axis_tlast
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

localparam BATCH_SIZE = 90;
localparam IDLE_NO = 1000000;

localparam MAX_PKT_SIZE = 8192; // In bytes
localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_S_AXIS_DATA_WIDTH/8));

`define  IDLE     0
`define  HEAD     1
`define  SEND     2

`define  RX_IDLE  0
`define  RX_WRITE 1
`define  RX_DROP  2
`define  RX_FORCE 3


wire  [C_S_AXIS_DATA_WIDTH-1:0]        pre_fifo_out_tdata;
wire  [(C_S_AXIS_DATA_WIDTH/8)-1:0]    pre_fifo_out_tkeep;
wire  [C_S_AXIS_TUSER_WIDTH-1:0]       pre_fifo_out_tuser;
wire                                   pre_fifo_out_tlast;
wire  pre_fifo_nearly_full;
wire  pre_fifo_empty;
reg   pre_fif0_wren;
reg   pre_fifo_rden;

reg   [C_S_AXIS_DATA_WIDTH-1:0]        batch_fifo_in_tdata;
reg   [(C_S_AXIS_DATA_WIDTH/8)-1:0]    batch_fifo_in_tkeep;
reg   [C_S_AXIS_TUSER_WIDTH-1:0]       batch_fifo_in_tuser;
reg                                    batch_fifo_in_tlast;

wire  [C_S_AXIS_DATA_WIDTH-1:0]        batch_fifo_out_tdata;
wire  [(C_S_AXIS_DATA_WIDTH/8)-1:0]    batch_fifo_out_tkeep;
wire  [C_S_AXIS_TUSER_WIDTH-1:0]       batch_fifo_out_tuser;
wire                                   batch_fifo_out_tlast;

wire  batch_fifo_nearly_full;
wire  batch_fifo_empty;
reg   batch_fifo_wren;
reg   batch_fifo_rden;

reg   [15:0]    batch_en_in;
wire  [15:0]    batch_en_out;
wire  batch_en_nearly_full;
wire  batch_en_empty;
reg   batch_en_rden;
reg   batch_en_wren;

assign s_axis_tready = ~pre_fifo_nearly_full;

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_S_AXIS_DATA_WIDTH/8)+C_S_AXIS_DATA_WIDTH                  ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                                   )
)
pre_fifo
(
   //Outputs
   .dout             (  {pre_fifo_out_tlast, pre_fifo_out_tuser, pre_fifo_out_tkeep, pre_fifo_out_tdata}    ),
   .full             (                                                                                      ),
   .nearly_full      (  pre_fifo_nearly_full                                                                ),
   .prog_full        (                                                                                      ),
   .empty            (  pre_fifo_empty                                                                      ),
   //Inputs
   .din              (  {s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}                            ),
   .wr_en            (  s_axis_tvalid & ~pre_fifo_nearly_full                                               ),
   .rd_en            (  pre_fifo_rden                                                                       ),
   .reset            (  ~axis_resetn                                                                        ),
   .clk              (  axis_aclk                                                                           )
);

//States : idle, write data and meta-data, drop enable, wait flush.
reg   [3:0]    current_pre_st, next_pre_st;
reg   [15:0]   batch_cnt, next_batch_cnt;
always @(posedge axis_aclk)
   if (~axis_resetn) begin
      current_pre_st <= `RX_IDLE;
      batch_cnt      <= 0;
   end
   else begin
      current_pre_st <= next_pre_st;
      batch_cnt      <= next_batch_cnt;
   end

reg   [31:0]   idle_cnt;
always @(posedge axis_aclk)
   if (~axis_resetn) begin
      idle_cnt <= 0;
   end
   else if (current_pre_st == `RX_IDLE) begin
      idle_cnt <= (idle_cnt == IDLE_NO) ? 0 : idle_cnt + 1;
   end
   else begin
      idle_cnt <= 0;
   end

always @(*) begin
   batch_fifo_in_tdata  = 0;
   batch_fifo_in_tkeep  = 0;
   batch_fifo_in_tuser  = 0;
   batch_fifo_in_tlast  = 0;
   batch_fifo_wren      = 0;
   pre_fifo_rden        = 0;
   batch_en_in          = 0;
   batch_en_wren        = 0;
   next_batch_cnt       = batch_cnt;
   next_pre_st          = `RX_IDLE;
   case (current_pre_st)
      `RX_IDLE : begin
         batch_fifo_in_tdata  = 0;
         batch_fifo_in_tkeep  = 0;
         batch_fifo_in_tuser  = 0;
         batch_fifo_in_tlast  = 0;
         batch_fifo_wren      = 0;
         pre_fifo_rden        = 0;
         batch_en_in          = 0;
         batch_en_wren        = 0;
         next_batch_cnt       = batch_cnt;
         next_pre_st          = (~pre_fifo_empty &  batch_fifo_nearly_full) ? `RX_DROP :
                                (~pre_fifo_empty & ~batch_fifo_nearly_full) ? `RX_WRITE :
                                (idle_cnt == 2000 & batch_cnt != 0)         ? `RX_FORCE : `RX_IDLE;
      end
      `RX_WRITE : begin
         batch_fifo_in_tdata  = pre_fifo_out_tdata;
         batch_fifo_in_tkeep  = pre_fifo_out_tkeep;
         batch_fifo_in_tuser  = pre_fifo_out_tuser;
         batch_fifo_in_tlast  = (batch_cnt == BATCH_SIZE) ? 1 : 0;
         batch_fifo_wren      = 1;
         pre_fifo_rden        = 1;
         batch_en_in          = (batch_cnt + 1);
         batch_en_wren        = (batch_cnt == BATCH_SIZE) ? 1 : 0;
         next_batch_cnt       = (batch_cnt == BATCH_SIZE) ? 0 : batch_cnt + 1;
         next_pre_st          = (~pre_fifo_empty & pre_fifo_out_tlast) ? `RX_IDLE : `RX_DROP;
      end
      `RX_DROP : begin
         pre_fifo_rden        = (~pre_fifo_empty) ? 1 : 0;
         next_pre_st          = (~pre_fifo_empty & pre_fifo_out_tlast) ? `RX_IDLE : `RX_DROP;
      end
      `RX_FORCE : begin
         batch_fifo_in_tdata  = 0;
         batch_fifo_in_tkeep  = 16'hffff;
         batch_fifo_in_tuser  = 0;
         batch_fifo_in_tlast  = 1;
         batch_fifo_wren      = 1;
         pre_fifo_rden        = 1;
         batch_en_in          = (batch_cnt + 1);
         batch_en_wren        = 1;
         next_batch_cnt       = 0;
         next_pre_st          = `RX_IDLE;
      end
   endcase
end

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_S_AXIS_DATA_WIDTH/8)+C_S_AXIS_DATA_WIDTH                        ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                                         )
)
batch_fifo
(
   //Outputs
   .dout             (  {batch_fifo_out_tlast, batch_fifo_out_tuser, batch_fifo_out_tkeep, batch_fifo_out_tdata}  ),
   .full             (                                                                                            ),
   .nearly_full      (  batch_fifo_nearly_full                                                                    ),
   .prog_full        (                                                                                            ),
   .empty            (  batch_fifo_empty                                                                          ),
   //Inputs
   .din              (  {batch_fifo_in_tlast, batch_fifo_in_tuser, batch_fifo_in_tkeep, batch_fifo_in_tdata}      ),
   .wr_en            (  batch_fifo_wren                                                                           ),
   .rd_en            (  batch_fifo_rden                                                                           ),
   .reset            (  ~axis_resetn                                                                              ),
   .clk              (  axis_aclk                                                                                 )
);

fallthrough_small_fifo
#(
   .WIDTH            (  16                         ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT          )
)
batch_en
(
   //Outputs
   .dout             (  batch_en_out               ),
   .full             (                             ),
   .nearly_full      (  batch_en_nearly_full       ),
   .prog_full        (                             ),
   .empty            (  batch_en_empty             ),
   //Inputs
   .din              (  batch_en_in                ),
   .wr_en            (  batch_en_wren              ),
   .rd_en            (  batch_en_rden              ),
   .reset            (  ~axis_resetn               ),
   .clk              (  axis_aclk                  )
);

reg   [3:0]    current_st, next_st;
always @(posedge axis_aclk)
   if (~axis_resetn) begin
      current_st  <= `IDLE;
   end
   else begin
      current_st  <= next_st;
   end

always @(*) begin
   m_axis_tdata      = 0;
   m_axis_tkeep      = 0;
   m_axis_tuser      = 0;
   m_axis_tlast      = 0;
   m_axis_tvalid     = 0;
   batch_fifo_rden   = 0;
   batch_en_rden     = 0;
   next_st           = 0;
   case (current_st)
      `IDLE : begin
         m_axis_tdata      = 0;
         m_axis_tkeep      = 0;
         m_axis_tuser      = 0;
         m_axis_tlast      = 0;
         m_axis_tvalid     = 0;
         batch_fifo_rden   = 0;
         batch_en_rden     = 0;
         next_st           = (~batch_en_empty & ~batch_fifo_empty) ? `HEAD : `IDLE;
      end
      `HEAD : begin
         m_axis_tdata      = batch_fifo_out_tdata;
         m_axis_tkeep      = batch_fifo_out_tkeep;
         m_axis_tuser      = {batch_fifo_out_tuser[127:16], batch_en_out[11:0], 4'h0};
         m_axis_tlast      = batch_fifo_out_tlast;
         m_axis_tvalid     = ~batch_fifo_empty;
         batch_fifo_rden   = (~batch_en_empty & ~batch_fifo_empty & m_axis_tready);
         batch_en_rden     = (~batch_en_empty & ~batch_fifo_empty & m_axis_tready);
         next_st           = (~batch_en_empty & ~batch_fifo_empty & m_axis_tready & batch_fifo_out_tlast) ? `IDLE :
                             (~batch_en_empty & ~batch_fifo_empty & m_axis_tready                       ) ? `SEND : `HEAD;
      end
      `SEND : begin
         m_axis_tdata      = batch_fifo_out_tdata;
         m_axis_tkeep      = batch_fifo_out_tkeep;
         m_axis_tuser      = 0;
         m_axis_tlast      = batch_fifo_out_tlast;
         m_axis_tvalid     = ~batch_fifo_empty;
         batch_fifo_rden   = (~batch_fifo_empty & m_axis_tready);
         next_st           = (~batch_fifo_empty & m_axis_tready & batch_fifo_out_tlast) ? `IDLE : `SEND;
      end
   endcase
end

endmodule
