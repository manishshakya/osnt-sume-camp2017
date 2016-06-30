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
// Version 1.0 (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at:
//
// http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@\n

//////////////////////////////////////////////////////////////////////////////////
// -------------------------------------
//  Defines
// ------------------------------------- 

//  Layer2 Protocols
`define ETH_IP						16'h0800
`define ETH_VLAN_Q	 				16'h8100
`define ETH_VLAN_AD                                     16'h9100

//  Layer3 Protocols
`define IP_VER4						4'h4

`define IP_TCP						8'h06
`define IP_UDP						8'h11


// General FLAGS
// to add/remove a flag just comment/uncomment the related line.
`define PKT_FLG_IPv4					0
`define PKT_FLG_TCP					1
`define PKT_FLG_UDP					2
`define PKT_FLG_VLAN_Q					3
`define PKT_FLG_VLAN_AD                                 4					

// Packet FLAG COUNTS 
// must be set accordingly the number of flags defined
`define PKT_FLAGS					5																			

// PRIORITY VALUE = [0], indicates that the given packet does not adhere to any of the following protocol combinations

`define PRIORITY_WHEN_NO_HIT				0
`define PRIORITY_ETH_IPv4_TCPnUDP			1
`define PRIORITY_ETH_VLAN_IPv4_TCPnUDP			2

//////////////////////////////////////////////////////////////////////////////////
