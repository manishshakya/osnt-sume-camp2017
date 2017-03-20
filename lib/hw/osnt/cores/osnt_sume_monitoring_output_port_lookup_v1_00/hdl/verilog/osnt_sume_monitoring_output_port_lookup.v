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
 * File:
 *    osnt_monitoring_output_port_lookup.v
 *
 * Author:
 *    Gianni Antichi
 *
 * Description:
 */

`include "packet_analyzer/defines.vh"

module osnt_sume_monitoring_output_port_lookup
	#(
  		parameter C_FAMILY 		= "virtex7",
  		parameter C_S_AXI_DATA_WIDTH 	= 32,
  		parameter C_S_AXI_ADDR_WIDTH 	= 32,
  		parameter C_USE_WSTRB 		= 0,
  		parameter C_DPHASE_TIMEOUT 	= 0,
  		parameter C_BASEADDR 	= 32'h76800000,
  		parameter C_HIGHADDR 	= 32'h7680FFFF,
  		//parameter C_BAR1_BASEADDR 	= 32'h74800000,
  		//parameter C_BAR1_HIGHADDR 	= 32'h7480FFFF,
		parameter C_S_AXI_ACLK_FREQ_HZ	= 100,
  		parameter C_M_AXIS_DATA_WIDTH	= 256,
  		parameter C_S_AXIS_DATA_WIDTH	= 256,
  		parameter C_M_AXIS_TUSER_WIDTH 	= 128,
  		parameter C_S_AXIS_TUSER_WIDTH 	= 128,
		parameter TIMESTAMP_WIDTH 	= 64,
      parameter TUPLE_WIDTH 		= 104,
      parameter NETWORK_PROTOCOL_COMBINATIONS = 4,
      parameter MAX_HDR_WORDS 	= 6,
      parameter DIVISION_FACTOR 	= 2,
      parameter BYTES_COUNT_WIDTH 	= 16
  	)
	(
  	// Slave AXI Ports
  		input 					S_AXI_ACLK,
  		input 					S_AXI_ARESETN,
  		input [C_S_AXI_ADDR_WIDTH-1:0] 		S_AXI_AWADDR,
  		input 					S_AXI_AWVALID,
  		input [C_S_AXI_DATA_WIDTH-1:0] 		S_AXI_WDATA,
 	 	input [C_S_AXI_DATA_WIDTH/8-1:0]	S_AXI_WSTRB,
  		input 					S_AXI_WVALID,
  		input 					S_AXI_BREADY,
  		input [C_S_AXI_ADDR_WIDTH-1:0] 		S_AXI_ARADDR,
  		input 					S_AXI_ARVALID,
  		input 					S_AXI_RREADY,
  		output 					S_AXI_ARREADY,
  		output [C_S_AXI_DATA_WIDTH-1:0] 	S_AXI_RDATA,
  		output [1:0] 				S_AXI_RRESP,
  		output 					S_AXI_RVALID,
  		output 					S_AXI_WREADY,
  		output [1:0] 				S_AXI_BRESP,
  		output 					S_AXI_BVALID,
  		output 					S_AXI_AWREADY,
  
  	// Master Stream Ports (interface to data path)
  		output [C_M_AXIS_DATA_WIDTH-1:0] 	M_AXIS_TDATA,
  		output [((C_M_AXIS_DATA_WIDTH/8))-1:0]	M_AXIS_TKEEP,
  		output [C_M_AXIS_TUSER_WIDTH-1:0] 	M_AXIS_TUSER,
  		output 					M_AXIS_TVALID,
  		input 					M_AXIS_TREADY,
  		output 					M_AXIS_TLAST,

  	// Slave Stream Ports (interface to RX queues)
  		input [C_S_AXIS_DATA_WIDTH-1:0] 	S_AXIS_TDATA,
  		input [((C_S_AXIS_DATA_WIDTH/8))-1:0] 	S_AXIS_TKEEP,
  		input [C_S_AXIS_TUSER_WIDTH-1:0] 	S_AXIS_TUSER,
  		input 					S_AXIS_TVALID,
  		output 					S_AXIS_TREADY,
  		input 					S_AXIS_TLAST,

	// Stamp Counter

		input [TIMESTAMP_WIDTH-1:0] 		STAMP_COUNTER
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
 
	// -- Internal Parameters
  	localparam NUM_RO_REGS = 26; 
  	localparam NUM_RW_REGS = 2;

  	localparam NUM_QUEUES = 8;
  	localparam NUM_QUEUES_WIDTH = log2(NUM_QUEUES);
  	localparam MON_LUT_DEPTH = 32;
  	localparam MON_LUT_DEPTH_BITS = log2(MON_LUT_DEPTH);
	localparam IP_WIDTH = 32;
	localparam PROTO_WIDTH = 8;
	localparam PORT_WIDTH = 16;

	localparam NUM_INPUT_QUEUES = 8;
	
	localparam PRCTL_ID_WIDTH = log2(NETWORK_PROTOCOL_COMBINATIONS);
        localparam ATTRIBUTE_DATA_WIDTH = NUM_INPUT_QUEUES+PRCTL_ID_WIDTH+`PKT_FLAGS+BYTES_COUNT_WIDTH+TUPLE_WIDTH;


  	// -- Signals
	wire Bus2IP_Clk;
  	wire Bus2IP_Resetn;
  	wire [C_S_AXI_ADDR_WIDTH-1:0] Bus2IP_Addr;
  	wire Bus2IP_CS;
  	wire Bus2IP_RNW;
  	wire [C_S_AXI_DATA_WIDTH-1:0] Bus2IP_Data;
  	wire [C_S_AXI_DATA_WIDTH/8-1:0] Bus2IP_BE;
  	wire [C_S_AXI_DATA_WIDTH-1:0] l_IP2Bus_Data[1:0];
  	reg IP2Bus_RdAck;
  	reg IP2Bus_WrAck;
  	reg IP2Bus_Error;

  	reg [C_S_AXI_DATA_WIDTH-1:0] IP2Bus_Data;
  	wire [1:0] l_IP2Bus_RdAck;
  	wire [1:0] l_IP2Bus_WrAck;
  	wire [1:0] l_IP2Bus_Error;
  
  	wire [(NUM_RW_REGS*C_S_AXI_DATA_WIDTH)-1:0] rw_regs;
	wire [(NUM_RW_REGS*C_S_AXI_DATA_WIDTH)-1:0] rw_defaults;
  	wire [(NUM_RO_REGS*C_S_AXI_DATA_WIDTH)-1:0] ro_regs;

  	wire rst_stats;
	wire stats_freeze;
	wire [3:0] debug_mode;
	wire force_drop;
	wire tuple_pkt_en;

  	wire [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_0;
  	wire [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_1;
  	wire [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_2;
  	wire [C_S_AXI_DATA_WIDTH-1:0] bytes_cnt_3;

  	wire [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_0;
  	wire [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_1;
  	wire [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_2;
  	wire [C_S_AXI_DATA_WIDTH-1:0] pkt_cnt_3;

	wire [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_0;
        wire [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_1;
        wire [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_2;
        wire [C_S_AXI_DATA_WIDTH-1:0] vlan_cnt_3;

        wire [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_0;
        wire [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_1;
        wire [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_2;
        wire [C_S_AXI_DATA_WIDTH-1:0] ip_cnt_3;

        wire [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_0;
        wire [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_1;
        wire [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_2;
        wire [C_S_AXI_DATA_WIDTH-1:0] udp_cnt_3;

        wire [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_0;
        wire [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_1;
        wire [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_2;
        wire [C_S_AXI_DATA_WIDTH-1:0] tcp_cnt_3;

        wire [C_S_AXI_DATA_WIDTH-1:0] stats_time_high;
        wire [C_S_AXI_DATA_WIDTH-1:0] stats_time_low;

  	wire [MON_LUT_DEPTH_BITS-1:0] mon_rd_addr;
  	wire mon_rd_req;
  	wire [IP_WIDTH-1:0] mon_rd_sip;
  	wire [IP_WIDTH-1:0] mon_rd_sip_mask;
  	wire [IP_WIDTH-1:0] mon_rd_dip;
  	wire [IP_WIDTH-1:0] mon_rd_dip_mask;
  	wire [PROTO_WIDTH-1:0] mon_rd_proto;
  	wire [PROTO_WIDTH-1:0] mon_rd_proto_mask;
  	wire [(2*PORT_WIDTH)-1:0] mon_rd_l4ports;
  	wire [(2*PORT_WIDTH)-1:0] mon_rd_l4ports_mask;
  	wire mon_rd_ack;
  	wire [MON_LUT_DEPTH_BITS-1:0] mon_wr_addr;
  	wire mon_wr_req;
  	wire [IP_WIDTH-1:0] mon_wr_sip;
  	wire [IP_WIDTH-1:0] mon_wr_sip_mask;
  	wire [IP_WIDTH-1:0] mon_wr_dip;
  	wire [IP_WIDTH-1:0] mon_wr_dip_mask;
  	wire [PROTO_WIDTH-1:0] mon_wr_proto;
  	wire [PROTO_WIDTH-1:0] mon_wr_proto_mask;
  	wire [(2*PORT_WIDTH)-1:0] mon_wr_l4ports;
  	wire [(2*PORT_WIDTH)-1:0] mon_wr_l4ports_mask;
  	wire mon_wr_ack;

  	wire [31:0] tbl_wr_proto;
  	wire [31:0] tbl_wr_proto_mask;
  	wire [31:0] tbl_rd_proto;
  	wire [31:0] tbl_rd_proto_mask;


  	sume_axi_ipif
   #(
    		.C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    		.C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
    		.C_BASEADDR (C_BASEADDR),
    		.C_HIGHADDR (C_HIGHADDR)
  	) sume_axi_ipif
  	(
    		.S_AXI_ACLK ( S_AXI_ACLK ),
    		.S_AXI_ARESETN ( S_AXI_ARESETN ),
    		.S_AXI_AWADDR ( S_AXI_AWADDR ),
    		.S_AXI_AWVALID ( S_AXI_AWVALID ),
    		.S_AXI_WDATA ( S_AXI_WDATA ),
    		.S_AXI_WSTRB ( S_AXI_WSTRB ),
    		.S_AXI_WVALID ( S_AXI_WVALID ),
    		.S_AXI_BREADY ( S_AXI_BREADY ),
    		.S_AXI_ARADDR ( S_AXI_ARADDR ),
    		.S_AXI_ARVALID ( S_AXI_ARVALID ),
    		.S_AXI_RREADY ( S_AXI_RREADY ),
    		.S_AXI_ARREADY ( S_AXI_ARREADY ),
    		.S_AXI_RDATA ( S_AXI_RDATA ),
    		.S_AXI_RRESP ( S_AXI_RRESP ),
    		.S_AXI_RVALID ( S_AXI_RVALID ),
    		.S_AXI_WREADY ( S_AXI_WREADY ),
    		.S_AXI_BRESP ( S_AXI_BRESP ),
    		.S_AXI_BVALID ( S_AXI_BVALID ),
    		.S_AXI_AWREADY ( S_AXI_AWREADY ),

	// Controls to the IP/IPIF modules
    		.Bus2IP_Clk ( Bus2IP_Clk ),
    		.Bus2IP_Resetn ( Bus2IP_Resetn ),
    		.Bus2IP_Addr ( Bus2IP_Addr ),
    		.Bus2IP_RNW ( Bus2IP_RNW ),
    		.Bus2IP_BE ( Bus2IP_BE ),
    		.Bus2IP_CS ( Bus2IP_CS ),
    		.Bus2IP_Data ( Bus2IP_Data ),
    		.IP2Bus_Data ( IP2Bus_Data ),
    		.IP2Bus_WrAck ( IP2Bus_WrAck ),
    		.IP2Bus_RdAck ( IP2Bus_RdAck ),
    		.IP2Bus_Error ( IP2Bus_Error )
  	);


  	always @ (posedge Bus2IP_Clk) begin
    		case (l_IP2Bus_RdAck)
       		2'b01: IP2Bus_Data <= l_IP2Bus_Data[0];
       		2'b10: IP2Bus_Data <= l_IP2Bus_Data[1];
       		default: IP2Bus_Data <= {C_S_AXI_DATA_WIDTH{1'b0}};
     		endcase

		IP2Bus_WrAck <= |l_IP2Bus_WrAck;
    	 	IP2Bus_RdAck <= |l_IP2Bus_RdAck;
     		IP2Bus_Error <= |l_IP2Bus_Error;
  	end
  
	// -- IPIF REGS
  	ipif_regs #
  	(
    		.C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    		.C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
    		.NUM_RW_REGS (NUM_RW_REGS),
    		.NUM_RO_REGS (NUM_RO_REGS)
  	) ipif_regs_inst
  	(
    		.Bus2IP_Clk ( Bus2IP_Clk ),
    		.Bus2IP_Resetn ( Bus2IP_Resetn ),
    		.Bus2IP_Addr ( Bus2IP_Addr ),
    		.Bus2IP_CS ( Bus2IP_CS && ~Bus2IP_Addr[15] ), // CS[1] = BAR0
    		.Bus2IP_RNW ( Bus2IP_RNW ),
    		.Bus2IP_Data ( Bus2IP_Data ),
    		.Bus2IP_BE ( Bus2IP_BE ),
    		.IP2Bus_Data ( l_IP2Bus_Data[0] ),
    		.IP2Bus_RdAck ( l_IP2Bus_RdAck[0] ),
    		.IP2Bus_WrAck ( l_IP2Bus_WrAck[0] ),
    		.IP2Bus_Error ( l_IP2Bus_Error[0] ),

    		.rw_regs ( rw_regs ),
		   .rw_defaults ( rw_defaults ),
    		.ro_regs ( ro_regs )
  	);
  
  	// -- Register assignments
  
	assign rw_defaults = 0;
	assign rst_stats = rw_regs[0];
	assign debug_mode = rw_regs[7:4]; //0x1: nf0, 0x2: nf1, 0x4: nf2, 0x8: nf3
	assign force_drop = rw_regs[8]; //0x100
	assign tuple_pkt_en = rw_regs[16]; //0x1_0000
	assign stats_freeze = rw_regs[32+0];

  	assign ro_regs = {stats_time_high,
			            stats_time_low,
			            tcp_cnt_3,
                     tcp_cnt_2,
                     tcp_cnt_1,
                     tcp_cnt_0,
                     udp_cnt_3,
                     udp_cnt_2,
                     udp_cnt_1,
                     udp_cnt_0,
                     ip_cnt_3,
                     ip_cnt_2,
                     ip_cnt_1,
                     ip_cnt_0,
                     vlan_cnt_3,
                     vlan_cnt_2,
                     vlan_cnt_1,
                     vlan_cnt_0,
			            bytes_cnt_3,
                    	bytes_cnt_2,
                    	bytes_cnt_1,
                    	bytes_cnt_0,
                    	pkt_cnt_3,
                    	pkt_cnt_2,
                    	pkt_cnt_1,
                    	pkt_cnt_0};

  	assign mon_wr_proto = tbl_wr_proto[7:0];
  	assign mon_wr_proto_mask = tbl_wr_proto_mask[7:0];
  	assign tbl_rd_proto = mon_rd_proto;
  	assign tbl_rd_proto_mask = mon_rd_proto_mask;

  	// IPIF MON TABLE REGS
  	ipif_table_regs
  	#(
     		.C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
     		.C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
     		.TBL_NUM_COLS (8),
     		.TBL_NUM_ROWS (MON_LUT_DEPTH)
  	) ipif_mon_table_regs_inst
  	(
   		.Bus2IP_Clk ( Bus2IP_Clk ),
   		.Bus2IP_Resetn ( Bus2IP_Resetn ),
   		.Bus2IP_Addr ( Bus2IP_Addr ),
   		.Bus2IP_CS ( Bus2IP_CS && Bus2IP_Addr[15] ), // CS[0] = BAR1
   		.Bus2IP_RNW ( Bus2IP_RNW ),
   		.Bus2IP_Data ( Bus2IP_Data ),
   		.Bus2IP_BE ( Bus2IP_BE ),
   		.IP2Bus_Data ( l_IP2Bus_Data[1] ),
   		.IP2Bus_RdAck ( l_IP2Bus_RdAck[1] ),
   		.IP2Bus_WrAck ( l_IP2Bus_WrAck[1] ),
   		.IP2Bus_Error ( l_IP2Bus_Error[1] ),
   
   		.tbl_rd_req ( mon_rd_req ),
   		.tbl_rd_ack ( mon_rd_ack ),
   		.tbl_rd_addr ( mon_rd_addr ),
   		.tbl_rd_data ( {tbl_rd_proto_mask,
		   		          tbl_rd_proto,
		   		          mon_rd_l4ports_mask,
                   		 mon_rd_l4ports,
                   		 mon_rd_dip_mask,
                   		 mon_rd_dip,
                   		 mon_rd_sip_mask,
                   		 mon_rd_sip}),
   		.tbl_wr_req ( mon_wr_req ),
   		.tbl_wr_ack ( mon_wr_ack ),
   		.tbl_wr_addr ( mon_wr_addr ),
   		.tbl_wr_data ( {tbl_wr_proto_mask,
                   		 tbl_wr_proto,
		   		          mon_wr_l4ports_mask,
		   		          mon_wr_l4ports,
		   		          mon_wr_dip_mask,
		   		          mon_wr_dip,
		   		          mon_wr_sip_mask,
		   		          mon_wr_sip})
	);
  
	// -- Monitoring
  	core_monitoring #
	(
    		.C_M_AXIS_DATA_WIDTH (C_M_AXIS_DATA_WIDTH),
    		.C_S_AXIS_DATA_WIDTH (C_S_AXIS_DATA_WIDTH),
    		.C_M_AXIS_TUSER_WIDTH (C_M_AXIS_TUSER_WIDTH),
    		.C_S_AXIS_TUSER_WIDTH (C_S_AXIS_TUSER_WIDTH),
		.C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    		.NUM_QUEUES (NUM_QUEUES),
    		.MON_LUT_DEPTH_BITS (MON_LUT_DEPTH_BITS),
		.TUPLE_WIDTH (TUPLE_WIDTH),
		.TIMESTAMP_WIDTH (TIMESTAMP_WIDTH),
                .NETWORK_PROTOCOL_COMBINATIONS (NETWORK_PROTOCOL_COMBINATIONS),
                .MAX_HDR_WORDS (MAX_HDR_WORDS),
                .DIVISION_FACTOR (DIVISION_FACTOR),
                .BYTES_COUNT_WIDTH (BYTES_COUNT_WIDTH),
                .ATTRIBUTE_DATA_WIDTH (ATTRIBUTE_DATA_WIDTH)
   	) core_monitoring
  	(
    	// Global Ports
    		.axi_aclk (S_AXI_ACLK),
    		.axi_resetn (S_AXI_ARESETN),

    	// Master Stream Ports (interface to data path)
    		.m_axis_tdata (M_AXIS_TDATA),
    		.m_axis_tstrb (M_AXIS_TKEEP),
    		.m_axis_tuser (M_AXIS_TUSER),
    		.m_axis_tvalid (M_AXIS_TVALID),
    		.m_axis_tready (M_AXIS_TREADY),
    		.m_axis_tlast (M_AXIS_TLAST),

    	// Slave Stream Ports (interface to RX queues)
    		.s_axis_tdata (S_AXIS_TDATA),
    		.s_axis_tstrb (S_AXIS_TKEEP),
    		.s_axis_tuser (S_AXIS_TUSER),
    		.s_axis_tvalid (S_AXIS_TVALID),
    		.s_axis_tready (S_AXIS_TREADY),
    		.s_axis_tlast (S_AXIS_TLAST),

    	// --- interface to monitoring TCAM
    		.mon_rd_addr (mon_rd_addr),
    		.mon_rd_req (mon_rd_req),
    		.mon_rd_rule ({mon_rd_l4ports,
                      	       mon_rd_dip,
                      	       mon_rd_sip,
                      	       mon_rd_proto}),
    		.mon_rd_rulemask ({mon_rd_l4ports_mask,
                      		   mon_rd_dip_mask,
                                   mon_rd_sip_mask,
                                   mon_rd_proto_mask}),
    		.mon_rd_ack (mon_rd_ack),
    		.mon_wr_addr (mon_wr_addr),
    		.mon_wr_req (mon_wr_req),
    		.mon_wr_rule ({mon_wr_l4ports,
                      	       mon_wr_dip,
                               mon_wr_sip,
                               mon_wr_proto}),
    		.mon_wr_rulemask ({mon_wr_l4ports_mask,
                      		   mon_wr_dip_mask,
                      		   mon_wr_sip_mask,
                        	   mon_wr_proto_mask} ),
    		.mon_wr_ack (mon_wr_ack),


    	// --- stats
        	.pkt_cnt_0 (pkt_cnt_0),
                .pkt_cnt_1 (pkt_cnt_1),
                .pkt_cnt_2 (pkt_cnt_2),
                .pkt_cnt_3 (pkt_cnt_3),

                .bytes_cnt_0 (bytes_cnt_0),
                .bytes_cnt_1 (bytes_cnt_1),
                .bytes_cnt_2 (bytes_cnt_2),
                .bytes_cnt_3 (bytes_cnt_3),

                .vlan_cnt_0 (vlan_cnt_0),
                .vlan_cnt_1 (vlan_cnt_1),
                .vlan_cnt_2 (vlan_cnt_2),
                .vlan_cnt_3 (vlan_cnt_3),

                .ip_cnt_0 (ip_cnt_0),
                .ip_cnt_1 (ip_cnt_1),
                .ip_cnt_2 (ip_cnt_2),
                .ip_cnt_3 (ip_cnt_3),

                .udp_cnt_0 (udp_cnt_0),
                .udp_cnt_1 (udp_cnt_1),
                .udp_cnt_2 (udp_cnt_2),
                .udp_cnt_3 (udp_cnt_3),

                .tcp_cnt_0 (tcp_cnt_0),
             	.tcp_cnt_1 (tcp_cnt_1),
                .tcp_cnt_2 (tcp_cnt_2),
                .tcp_cnt_3 (tcp_cnt_3),

                .stats_time_high (stats_time_high),
                .stats_time_low (stats_time_low),

        // --- stats misc
        	.stats_freeze (stats_freeze),
        	.rst_stats (rst_stats),
         .debug_mode (debug_mode),
         .force_drop (force_drop),
         .tuple_pkt_en (tuple_pkt_en),

	// --- ref time
		.stamp_counter (STAMP_COUNTER)
	);
  	endmodule
