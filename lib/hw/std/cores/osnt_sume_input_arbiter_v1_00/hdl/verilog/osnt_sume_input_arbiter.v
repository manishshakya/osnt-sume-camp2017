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

`timescale 1ns/1ps

module osnt_sume_input_arbiter
#(
   parameter   C_FAMILY               = "virtex7",
   parameter   FREQ_HZ              = 156.25,

   parameter C_M_AXIS_DATA_WIDTH	   = 256,
   parameter C_S_AXIS_DATA_WIDTH    = 256,
   parameter C_M_AXIS_TUSER_WIDTH   = 128,
   parameter C_S_AXIS_TUSER_WIDTH   = 128
)
(
   input                                     axis_aclk,
   input                                     axis_aresetn,

   //Master Stream Ports (interface to data path)
   output   [C_M_AXIS_DATA_WIDTH-1:0]        m_axis_tdata,
   output   [(C_M_AXIS_DATA_WIDTH/8)-1:0]    m_axis_tkeep,
   output   [C_M_AXIS_TUSER_WIDTH-1:0]       m_axis_tuser,
   output                                    m_axis_tvalid,
   input                                     m_axis_tready,
   output                                    m_axis_tlast,

   //Slave Stream Ports (interface to RX queues)
   input    [C_S_AXIS_DATA_WIDTH-1:0]        s0_axis_tdata,
   input    [(C_S_AXIS_DATA_WIDTH/8)-1:0]    s0_axis_tkeep,
   input    [C_S_AXIS_TUSER_WIDTH-1:0]       s0_axis_tuser,
   input                                     s0_axis_tvalid,
   output                                    s0_axis_tready,
   input                                     s0_axis_tlast,

   input    [C_S_AXIS_DATA_WIDTH-1:0]        s1_axis_tdata,
   input    [(C_S_AXIS_DATA_WIDTH/8)-1:0]    s1_axis_tkeep,
   input    [C_S_AXIS_TUSER_WIDTH-1:0]       s1_axis_tuser,
   input                                     s1_axis_tvalid,
   output                                    s1_axis_tready,
   input                                     s1_axis_tlast,

   input    [C_S_AXIS_DATA_WIDTH-1:0]        s2_axis_tdata,
   input    [(C_S_AXIS_DATA_WIDTH/8)-1:0]    s2_axis_tkeep,
   input    [C_S_AXIS_TUSER_WIDTH-1:0]       s2_axis_tuser,
   input                                     s2_axis_tvalid,
   output                                    s2_axis_tready,
   input                                     s2_axis_tlast,

   input    [C_S_AXIS_DATA_WIDTH-1:0]        s3_axis_tdata,
   input    [(C_S_AXIS_DATA_WIDTH/8)-1:0]    s3_axis_tkeep,
   input    [C_S_AXIS_TUSER_WIDTH-1:0]       s3_axis_tuser,
   input                                     s3_axis_tvalid,
   output                                    s3_axis_tready,
   input                                     s3_axis_tlast,

   input    [C_S_AXIS_DATA_WIDTH-1:0]        s4_axis_tdata,
   input    [(C_S_AXIS_DATA_WIDTH/8)-1:0]    s4_axis_tkeep,
   input    [C_S_AXIS_TUSER_WIDTH-1:0]       s4_axis_tuser,
   input                                     s4_axis_tvalid,
   output                                    s4_axis_tready,
   input                                     s4_axis_tlast
);

localparam  NUM_QUEUES = 5;

input_arbiter
   #(
     .C_M_AXIS_DATA_WIDTH  (  C_M_AXIS_DATA_WIDTH  ),
     .C_S_AXIS_DATA_WIDTH  (  C_S_AXIS_DATA_WIDTH  ),
     .C_M_AXIS_TUSER_WIDTH (  C_M_AXIS_TUSER_WIDTH ),
     .C_S_AXIS_TUSER_WIDTH (  C_S_AXIS_TUSER_WIDTH ),
     .NUM_QUEUES           (  NUM_QUEUES           )
   )
input_arbiter
   (
      //Global Ports
      .axis_aclk           (  axis_aclk            ),
      .axis_resetn         (  axis_aresetn          ),
   
      //Master Stream Ports (interface OPL)
      .m_axis_tdata        (  m_axis_tdata         ),
      .m_axis_tstrb        (  m_axis_tkeep         ),
      .m_axis_tuser        (  m_axis_tuser         ),
      .m_axis_tvalid       (  m_axis_tvalid        ), 
      .m_axis_tready       (  m_axis_tready        ),
      .m_axis_tlast        (  m_axis_tlast         ),
   
      //Slave Stream Ports (interface to RX queues)
      .s_axis_tdata_0	   (  s0_axis_tdata        ),
      .s_axis_tstrb_0	   (  s0_axis_tkeep        ),
      .s_axis_tuser_0	   (  s0_axis_tuser        ),
      .s_axis_tvalid_0	   (  s0_axis_tvalid       ),
      .s_axis_tready_0	   (  s0_axis_tready       ),
      .s_axis_tlast_0	   (  s0_axis_tlast        ),
   
      .s_axis_tdata_1	   (  s1_axis_tdata        ),
      .s_axis_tstrb_1	   (  s1_axis_tkeep        ),
      .s_axis_tuser_1	   (  s1_axis_tuser        ),
      .s_axis_tvalid_1	   (  s1_axis_tvalid       ),
      .s_axis_tready_1	   (  s1_axis_tready       ),
      .s_axis_tlast_1	   (  s1_axis_tlast        ),
   
      .s_axis_tdata_2      (  s2_axis_tdata        ),
      .s_axis_tstrb_2      (  s2_axis_tkeep        ),
      .s_axis_tuser_2      (  s2_axis_tuser        ),
      .s_axis_tvalid_2     (  s2_axis_tvalid       ),
      .s_axis_tready_2     (  s2_axis_tready       ),
      .s_axis_tlast_2      (  s2_axis_tlast        ),
   
      .s_axis_tdata_3      (  s3_axis_tdata        ),
      .s_axis_tstrb_3      (  s3_axis_tkeep        ),
      .s_axis_tuser_3      (  s3_axis_tuser        ),
      .s_axis_tvalid_3     (  s3_axis_tvalid       ),
      .s_axis_tready_3     (  s3_axis_tready       ),
      .s_axis_tlast_3      (  s3_axis_tlast        ),
   
      .s_axis_tdata_4      (  s4_axis_tdata        ),
      .s_axis_tstrb_4      (  s4_axis_tkeep        ),
      .s_axis_tuser_4      (  s4_axis_tuser        ),
      .s_axis_tvalid_4     (  s4_axis_tvalid       ),
      .s_axis_tready_4     (  s4_axis_tready       ),
      .s_axis_tlast_4      (  s4_axis_tlast        )
   );

endmodule
