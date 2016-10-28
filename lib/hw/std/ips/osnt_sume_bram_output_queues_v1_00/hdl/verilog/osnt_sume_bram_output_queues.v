//
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
// Junior University
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
/*******************************************************************************
 *  File:
 *        osnt_sume_bram_output_queues.v
 *
 *  Author:
 *        James Hongyi Zeng
 *
 *  Description:
 *        BRAM Output queues
 *        Outputs have a parameterizable width
 *
 */

module osnt_sume_bram_output_queues
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter NUM_QUEUES=5
)
(
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Slave Stream Ports (interface to data path)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input s_axis_tvalid,
    output reg s_axis_tready,
    input s_axis_tlast,

    // Master Stream Ports (interface to TX queues)
    output [C_M_AXIS_DATA_WIDTH - 1:0] m0_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m0_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m0_axis_tuser,
    output  m0_axis_tvalid,
    input m0_axis_tready,
    output  m0_axis_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0] m1_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m1_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m1_axis_tuser,
    output  m1_axis_tvalid,
    input m1_axis_tready,
    output  m1_axis_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0] m2_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m2_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m2_axis_tuser,
    output  m2_axis_tvalid,
    input m2_axis_tready,
    output  m2_axis_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0] m3_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m3_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m3_axis_tuser,
    output  m3_axis_tvalid,
    input m3_axis_tready,
    output  m3_axis_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0] m4_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m4_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m4_axis_tuser,
    output  m4_axis_tvalid,
    input m4_axis_tready,
    output  m4_axis_tlast
);

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // ------------ Internal Params --------

   localparam NUM_QUEUES_WIDTH = log2(NUM_QUEUES);

   localparam BUFFER_SIZE         = 9100; // Buffer size 4096B
   localparam BUFFER_SIZE_WIDTH   = log2(BUFFER_SIZE/(C_M_AXIS_DATA_WIDTH/8));

   localparam MAX_PACKET_SIZE = 1600;
   localparam BUFFER_THRESHOLD = (BUFFER_SIZE-MAX_PACKET_SIZE)/(C_M_AXIS_DATA_WIDTH/8);

   localparam NUM_STATES = 3;
   localparam IDLE = 0;
   localparam WR_PKT = 1;
   localparam DROP = 2;

   localparam NUM_METADATA_STATES = 2;
   localparam WAIT_HEADER = 0;
   localparam WAIT_EOP = 1;

   // ------------- Regs/ wires -----------

   reg [NUM_QUEUES-1:0]                nearly_full;
   wire [NUM_QUEUES-1:0]               nearly_full_fifo;
   wire [NUM_QUEUES-1:0]               empty;

   reg [NUM_QUEUES-1:0]                metadata_nearly_full;
   wire [NUM_QUEUES-1:0]               metadata_nearly_full_fifo;
   wire [NUM_QUEUES-1:0]               metadata_empty;

   wire [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser[NUM_QUEUES-1:0];
   wire [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata[NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  fifo_out_tstrb[NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0] 	           fifo_out_tlast;

   wire [NUM_QUEUES-1:0]               rd_en;
   reg [NUM_QUEUES-1:0]                wr_en;

   reg [NUM_QUEUES-1:0]                metadata_rd_en;
   reg [NUM_QUEUES-1:0]                metadata_wr_en;

   reg [NUM_QUEUES-1:0]          cur_queue;
   reg [NUM_QUEUES-1:0]          cur_queue_next;
   wire [NUM_QUEUES-1:0]         oq;

   reg [NUM_STATES-1:0]                state;
   reg [NUM_STATES-1:0]                state_next;

   reg [NUM_METADATA_STATES-1:0]       metadata_state[NUM_QUEUES-1:0];
   reg [NUM_METADATA_STATES-1:0]       metadata_state_next[NUM_QUEUES-1:0];

   reg								   first_word, first_word_next;

   // ------------ Modules -------------

   generate
   genvar i;
   for(i=0; i<NUM_QUEUES; i=i+1) begin: output_queues
      fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
           .MAX_DEPTH_BITS(BUFFER_SIZE_WIDTH),
           .PROG_FULL_THRESHOLD(BUFFER_THRESHOLD))
      output_fifo
        (// Outputs
         .dout                           ({fifo_out_tlast[i], fifo_out_tstrb[i], fifo_out_tdata[i]}),
         .full                           (),
         .nearly_full                    (),
	 	 .prog_full                      (nearly_full_fifo[i]),
         .empty                          (empty[i]),
         // Inputs
         .din                            ({s_axis_tlast, s_axis_tkeep, s_axis_tdata}),
         .wr_en                          (wr_en[i]),
         .rd_en                          (rd_en[i]),
         .reset                          (~axis_resetn),
         .clk                            (axis_aclk));

      fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_TUSER_WIDTH),
           .MAX_DEPTH_BITS(2))
      metadata_fifo
        (// Outputs
         .dout                           (fifo_out_tuser[i]),
         .full                           (),
         .nearly_full                    (metadata_nearly_full_fifo[i]),
	 	 .prog_full                      (),
         .empty                          (metadata_empty[i]),
         // Inputs
         .din                            (s_axis_tuser),
         .wr_en                          (metadata_wr_en[i]),
         .rd_en                          (metadata_rd_en[i]),
         .reset                          (~axis_resetn),
         .clk                            (axis_aclk));

   always @(metadata_state[i], rd_en[i], fifo_out_tlast[i]) begin
        metadata_rd_en[i] = 1'b0;
        metadata_state_next[i] = WAIT_HEADER;
      	case(metadata_state[i])
      		WAIT_HEADER: begin
      			if(rd_en[i]) begin
      				metadata_state_next[i] = WAIT_EOP;
      				metadata_rd_en[i] = 1'b1;
      			end
      		end
      		WAIT_EOP: begin
      			metadata_state_next[i] = WAIT_EOP;
      			if(rd_en[i] & fifo_out_tlast[i]) begin
      				metadata_state_next[i] = WAIT_HEADER;
      			end
      		end
        endcase
      end

      always @(posedge axis_aclk) begin
      	if(~axis_resetn) begin
         	metadata_state[i] <= WAIT_HEADER;
      	end
      	else begin
         	metadata_state[i] <= metadata_state_next[i];
      	end
      end
   end
   endgenerate

   // Per NetFPGA-10G AXI Spec
   localparam DST_POS = 24;
   assign oq = s_axis_tuser[DST_POS] |
   			   (s_axis_tuser[DST_POS + 2] << 1) |
   			   (s_axis_tuser[DST_POS + 4] << 2) |
   			   (s_axis_tuser[DST_POS + 6] << 3) |
   			   ((s_axis_tuser[DST_POS + 1] | s_axis_tuser[DST_POS + 3] | s_axis_tuser[DST_POS + 5] | s_axis_tuser[DST_POS + 7]) << 4);

   always @(*) begin
      state_next     = IDLE;
      cur_queue_next = cur_queue;
      wr_en          = 0;
      metadata_wr_en = 0;
      s_axis_tready  = 0;
      first_word_next = first_word;

      case(state)

        /* cycle between input queues until one is not empty */
        IDLE: begin
           cur_queue_next = oq;
           if(s_axis_tvalid) begin
              if(~|((nearly_full | metadata_nearly_full) & oq)) begin // All interesting oqs are NOT _nearly_ full (able to fit in the maximum pacekt).
                  state_next = WR_PKT;
                  first_word_next = 1'b1;
              end
              else begin
              	  state_next = DROP;
              end
           end
        end

        /* wait until eop */
        WR_PKT: begin
			   state_next = WR_PKT;
           s_axis_tready = 1;
           if(s_axis_tvalid) begin
           		first_word_next = 1'b0;
				wr_en = cur_queue;
				if(first_word) begin
					metadata_wr_en = cur_queue;
				end
				if(s_axis_tlast) begin
					state_next = IDLE;
				end
           end
        end // case: WR_PKT

        DROP: begin
           	state_next = DROP;
           s_axis_tready = 1;
           if(s_axis_tvalid & s_axis_tlast) begin
           	  state_next = IDLE;
           end
        end

      endcase // case(state)
   end // always @ (*)



   always @(posedge axis_aclk) begin
      if(~axis_resetn) begin
         state <= IDLE;
         cur_queue <= 0;
         first_word <= 0;
      end
      else begin
         state <= state_next;
         cur_queue <= cur_queue_next;
         first_word <= first_word_next;
      end

      nearly_full <= nearly_full_fifo;
      metadata_nearly_full <= metadata_nearly_full_fifo;
   end


   assign m0_axis_tdata	 = fifo_out_tdata[0];
   assign m0_axis_tkeep	 = fifo_out_tstrb[0];
   assign m0_axis_tuser	 = fifo_out_tuser[0];
   assign m0_axis_tlast	 = fifo_out_tlast[0];
   assign m0_axis_tvalid	 = ~empty[0];
   assign rd_en[0]			 = m0_axis_tready & ~empty[0];

   assign m1_axis_tdata	 = fifo_out_tdata[1];
   assign m1_axis_tkeep	 = fifo_out_tstrb[1];
   assign m1_axis_tuser	 = fifo_out_tuser[1];
   assign m1_axis_tlast	 = fifo_out_tlast[1];
   assign m1_axis_tvalid	 = ~empty[1];
   assign rd_en[1]			 = m1_axis_tready & ~empty[1];

   assign m2_axis_tdata	 = fifo_out_tdata[2];
   assign m2_axis_tkeep	 = fifo_out_tstrb[2];
   assign m2_axis_tuser	 = fifo_out_tuser[2];
   assign m2_axis_tlast	 = fifo_out_tlast[2];
   assign m2_axis_tvalid	 = ~empty[2];
   assign rd_en[2]			 = m2_axis_tready & ~empty[2];

   assign m3_axis_tdata	 = fifo_out_tdata[3];
   assign m3_axis_tkeep	 = fifo_out_tstrb[3];
   assign m3_axis_tuser	 = fifo_out_tuser[3];
   assign m3_axis_tlast	 = fifo_out_tlast[3];
   assign m3_axis_tvalid	 = ~empty[3];
   assign rd_en[3]			 = m3_axis_tready & ~empty[3];

   assign m4_axis_tdata	 = fifo_out_tdata[4];
   assign m4_axis_tkeep	 = fifo_out_tstrb[4];
   assign m4_axis_tuser	 = fifo_out_tuser[4];
   assign m4_axis_tlast	 = fifo_out_tlast[4];
   assign m4_axis_tvalid	 = ~empty[4];
   assign rd_en[4]			 = m4_axis_tready & ~empty[4];

endmodule
