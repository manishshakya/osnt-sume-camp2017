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

module pcap_mem_store
#(
   parameter   C_M_AXIS_DATA_WIDTH  = 256,
   parameter   C_S_AXIS_DATA_WIDTH  = 256,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128,
   parameter   SRC_PORT_POS         = 16,
   parameter   NUM_QUEUES           = 4
)
(
   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   //Master Stream Ports to external memory for pcap storing
   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m0_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m0_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m0_axis_tuser,
   output   reg                                          m0_axis_tvalid,
   input                                                 m0_axis_tready,
   output   reg                                          m0_axis_tlast,

   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m1_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m1_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m1_axis_tuser,
   output   reg                                          m1_axis_tvalid,
   input                                                 m1_axis_tready,
   output   reg                                          m1_axis_tlast,

   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m2_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m2_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m2_axis_tuser,
   output   reg                                          m2_axis_tvalid,
   input                                                 m2_axis_tready,
   output   reg                                          m2_axis_tlast,

   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m3_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m3_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m3_axis_tuser,
   output   reg                                          m3_axis_tvalid,
   input                                                 m3_axis_tready,
   output   reg                                          m3_axis_tlast,

   //Slave Stream Ports from host over DMA 
   input          [C_S_AXIS_DATA_WIDTH-1:0]              s_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast
);

integer j;

function integer log2;
   input integer number;
   begin
      log2=0;
      while(2**log2<number) begin
         log2=log2+1;
      end
   end
endfunction//log2

assign s_axis_tready = 1;

reg   [3:0] m0_st_current, m0_st_next;
reg   [3:0] m1_st_current, m1_st_next;
reg   [3:0] m2_st_current, m2_st_next;
reg   [3:0] m3_st_current, m3_st_next;

// ------------ Internal Params --------
localparam  MAX_PKT_SIZE      = 2000; //In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH/8));

reg   fifo_rden;
wire  fifo_empty;
wire  fifo_full;

wire  [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata;
wire  [(C_M_AXIS_DATA_WIDTH/8)-1:0]    fifo_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]       fifo_out_tuser;
wire  [NUM_QUEUES-1:0]                 fifo_out_tlast;

wire  [7:0] tuser_src_port = fifo_out_tuser[16+:8];

`define  ST_MEM_IDLE    0
`define  ST_MEM_WR_0    1
`define  ST_MEM_WR_1    2
`define  ST_MEM_WR_2    3
`define  ST_MEM_WR_3    4

reg   [3:0] st_mem_current, st_mem_next;
always @(posedge axis_aclk)
   if (~axis_aresetn) begin
      st_mem_current <= 0;
   end
   else begin
      st_mem_current <= st_mem_next;
   end

always @(*) begin
   m0_axis_tdata     = 0;
   m0_axis_tkeep     = 0;
   m0_axis_tuser     = 0;
   m0_axis_tvalid    = 0;
   m0_axis_tlast     = 0;
   fifo_rden         = 0;
   st_mem_next       = 0;
   case (st_mem_current)
      `ST_MEM_IDLE : begin
         st_mem_next       = ((tuser_src_port == 8'h02) && ~fifo_empty) ? `ST_MEM_WR_0 : `ST_MEM_IDLE;
      end
      `ST_MEM_WR_0 : begin
         m0_axis_tdata     = fifo_out_tdata;
         m0_axis_tkeep     = fifo_out_tkeep;
         m0_axis_tuser     = fifo_out_tuser;
         m0_axis_tvalid    = ~fifo_empty;
         m0_axis_tlast     = fifo_out_tlast;
         fifo_rden         = (~fifo_empty & m0_axis_tready);
         st_mem_next       = (~fifo_empty & m0_axis_tready & fifo_out_tlast) ? `ST_MEM_IDLE : `ST_MEM_WR_0;
      end
   endcase
end


fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_M_AXIS_DATA_WIDTH/8)+C_M_AXIS_DATA_WIDTH   ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                    )
)
pcap_fifo
(
   //Outputs
   .dout             (  {fifo_out_tlast, fifo_out_tuser, fifo_out_tkeep, fifo_out_tdata}     ),
   .full             (                                                                       ),
   .nearly_full      (  fifo_full                                                            ),
   .prog_full        (                                                                       ),
   .empty            (  fifo_empty                                                           ),
   //Inputs
   .din              (  {s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}             ),
   .wr_en            (  s_axis_tvalid & ~fifo_full                                           ),
   .rd_en            (  fifo_rden                                                            ),
   .reset            (  ~axis_aresetn                                                        ),
   .clk              (  axis_aclk                                                            )
);

endmodule
