//
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
// Junior University
// Copyright (c) 2016 University of Cambridge
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

/*******************************************************************************
 *  File:
 *        process_pkt.v
 *
 *  Author:
 *        Gianni Antichi
 *
 *  Description:
 *        TCAM lookup module
 */

`timescale 1ns/1ps

module process_pkt
#(
   parameter TUPLE_WIDTH = 104,
   parameter NUM_QUEUES = 8,
   parameter MON_LUT_DEPTH_BITS = 5
)
(
   // --- trigger signals
   input [TUPLE_WIDTH-1:0]   tuple,
   input [NUM_QUEUES-1:0]    src_port,
   input		        lookup_req,

   input [3:0]             debug_mode,

      // --- output signal
      output reg [NUM_QUEUES-1:0]dst_ports,
      output reg	        lookup_done,

      // --- interface to registers
      input [MON_LUT_DEPTH_BITS-1:0]rule_rd_addr,          // address in table to read
      input                     rule_rd_req,           // request a read
      output [TUPLE_WIDTH-1:0]  rule_rd,               // rule to match in the TCAM
      output [TUPLE_WIDTH-1:0]  rule_rd_mask,          // rule subnet
      output reg                rule_rd_ack,           // pulses high

      input [MON_LUT_DEPTH_BITS-1:0]rule_wr_addr,
      input                     rule_wr_req,
      input [TUPLE_WIDTH-1:0]   rule_wr,
      input [TUPLE_WIDTH-1:0]   rule_wr_mask,
      output reg                rule_wr_ack,
   
      // --- misc
      input                     clk,
      input                     reset
     );

   //--------------------- Internal Parameter-------------------------
      localparam RESET = 0;
      localparam READY = 1;
      localparam MON_DEPTH = 2**MON_LUT_DEPTH_BITS;
      localparam CMP_WIDTH = TUPLE_WIDTH;
      localparam RESET_CMP_DATA = {CMP_WIDTH{1'b0}};
      localparam RESET_CMP_DMASK = {CMP_WIDTH{1'b0}};

      localparam NOT_MATCH_PORT = {NUM_QUEUES{1'b0}};
   //---------------------- Wires and regs----------------------------

      reg [MON_LUT_DEPTH_BITS-1:0]  lut_rd_addr;
      reg [2*CMP_WIDTH-1:0]     lut_rd_data;

      reg [2*CMP_WIDTH-1:0]     lut[MON_DEPTH-1:0];

      reg                       lookup_latched_0, lookup_latched_1;
      reg                       rd_req_latched;

      reg [CMP_WIDTH-1:0]       din;
      reg [CMP_WIDTH-1:0]	data_mask;

      reg			we;
      reg [MON_LUT_DEPTH_BITS-1:0]  wr_addr;


      wire [CMP_WIDTH-1:0]      cam_din;
      wire [CMP_WIDTH-1:0]      cam_data_mask;
      wire [MON_LUT_DEPTH_BITS-1:0] cam_wr_addr;

      reg [NUM_QUEUES-1:0]      match_oport;
      reg [NUM_QUEUES-1:0]      dst_port_latched_0, dst_port_latched_1;

      reg [4:0]                 reset_count;
      reg                       state;
 
//------------------------- Modules-------------------------------
tcam_wrapper
#(
   .C_TCAM_ADDR_WIDTH      (  MON_LUT_DEPTH_BITS      ),
   .C_TCAM_DATA_WIDTH      (  CMP_WIDTH               )
)
mon_tcam
(
   .CLK                    (  clk                     ),
   .WE                     (  cam_we                  ),
   .WR_ADDR                (  cam_wr_addr             ),
   .DIN                    (  cam_din                 ),
   .DATA_MASK              (  cam_data_mask           ),
   .BUSY                   (  cam_busy                ),

   .CMP_DIN                (  tuple                   ),
   .CMP_DATA_MASK          (  {CMP_WIDTH{1'b0}}       ),
   .MATCH                  (  cam_match               ),
   .MATCH_ADDR             (                          )
);

reg   r_cam_match;
always @(posedge clk)
   if(reset)
      r_cam_match    <= 0;
   else
      r_cam_match    <= cam_match;

   //------------------------- Logic --------------------------------

   assign rule_rd       = lut_rd_data[CMP_WIDTH-1:0];
   assign rule_rd_mask  = lut_rd_data[2*CMP_WIDTH-1:CMP_WIDTH];

   assign cam_din 	= din;
   assign cam_data_mask = data_mask;

   assign cam_we	= we;
   assign cam_wr_addr   = wr_addr;


   /* if we get a miss then set the dst port to the default ports
    * without the source */


always @(*) begin
     match_oport = 0;
     case(src_port)
             8'h1: 	match_oport     = 8'h2;
             8'h4: 	match_oport     = 8'h8;
             8'h10:	match_oport     = 8'h20;
             8'h40:	match_oport     = 8'h80;
             default:match_oport     = 8'h0;
     endcase
end

always @(posedge clk) begin
   if(reset) begin
      lookup_latched_0    <= 0;
      lookup_latched_1    <= 0;
      dst_port_latched_0  <= 0;
      dst_port_latched_1  <= 0;
      lookup_done       <= 0;
      rd_req_latched    <= 0;
      we                <= 0;
      wr_addr           <= 0;
      din               <= 0;
      data_mask         <= 0;
      dst_ports	      <= 0;
      rule_wr_ack       <= 0;
      state             <= RESET;
      reset_count       <= 0;
      rule_rd_ack       <= 0;
      lut_rd_data       <= 0;
   end // if (reset)
   else begin
      if (state == RESET && !cam_busy) begin
         if(reset_count == 16) begin
            state  <= READY;
            we     <= 1'b0;
         end
         else begin
            we           <= 1'b1;
		      wr_addr      <= reset_count[3:0];
            din          <= RESET_CMP_DATA;
            data_mask    <= RESET_CMP_DMASK;
            reset_count  <= reset_count + 1'b1;
         end
      end   
	   else if (state == READY) begin
	      /* first pipeline stage -- do CAM lookup */
		   lookup_latched_0        <= lookup_req;
		   lookup_latched_1        <= lookup_latched_0;
	   	dst_port_latched_0		<= match_oport;
	   	dst_port_latched_1		<= dst_port_latched_0;

         /* second pipeline stage -- CAM result */
         /* add debug mode default for test */
         dst_ports             	<= (lookup_latched_1 & (r_cam_match | (|debug_mode))) ? dst_port_latched_1 : NOT_MATCH_PORT;
         //dst_ports			<= (lookup_req) ? port_out : dst_ports;
         //dst_ports                   <= (lookup_req & cam_match) ? match_oport : not_match_oport;
         //lookup_done			<= lookup_req;
	   	lookup_done                 <= lookup_latched_1;

         /* handle read LUT */
         lut_rd_addr                 <= rule_rd_addr;
         rd_req_latched              <= rule_rd_req;
            
         /* output read LUT */
         lut_rd_data                 <= lut[lut_rd_addr];
         rule_rd_ack                 <= rd_req_latched;
            
         /* Handle writes */
         if(rule_wr_req && !cam_busy) begin
			   wr_addr    <= rule_wr_addr[3:0];
            din        <= rule_wr;
            data_mask  <= rule_wr_mask;
            rule_wr_ack    <= 1;
		      we <= 1;
         end  
         else begin
            we <= 0;
            rule_wr_ack <= 0;
         end // else: !if(rule_wr_req && !cam_busy)
      end // else: !if(state == RESET)   
	end // else: !if(reset)
      // separate this out to allow implementation as BRAM
   if(we)
	   lut[{1'b0, wr_addr[3:0]}] <= {cam_data_mask, cam_din};
end // always @ (posedge clk)


endmodule // process_pkt

