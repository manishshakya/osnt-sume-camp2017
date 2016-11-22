//
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
// Junior University
// Copyright (c) 2016 University of Cambridge
// Copyright (c) 2016 Jong Hun Han, Gianni Antichi
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
 *        core_monitoring.v
 *
 *  Author:
 *        Gianni Antichi
 *
 *  Description:
 *        Hardwire the hardware interfaces to CPU and vice versa
 */

module core_monitoring
#(
   //Master AXI Stream Data Width
   parameter C_M_AXIS_DATA_WIDTH    =256,
   parameter C_S_AXIS_DATA_WIDTH             = 256,
   parameter C_M_AXIS_TUSER_WIDTH            = 128,
   parameter C_S_AXIS_TUSER_WIDTH            = 128,
   parameter C_S_AXI_DATA_WIDTH              = 32,
   parameter SRC_PORT_POS                    = 16,
   parameter DST_PORT_POS                    = 24,
   parameter NUM_QUEUES                      = 8,
   parameter MON_LUT_DEPTH_BITS              = 5,
   parameter TUPLE_WIDTH                     = 104,
   parameter NETWORK_PROTOCOL_COMBINATIONS   = 4,
   parameter MAX_HDR_WORDS = 6,
   parameter DIVISION_FACTOR = 2,
   parameter BYTES_COUNT_WIDTH = 16,
   parameter TIMESTAMP_WIDTH = 64,
   parameter ATTRIBUTE_DATA_WIDTH = 135
)
(
    // Global Ports
    input axi_aclk,
    input axi_resetn,

    	// Master Stream Ports (interface to data path)
    		output reg [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    		output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tstrb,
    		output reg [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    		output reg m_axis_tvalid,
    		input  m_axis_tready,
    		output reg m_axis_tlast,

    	// Slave Stream Ports (interface to RX queues)
    		input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    		input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb,
    		input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    		input  s_axis_tvalid,
    		output s_axis_tready,
    		input  s_axis_tlast,

    	// TCAM
    		input [MON_LUT_DEPTH_BITS-1:0] mon_rd_addr,
    		input mon_rd_req,
    		output [TUPLE_WIDTH-1:0] mon_rd_rule,
    		output [TUPLE_WIDTH-1:0] mon_rd_rulemask,
    		output mon_rd_ack,

    		input [MON_LUT_DEPTH_BITS-1:0] mon_wr_addr,
    		input mon_wr_req,
    		input [TUPLE_WIDTH-1:0] mon_wr_rule,
    		input [TUPLE_WIDTH-1:0] mon_wr_rulemask,
    		output mon_wr_ack,

    	// stats handler
                output [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_0,
                output [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_1,
                output [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_2,
                output [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_3,

                output [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_0,
                output [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_1,
                output [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_2,
                output [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_3,

                output [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_0,
                output [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_1,
                output [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_2,
                output [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_3,

                output [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_0,
                output [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_1,
                output [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_2,
                output [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_3,

                output [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_0,
                output [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_1,
                output [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_2,
                output [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_3,

                output [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_0,
                output [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_1,
                output [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_2,
                output [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_3,

                output [C_S_AXI_DATA_WIDTH-1:0] stats_time_high,
                output [C_S_AXI_DATA_WIDTH-1:0] stats_time_low,

	// stamp counter
		input [TIMESTAMP_WIDTH-1:0]	stamp_counter,

	// stats misc
		input				stats_freeze,
		input				rst_stats,
      input [3:0]           debug_mode,
      input                force_drop,
      input               tuple_pkt_en 
	);


	//--------------------- Internal Parameter-------------------------

   	localparam NUM_STATES               = 4;
   	localparam WAIT_TILL_DONE_DECODE    = 1;
   	localparam IN_PACKET                = 2;
   	localparam SM_PACKET                = 3;
   	localparam FLUSH                    = 4;

   	localparam METADATA_TUSER	    = 32;
       
	//---------------------- Wires and regs---------------------------

	wire [ATTRIBUTE_DATA_WIDTH-1:0]		pkt_attributes;
	wire					pkt_valid;
	wire [192-1:0]		tuple_pkt_attributes;
	wire					tuple_pkt_valid;
        wire [ATTRIBUTE_DATA_WIDTH-1:0]         pkt_attributes_w;
        wire                                    pkt_valid_w;
        reg [ATTRIBUTE_DATA_WIDTH-1:0]          pkt_attributes_reg;
        reg                                     pkt_valid_reg;
  
   	wire                         		lookup_done;

   	reg                          		in_fifo_rd_en;
   	wire                         		in_fifo_nearly_full;
   	wire                         		in_fifo_empty;

   	wire [NUM_QUEUES-1:0]        		dst_ports;
   	wire [NUM_QUEUES-1:0]			fifo_dst_ports;
 
   	wire					hit_fifo_empty;
   	reg					hit_fifo_rd_en;

   	wire [C_S_AXIS_TUSER_WIDTH-1:0] 	tuser_fifo;
   	wire [((C_M_AXIS_DATA_WIDTH/8))-1:0] 	tstrb_fifo;
   	wire 					tlast_fifo;
   	wire [C_M_AXIS_DATA_WIDTH-1:0]        	tdata_fifo;

   	wire [TUPLE_WIDTH-1:0]       		mon_rd_rulemask_inverted;

   	reg [NUM_STATES-1:0]			state,state_next;


   //------------------------- Modules-------------------------------

assign mon_rd_rulemask = ~mon_rd_rulemask_inverted;
assign s_axis_tready = !in_fifo_nearly_full;
assign pkt_valid_w = pkt_valid_reg;
assign pkt_attributes_w = pkt_attributes_reg;

packet_analyzer
#(
   .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
   .NETWORK_PROTOCOL_COMBINATIONS(NETWORK_PROTOCOL_COMBINATIONS),
   .MAX_HDR_WORDS(MAX_HDR_WORDS),
   .DIVISION_FACTOR(DIVISION_FACTOR),
   .NUM_INPUT_QUEUES(NUM_QUEUES),
   .BYTES_COUNT_WIDTH(BYTES_COUNT_WIDTH),
   .TUPLE_WIDTH(TUPLE_WIDTH),
   .ATTRIBUTE_DATA_WIDTH(ATTRIBUTE_DATA_WIDTH)
) packet_analyzer
(
   // --- input
   .tdata(s_axis_tdata),
   .tuser(s_axis_tuser),
   .valid(s_axis_tvalid & ~in_fifo_nearly_full),
   .tlast(s_axis_tlast),

   .tuple_pkt_en  (  tuple_pkt_en),

   // --- output 
   .pkt_valid(pkt_valid),
   .pkt_attributes(pkt_attributes),
        
	// --- misc
   .reset(~axi_resetn),
   .clk(axi_aclk)
);

tuple_packet_analyzer
#(
   .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
   .NETWORK_PROTOCOL_COMBINATIONS(NETWORK_PROTOCOL_COMBINATIONS),
   .MAX_HDR_WORDS(MAX_HDR_WORDS),
   .DIVISION_FACTOR(DIVISION_FACTOR),
   .NUM_INPUT_QUEUES(NUM_QUEUES),
   .BYTES_COUNT_WIDTH(BYTES_COUNT_WIDTH),
   .TUPLE_WIDTH(TUPLE_WIDTH),
   .ATTRIBUTE_DATA_WIDTH(192)
) tuple_packet_analyzer
(
   // --- input
   .tdata(s_axis_tdata),
   .tuser(s_axis_tuser),
   .valid(s_axis_tvalid & ~in_fifo_nearly_full),
   .tlast(s_axis_tlast),

   .tuple_pkt_en  (  tuple_pkt_en),

   // --- output 
   .pkt_valid(tuple_pkt_valid),
   .pkt_attributes(tuple_pkt_attributes),
        
	// --- misc
   .reset(~axi_resetn),
   .clk(axi_aclk)
);

reg tuple_pkt_valid_r;

always @(posedge axi_aclk)
   if (~axi_resetn)
      tuple_pkt_valid_r    <= 0;
   else
      tuple_pkt_valid_r    <= tuple_pkt_valid;

wire  tuple_pkt_valid_w = tuple_pkt_valid & ~tuple_pkt_valid_r;


wire  [191:0] tuple_pkt_attributes_out;
wire  tuple_pkt_nearly_full, tuple_pkt_empty;
reg   tuple_pkt_rd_en;

fallthrough_small_fifo
#(
   .WIDTH(192),
   .MAX_DEPTH_BITS(8)
)
tuple_pkt_fifo
(
   .din        (tuple_pkt_attributes),  // Data in
   .wr_en      (tuple_pkt_valid_w),               // Write enable
   .rd_en      (tuple_pkt_rd_en),       // Read the next word
   .dout       (tuple_pkt_attributes_out),
   .full       (),
   .prog_full  (),
   .nearly_full (tuple_pkt_nearly_full),
   .empty (tuple_pkt_empty),
   .reset (~axi_resetn),
   .clk (axi_aclk)
);


stats_handler
#(
   .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
   .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
   .ATTRIBUTE_DATA_WIDTH(ATTRIBUTE_DATA_WIDTH),
   .NUM_INPUT_QUEUES(NUM_QUEUES),
   .TUPLE_WIDTH(TUPLE_WIDTH),
   .BYTES_COUNT_WIDTH(BYTES_COUNT_WIDTH)
)
stats_handler
(
   // --- input
   .pkt_attributes(pkt_attributes_w),
   .pkt_valid(pkt_valid_w),
   .stamp_counter(stamp_counter),
   .stats_freeze(stats_freeze),
   .rst_stats(rst_stats),

   // --- output
   .pkt_cnt_0(pkt_cnt_0),
   .pkt_cnt_1(pkt_cnt_1),
   .pkt_cnt_2(pkt_cnt_2),
   .pkt_cnt_3(pkt_cnt_3),

   .bytes_cnt_0(bytes_cnt_0),
   .bytes_cnt_1(bytes_cnt_1),
   .bytes_cnt_2(bytes_cnt_2),
   .bytes_cnt_3(bytes_cnt_3),

   .vlan_cnt_0(vlan_cnt_0),
   .vlan_cnt_1(vlan_cnt_1),
   .vlan_cnt_2(vlan_cnt_2),
   .vlan_cnt_3(vlan_cnt_3),

   .ip_cnt_0(ip_cnt_0),
   .ip_cnt_1(ip_cnt_1),
   .ip_cnt_2(ip_cnt_2),
   .ip_cnt_3(ip_cnt_3),

   .udp_cnt_0(udp_cnt_0),
   .udp_cnt_1(udp_cnt_1),
   .udp_cnt_2(udp_cnt_2),
   .udp_cnt_3(udp_cnt_3),

   .tcp_cnt_0(tcp_cnt_0),
   .tcp_cnt_1(tcp_cnt_1),
   .tcp_cnt_2(tcp_cnt_2),
   .tcp_cnt_3(tcp_cnt_3),

   .stats_time_high(stats_time_high),
   .stats_time_low(stats_time_low),

   // --- misc
   .reset(~axi_resetn),
   .clk(axi_aclk)
);

	
process_pkt
#(
   .TUPLE_WIDTH (TUPLE_WIDTH),
   .NUM_QUEUES (NUM_QUEUES),
   .MON_LUT_DEPTH_BITS(MON_LUT_DEPTH_BITS)
)
process_pkt
(
   // --- input
   .tuple(pkt_attributes_w[TUPLE_WIDTH-1:0]),
   .src_port(pkt_attributes_w[ATTRIBUTE_DATA_WIDTH-1:ATTRIBUTE_DATA_WIDTH-NUM_QUEUES]),
   .lookup_req (pkt_valid_w),

   .debug_mode(debug_mode),

   // --- output
   .dst_ports (dst_ports),
   .lookup_done (lookup_done),

	// --- TCAM management
   .rule_rd_addr(mon_rd_addr),
   .rule_rd_req(mon_rd_req),
   .rule_rd(mon_rd_rule),
   .rule_rd_mask(mon_rd_rulemask_inverted),
   .rule_rd_ack(mon_rd_ack),
   .rule_wr_addr(mon_wr_addr),
   .rule_wr_req(mon_wr_req),
   .rule_wr(mon_wr_rule),
   .rule_wr_mask(~mon_wr_rulemask),
   .rule_wr_ack(mon_wr_ack),

   // --- misc
   .reset(~axi_resetn),
   .clk(axi_aclk)
);


/* The size of this fifo has to be large enough to fit the previous modules' headers
	and the ethernet header */

fallthrough_small_fifo
#(
   .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
   .MAX_DEPTH_BITS(8)
)
pkt_fifo
(
   .din ({s_axis_tlast, s_axis_tuser, s_axis_tstrb, s_axis_tdata}),  // Data in
   .wr_en (s_axis_tvalid & ~in_fifo_nearly_full),               // Write enable
   .rd_en (in_fifo_rd_en),       // Read the next word
   .dout ({tlast_fifo, tuser_fifo, tstrb_fifo, tdata_fifo}),
   .full (),
   .prog_full (),
   .nearly_full (in_fifo_nearly_full),
   .empty (in_fifo_empty),
   .reset (~axi_resetn),
   .clk (axi_aclk)
);


	fallthrough_small_fifo
	#(
		.WIDTH(NUM_QUEUES),
		.MAX_DEPTH_BITS(8))
      	hit_fifo
        (
		.din (dst_ports),     // Data in
         	.wr_en (lookup_done),               // Write enable
         	.rd_en (hit_fifo_rd_en),       // Read the next word
         	.dout (fifo_dst_ports),
         	.full (),
         	.prog_full (),
         	.nearly_full (),
         	.empty (hit_fifo_empty),
         	.reset (~axi_resetn),
         	.clk (axi_aclk));


/*********************************************************************
 * Wait until the TUPLE has been searched in TCAM, then write the 
 * module header and move the packet to the right output queue/s
 **********************************************************************/

always @(*) begin
   m_axis_tuser = tuser_fifo;
   m_axis_tstrb = (tuple_pkt_en) ? 32'hffff_ff00 : tstrb_fifo;
   m_axis_tlast = tlast_fifo;
   m_axis_tdata = (tuple_pkt_en) ? {tuple_pkt_attributes_out, {(256-192){1'b0}}} : tdata_fifo;
   m_axis_tvalid = 0;
   in_fifo_rd_en = 0;
   hit_fifo_rd_en = 0;
   tuple_pkt_rd_en = 0;
   state_next = WAIT_TILL_DONE_DECODE;
   case(state)
      WAIT_TILL_DONE_DECODE: begin
         state_next = WAIT_TILL_DONE_DECODE;
         if(!hit_fifo_empty & ~tuple_pkt_empty) begin
            if(|fifo_dst_ports && ~force_drop) begin
				   m_axis_tlast = (tuple_pkt_en) ? 1 : 0;
				   m_axis_tvalid = 1;
               m_axis_tuser[DST_PORT_POS+7:DST_PORT_POS] = (debug_mode == 0) ? fifo_dst_ports :
                                                           {debug_mode[3],1'b0,debug_mode[2],1'b0,debug_mode[1],1'b0,debug_mode[0],1'b0} & fifo_dst_ports;
               m_axis_tuser[0+:16] = (tuple_pkt_en) ? 16'h0018 : tuser_fifo[0+:16];
					if(m_axis_tready) begin
					   in_fifo_rd_en = 1;
						hit_fifo_rd_en = 1;
                  tuple_pkt_rd_en = 1;
						state_next = (tuple_pkt_en) ? SM_PACKET : IN_PACKET;
					end
				end
				else begin
					in_fifo_rd_en = 1;
					if(tlast_fifo) begin
                  tuple_pkt_rd_en = 1;
						hit_fifo_rd_en = 1;
               end
				end
			end
         else if (in_fifo_nearly_full) begin
            in_fifo_rd_en = 1;
            if (tlast_fifo) begin
               hit_fifo_rd_en = ~hit_fifo_empty;
               tuple_pkt_rd_en = ~tuple_pkt_empty;
               state_next = WAIT_TILL_DONE_DECODE;
            end
            else begin
               state_next = FLUSH;
            end
         end
		end
      IN_PACKET: begin
         state_next = IN_PACKET;
		   if(!in_fifo_empty) begin
				m_axis_tvalid = 1;
				if(m_axis_tready) begin
					in_fifo_rd_en = 1;
					if(tlast_fifo)
                  state_next = WAIT_TILL_DONE_DECODE;
				end
			end
		end
      SM_PACKET: begin
         state_next = SM_PACKET;
		   if(!in_fifo_empty) begin
					in_fifo_rd_en = 1;
					if(tlast_fifo)
                  state_next = WAIT_TILL_DONE_DECODE;
			end
		end
      FLUSH: begin
         state_next = FLUSH;
		   in_fifo_rd_en = 1;
			if(tlast_fifo) begin
               hit_fifo_rd_en = ~hit_fifo_empty;
               tuple_pkt_rd_en = ~tuple_pkt_empty;
               state_next = WAIT_TILL_DONE_DECODE;
			end
		end
   endcase // case(state)
end // always @ (*)


always @(posedge axi_aclk) begin
   if(~axi_resetn) begin
      state 		         <= WAIT_TILL_DONE_DECODE;
		pkt_valid_reg        <= 0;
		pkt_attributes_reg   <= 0;
   end
   else begin
      state                <= state_next;
      pkt_valid_reg        <= pkt_valid;
      pkt_attributes_reg   <= pkt_attributes;
	end
end

endmodule // output_port_lookup

