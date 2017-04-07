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

module pcap_mem_replay
#(
   parameter   C_M_AXIS_DATA_WIDTH  = 256,
   parameter   C_S_AXIS_DATA_WIDTH  = 256,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128,
   parameter   NUM_QUEUES           = 4
)
(
   // Master Stream Ports (interface to data path)
   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   input                                                 sw_rst,

   //Master from external Memory Stream Ports
   output         [C_M_AXIS_DATA_WIDTH-1:0]              m0_axis_tdata,
   output         [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m0_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m0_axis_tuser,
   output                                                m0_axis_tvalid,
   input                                                 m0_axis_tready,
   output                                                m0_axis_tlast,

   output         [C_M_AXIS_DATA_WIDTH-1:0]              m1_axis_tdata,
   output         [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m1_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m1_axis_tuser,
   output                                                m1_axis_tvalid,
   input                                                 m1_axis_tready,
   output                                                m1_axis_tlast,

   output         [C_M_AXIS_DATA_WIDTH-1:0]              m2_axis_tdata,
   output         [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m2_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m2_axis_tuser,
   output                                                m2_axis_tvalid,
   input                                                 m2_axis_tready,
   output                                                m2_axis_tlast,

   output         [C_M_AXIS_DATA_WIDTH-1:0]              m3_axis_tdata,
   output         [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m3_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m3_axis_tuser,
   output                                                m3_axis_tvalid,
   input                                                 m3_axis_tready,
   output                                                m3_axis_tlast,

   //Slave from external Memory Stream Ports
   input          [C_S_AXIS_DATA_WIDTH-1:0]              s0_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s0_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s0_axis_tuser,
   input                                                 s0_axis_tvalid,
   output                                                s0_axis_tready,
   input                                                 s0_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s1_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s1_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s1_axis_tuser,
   input                                                 s1_axis_tvalid,
   output                                                s1_axis_tready,
   input                                                 s1_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s2_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s2_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s2_axis_tuser,
   input                                                 s2_axis_tvalid,
   output                                                s2_axis_tready,
   input                                                 s2_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s3_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s3_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s3_axis_tuser,
   input                                                 s3_axis_tvalid,
   output                                                s3_axis_tready,
   input                                                 s3_axis_tlast
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

// ------------ Internal Params --------
localparam  MAX_PKT_SIZE      = 2000; // In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

// ------------- Regs/ wires -----------
reg   [NUM_QUEUES-1:0]  fifo_rden;
wire  [NUM_QUEUES-1:0]  fifo_empty;
wire  [NUM_QUEUES-1:0]  fifo_full;
wire  [C_M_AXIS_DATA_WIDTH-1:0]        fifo_in_tdata[0:NUM_QUEUES-1];
wire  [(C_M_AXIS_DATA_WIDTH/8)-1:0]    fifo_in_tkeep[0:NUM_QUEUES-1];
wire  [C_M_AXIS_TUSER_WIDTH-1:0]       fifo_in_tuser[0:NUM_QUEUES-1];
wire  [NUM_QUEUES-1:0]                 fifo_in_tlast;
wire  [NUM_QUEUES-1:0]                 fifo_in_tvalid;

wire  [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata[0:NUM_QUEUES-1];
wire  [(C_M_AXIS_DATA_WIDTH/8)-1:0]    fifo_out_tkeep[0:NUM_QUEUES-1];
wire  [C_M_AXIS_TUSER_WIDTH-1:0]       fifo_out_tuser[0:NUM_QUEUES-1];
wire  [NUM_QUEUES-1:0]                 fifo_out_tlast;
wire  [NUM_QUEUES-1:0]                 fifo_out_tready;

assign fifo_in_tdata[0]  = s0_axis_tdata;
assign fifo_in_tkeep[0]  = s0_axis_tkeep;
assign fifo_in_tuser[0]  = s0_axis_tuser;
assign fifo_in_tvalid[0] = s0_axis_tvalid;
assign fifo_in_tlast[0]  = s0_axis_tlast;
assign s0_axis_tready    = ~fifo_full[0];

assign fifo_in_tdata[1]  = s1_axis_tdata;
assign fifo_in_tkeep[1]  = s1_axis_tkeep;
assign fifo_in_tuser[1]  = s1_axis_tuser;
assign fifo_in_tvalid[1] = s1_axis_tvalid;
assign fifo_in_tlast[1]  = s1_axis_tlast;
assign s1_axis_tready    = ~fifo_full[1];

assign fifo_in_tdata[2]  = s2_axis_tdata;
assign fifo_in_tkeep[2]  = s2_axis_tkeep;
assign fifo_in_tuser[2]  = s2_axis_tuser;
assign fifo_in_tvalid[2] = s2_axis_tvalid;
assign fifo_in_tlast[2]  = s2_axis_tlast;
assign s2_axis_tready    = ~fifo_full[2];

assign fifo_in_tdata[3]  = s3_axis_tdata;
assign fifo_in_tkeep[3]  = s3_axis_tkeep;
assign fifo_in_tuser[3]  = s3_axis_tuser;
assign fifo_in_tvalid[3] = s3_axis_tvalid;
assign fifo_in_tlast[3]  = s3_axis_tlast;
assign s3_axis_tready    = ~fifo_full[3];


assign m0_axis_tdata       = fifo_out_tdata[0]; 
assign m0_axis_tkeep       = fifo_out_tkeep[0]; 
assign m0_axis_tuser       = fifo_out_tuser[0]; 
assign m0_axis_tvalid      = ~fifo_empty[0]; 
assign m0_axis_tlast       = fifo_out_tlast[0]; 
assign fifo_out_tready[0]  = m0_axis_tready;

assign m1_axis_tdata       = fifo_out_tdata[1]; 
assign m1_axis_tkeep       = fifo_out_tkeep[1]; 
assign m1_axis_tuser       = fifo_out_tuser[1]; 
assign m1_axis_tvalid      = ~fifo_empty[1]; 
assign m1_axis_tlast       = fifo_out_tlast[1]; 
assign fifo_out_tready[1]  = m1_axis_tready; 

assign m2_axis_tdata       = fifo_out_tdata[2];
assign m2_axis_tkeep       = fifo_out_tkeep[2];
assign m2_axis_tuser       = fifo_out_tuser[2];
assign m2_axis_tvalid      = ~fifo_empty[2];
assign m2_axis_tlast       = fifo_out_tlast[2]; 
assign fifo_out_tready[2]  = m2_axis_tready; 

assign m3_axis_tdata       = fifo_out_tdata[3];
assign m3_axis_tkeep       = fifo_out_tkeep[3];
assign m3_axis_tuser       = fifo_out_tuser[3];
assign m3_axis_tvalid      = ~fifo_empty[3];
assign m3_axis_tlast       = fifo_out_tlast[3]; 
assign fifo_out_tready[3]  = m3_axis_tready;

generate
   genvar i;
   for(i=0; i<NUM_QUEUES; i=i+1) begin: mem_ld_fifo
      fallthrough_small_fifo
      #(
         .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_M_AXIS_DATA_WIDTH/8)+C_M_AXIS_DATA_WIDTH            ),
         .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                             )
      )
      mem_ld_fifo
      (
         //Outputs
         .dout             (  {fifo_out_tlast[i], fifo_out_tuser[i], fifo_out_tkeep[i], fifo_out_tdata[i]}  ),
         .full             (                                                                                ),
         .nearly_full      (  fifo_full[i]                                                                  ),
	      .prog_full        (                                                                                ),
         .empty            (  fifo_empty[i]                                                                 ),
         //Inputs
         .din              (  {fifo_in_tlast[i], fifo_in_tuser[i], fifo_in_tkeep[i], fifo_in_tdata[i]}      ),
         .wr_en            (  fifo_in_tvalid[i] & ~fifo_full[i]                                             ),
         .rd_en            (  fifo_out_tready[i] & ~fifo_empty[i]                                           ),
         .reset            (  ~axis_aresetn                                                                 ),
         .clk              (  axis_aclk                                                                     )
      );
   end
endgenerate

endmodule
