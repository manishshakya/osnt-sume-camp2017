//
// Copyright (c) 2016 Jong Hun Han
// All rights reserved.
//
// This software was developed by University of Cambridge Computer Laboratory
// under the ENDEAVOUR project (grant agreement 644960) as part of
// the European Union's Horizon 2020 research and innovation programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor license
// agreements.  See the NOTICE file distributed with this work for additional
// information regarding copyright ownership.  NetFPGA licenses this file to you
// under the NetFPGA Hardware-Software License, Version 1.0 (the "License"); you
// may not use this file except in compliance with the License.  You may obtain
// a copy of the License at:
//
// http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@

// Network Protocol Combinations supported


// ETH-IP-TCP/UDP packets
`ifdef PRIORITY_ETH_IPv4_TCPnUDP
	ETH_IPv4_TCPnUDP 
        #(
        	.C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
                .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
                .TUPLE_WIDTH(TUPLE_WIDTH),
                .NUM_INPUT_QUEUES(NUM_INPUT_QUEUES),
                .PRTCL_ID_WIDTH(PRTCL_ID_WIDTH),
                .BYTES_COUNT_WIDTH(BYTES_COUNT_WIDTH),
                .ATTRIBUTE_DATA_WIDTH(ATTRIBUTE_DATA_WIDTH)
        ) ETH_IPv4_TCPnUDP_inst
	(
	// --- Interface to the previous stage
		.in_tdata       (pkt_tdata),
                .in_valid       (pkt_tvalid),
                .in_tlast       (pkt_tlast),
                .in_eoh         (pkt_eoh),
                .in_tuser       (pkt_tuser),

                .pkt_valid      (DECLARATIONS_W[`PRIORITY_ETH_IPv4_TCPnUDP].pkt_valid_int),
                .pkt_attributes (DECLARATIONS_W[`PRIORITY_ETH_IPv4_TCPnUDP].pkt_attributes_int),

	// --- Misc
                .reset          (reset),
                .clk            (clk));
`endif

	 
// ETH-VLAN(802.1q/802.1ad)-IP-TCP/UDP packets
`ifdef PRIORITY_ETH_VLAN_IPv4_TCPnUDP
	ETH_VLAN_IPv4_TCPnUDP 
        #(
                .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
                .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
                .TUPLE_WIDTH(TUPLE_WIDTH),
                .NUM_INPUT_QUEUES(NUM_INPUT_QUEUES),
                .PRTCL_ID_WIDTH(PRTCL_ID_WIDTH),
                .BYTES_COUNT_WIDTH(BYTES_COUNT_WIDTH),
                .ATTRIBUTE_DATA_WIDTH(ATTRIBUTE_DATA_WIDTH)
        ) ETH_VLAN_IPv4_TCPnUDP_inst
	(
	// --- Interface to the previous stage

                .in_tdata       (pkt_tdata),
                .in_valid       (pkt_tvalid),
                .in_tlast       (pkt_tlast),
                .in_eoh         (pkt_eoh),
                .in_tuser       (pkt_tuser),

                .pkt_valid      (DECLARATIONS_W[`PRIORITY_ETH_VLAN_IPv4_TCPnUDP].pkt_valid_int),
                .pkt_attributes (DECLARATIONS_W[`PRIORITY_ETH_VLAN_IPv4_TCPnUDP].pkt_attributes_int),

	// --- Misc
                .reset          (reset),
                .clk            (clk));
`endif
