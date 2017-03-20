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
 *        packet_analyzer.v
 *
 *  Author:
 *        Muhammad Shahbaz, Gianni Antichi
 *
 *  Description:
 *        Hardwire the hardware interfaces to CPU and vice versa
 */

`timescale 1ns/1ps

`include "defines.vh"

module tuple_packet_analyzer
#(
   parameter   C_S_AXIS_DATA_WIDTH              = 256,
   parameter   C_S_AXIS_TUSER_WIDTH             = 128,
   parameter   NETWORK_PROTOCOL_COMBINATIONS    = 4,
   parameter   MAX_HDR_WORDS                    = 6,
   parameter   DIVISION_FACTOR                  = 2,
   parameter   PRTCL_ID_WIDTH                   = 2,
   parameter   NUM_INPUT_QUEUES                 = 8,
   parameter   BYTES_COUNT_WIDTH                = 16,
   parameter   TUPLE_WIDTH                      = 104,
   parameter   ATTRIBUTE_DATA_WIDTH             = 135
)
(
   // --- Interface to the previous stage
   input          [C_S_AXIS_DATA_WIDTH-1:0]     tdata,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]    tuser,
   input                                        valid,
   input                                        tlast,
   
   // --- Results 
   input                                        tuple_pkt_en,

   output                                       pkt_valid,
   output         [ATTRIBUTE_DATA_WIDTH-1:0]    pkt_attributes,
   //{input_port, prtcl_id, pkt_flags, bytes, l4 dst port, l4 src port, dest ip, src ip, proto}
 
   // --- Misc
   input                                        reset,
   input                                        clk
);

//---------------------- Wires/Regs -------------------------------
wire [C_S_AXIS_DATA_WIDTH-1:0]   pkt_tdata;
wire [C_S_AXIS_TUSER_WIDTH-1:0]  pkt_tuser;
wire  pkt_eoh;
wire  pkt_tlast;
wire  pkt_tvalid;

//------------------------ Logic ----------------------------------
packet_monitor
#(
   .C_S_AXIS_DATA_WIDTH    (  C_S_AXIS_DATA_WIDTH     ),
   .C_S_AXIS_TUSER_WIDTH   (  C_S_AXIS_TUSER_WIDTH    ),
   .MAX_HDR_WORDS          (  MAX_HDR_WORDS           )
)
packet_monitor_inst
(
   // --- Interface to the previous stage
   .tdata                  (  tdata                   ),
   .valid                  (  valid                   ),
   .tlast                  (  tlast                   ),
   .tuser                  (  tuser                   ),
   // --- Results 
   .out_tdata              (  pkt_tdata               ),
   .out_tuser              (  pkt_tuser               ),
   .out_valid              (  pkt_tvalid              ),
   .out_eoh                (  pkt_eoh                 ),
   .out_tlast              (  pkt_tlast               ),

   .sample_results         (),
    
   // --- Misc
   .reset                  (reset                     ),
   .clk                    (clk                       )
);

tuple_ETH_IPv4_TCPnUDP
#(
   .C_S_AXIS_DATA_WIDTH    (  C_S_AXIS_DATA_WIDTH     ),
   .C_S_AXIS_TUSER_WIDTH   (  C_S_AXIS_TUSER_WIDTH    ),
   .TUPLE_WIDTH            (  TUPLE_WIDTH             ),
   .NUM_INPUT_QUEUES       (  NUM_INPUT_QUEUES        ),
   .PRTCL_ID_WIDTH         (  PRTCL_ID_WIDTH          ),
   .BYTES_COUNT_WIDTH      (  BYTES_COUNT_WIDTH       ),
   .ATTRIBUTE_DATA_WIDTH   (  ATTRIBUTE_DATA_WIDTH    )
)
tuple_ETH_IPv4_TCPnUDP
(
   // --- Interface to the previous stage
   .in_tdata               (  pkt_tdata               ),
   .in_valid               (  pkt_tvalid              ),
   .in_tlast               (  pkt_tlast               ),
   .in_eoh                 (  pkt_eoh                 ),
   .in_tuser               (  pkt_tuser               ),

   .tuple_pkt_en           (  tuple_pkt_en            ),

   .pkt_valid              (  pkt_valid               ),
   .pkt_attributes         (  pkt_attributes          ),

   // --- Misc
   .reset                  (  reset                   ),
   .clk                    (  clk                     )
);

    endmodule
