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

module osnt_sume_mem_pcap_replay_uengine
#(
   parameter   C_S_AXI_DATA_WIDTH   = 32,
   parameter   C_S_AXI_ADDR_WIDTH   = 32,
   parameter   C_BASEADDR           = 32'hFFFFFFFF,
   parameter   C_HIGHADDR           = 32'h00000000,
   parameter   C_USE_WSTRB          = 0,
   parameter   C_DPHASE_TIMEOUT     = 0,
   parameter   C_S_AXI_ACLK_FREQ_HZ = 100,
   parameter   C_M_AXIS_DATA_WIDTH  = 256,
   parameter   C_S_AXIS_DATA_WIDTH  = 256,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128,
   parameter   SRC_PORT_POS         = 16,
   parameter   NUM_QUEUES           = 4,
   parameter   MEM_DEPTH            = 20 
)
(
   // Slave AXI Ports
   input                                                 s_axi_aclk,
   input                                                 s_axi_aresetn,
   input          [C_S_AXI_ADDR_WIDTH-1:0]               s_axi_awaddr,
   input                                                 s_axi_awvalid,
   input          [C_S_AXI_DATA_WIDTH-1:0]               s_axi_wdata,
   input          [C_S_AXI_DATA_WIDTH/8-1:0]             s_axi_wstrb,
   input                                                 s_axi_wvalid,
   input                                                 s_axi_bready,
   input          [C_S_AXI_ADDR_WIDTH-1:0]               s_axi_araddr,
   input                                                 s_axi_arvalid,
   input                                                 s_axi_rready,
   output                                                s_axi_arready,
   output         [C_S_AXI_DATA_WIDTH-1:0]               s_axi_rdata,
   output         [1:0]                                  s_axi_rresp,
   output                                                s_axi_rvalid,
   output                                                s_axi_wready,
   output         [1:0]                                  s_axi_bresp,
   output                                                s_axi_bvalid,
   output                                                s_axi_awready,

   // Master Stream Ports (interface to data path)
   input                                                 axis_aclk,
   input                                                 axis_aresetn,

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

   // Slave Stream Ports (interface to RX queues)
   input          [C_S_AXIS_DATA_WIDTH-1:0]              s_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast,

   // External Memory Stream Ports (interface to RX queues)
   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m00_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m00_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m00_axis_tuser,
   output   reg                                          m00_axis_tvalid,
   input                                                 m00_axis_tready,
   output   reg                                          m00_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s00_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s00_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s00_axis_tuser,
   input                                                 s00_axis_tvalid,
   output                                                s00_axis_tready,
   input                                                 s00_axis_tlast,

   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m01_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m01_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m01_axis_tuser,
   output   reg                                          m01_axis_tvalid,
   input                                                 m01_axis_tready,
   output   reg                                          m01_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s01_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s01_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s01_axis_tuser,
   input                                                 s01_axis_tvalid,
   output                                                s01_axis_tready,
   input                                                 s01_axis_tlast,

   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m02_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m02_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m02_axis_tuser,
   output   reg                                          m02_axis_tvalid,
   input                                                 m02_axis_tready,
   output   reg                                          m02_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s02_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s02_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s02_axis_tuser,
   input                                                 s02_axis_tvalid,
   output                                                s02_axis_tready,
   input                                                 s02_axis_tlast,

   output   reg   [C_M_AXIS_DATA_WIDTH-1:0]              m03_axis_tdata,
   output   reg   [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m03_axis_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             m03_axis_tuser,
   output   reg                                          m03_axis_tvalid,
   input                                                 m03_axis_tready,
   output   reg                                          m03_axis_tlast,

   input          [C_S_AXIS_DATA_WIDTH-1:0]              s03_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s03_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s03_axis_tuser,
   input                                                 s03_axis_tvalid,
   output                                                s03_axis_tready,
   input                                                 s03_axis_tlast,

   output                                                sw_rst,
   
   output                                                q0_start_replay,
   output                                                q1_start_replay,
   output                                                q2_start_replay,
   output                                                q3_start_replay,
   
   output         [C_S_AXI_DATA_WIDTH-1:0]               q0_replay_count,
   output         [C_S_AXI_DATA_WIDTH-1:0]               q1_replay_count,
   output         [C_S_AXI_DATA_WIDTH-1:0]               q2_replay_count,
   output         [C_S_AXI_DATA_WIDTH-1:0]               q3_replay_count
);

// -- Internal Parameters
localparam NUM_RW_REGS = 26;
localparam NUM_WO_REGS = 0;
localparam NUM_RO_REGS = 0;

// -- Signals
wire  [NUM_RW_REGS*C_S_AXI_DATA_WIDTH:0]           rw_regs;
 
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q0_addr_low;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q0_addr_high;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q1_addr_low;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q1_addr_high;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q2_addr_low;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q2_addr_high;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q3_addr_low;
wire  [C_S_AXI_DATA_WIDTH-1:0]                     q3_addr_high;
                                                  
wire                                               q0_enable;
wire                                               q1_enable;
wire                                               q2_enable;
wire                                               q3_enable;
                                                  
wire                                               q0_wr_done;
wire                                               q1_wr_done;
wire                                               q2_wr_done;
wire                                               q3_wr_done;
                                                  
wire  [C_S_AXI_DATA_WIDTH-1:0]                     conf_path;

pcap_mem_store
#(
   .C_M_AXIS_DATA_WIDTH       (  C_M_AXIS_DATA_WIDTH     ),
   .C_S_AXIS_DATA_WIDTH       (  C_S_AXIS_DATA_WIDTH     ),
   .C_M_AXIS_TUSER_WIDTH      (  C_M_AXIS_TUSER_WIDTH    ),
   .C_S_AXIS_TUSER_WIDTH      (  C_S_AXIS_TUSER_WIDTH    ),
   .SRC_PORT_POS              (  SRC_PORT_POS            ),
   .NUM_QUEUES                (  NUM_QUEUES              )
)
pcap_mem_store
(
   .axis_aclk                 (  axis_aclk               ),
   .axis_aresetn              (  axis_aresetn            ),

   //Master Stream Ports to external memory for pcap storing
   .m0_axis_tdata             (  m00_axis_tdata          ),
   .m0_axis_tkeep             (  m00_axis_tkeep          ),
   .m0_axis_tuser             (  m00_axis_tuser          ),
   .m0_axis_tvalid            (  m00_axis_tvalid         ),
   .m0_axis_tready            (  m00_axis_tready         ),
   .m0_axis_tlast             (  m00_axis_tlast          ),
             
   .m1_axis_tdata             (  m01_axis_tdata          ),
   .m1_axis_tkeep             (  m01_axis_tkeep          ),
   .m1_axis_tuser             (  m01_axis_tuser          ),
   .m1_axis_tvalid            (  m01_axis_tvalid         ),
   .m1_axis_tready            (  m01_axis_tready         ),
   .m1_axis_tlast             (  m01_axis_tlast          ),

   .m2_axis_tdata             (  m02_axis_tdata          ),
   .m2_axis_tkeep             (  m02_axis_tkeep          ),
   .m2_axis_tuser             (  m02_axis_tuser          ),
   .m2_axis_tvalid            (  m02_axis_tvalid         ),
   .m2_axis_tready            (  m02_axis_tready         ),
   .m2_axis_tlast             (  m02_axis_tlast          ),

   .m3_axis_tdata             (  m03_axis_tdata          ),
   .m3_axis_tkeep             (  m03_axis_tkeep          ),
   .m3_axis_tuser             (  m03_axis_tuser          ),
   .m3_axis_tvalid            (  m03_axis_tvalid         ),
   .m3_axis_tready            (  m03_axis_tready         ),
   .m3_axis_tlast             (  m03_axis_tlast          ),

   //Slave Stream Ports from host over DMA 
   .s_axis_tdata              (  s_axis_tdata            ),
   .s_axis_tkeep              (  s_axis_tkeep            ),
   .s_axis_tuser              (  s_axis_tuser            ),
   .s_axis_tvalid             (  s_axis_tvalid           ),
   .s_axis_tready             (  s_axis_tready           ),
   .s_axis_tlast              (  s_axis_tlast            )
);

pcap_mem_replay
#(
   .C_M_AXIS_DATA_WIDTH       (  C_M_AXIS_DATA_WIDTH     ),
   .C_S_AXIS_DATA_WIDTH       (  C_S_AXIS_DATA_WIDTH     ),
   .C_M_AXIS_TUSER_WIDTH      (  C_M_AXIS_TUSER_WIDTH    ),
   .C_S_AXIS_TUSER_WIDTH      (  C_S_AXIS_TUSER_WIDTH    ),
   .NUM_QUEUES                (  NUM_QUEUES              )
)
pcap_mem_replay
(
   // Master Stream Ports (interface to data path)
   .axis_aclk                 (  axis_aclk               ),
   .axis_aresetn              (  axis_aresetn            ),
                                             
   .sw_rst                    (  sw_rst                  ),

   //Master to pipeline
   .m0_axis_tdata             (  m0_axis_tdata           ),
   .m0_axis_tkeep             (  m0_axis_tkeep           ),
   .m0_axis_tuser             (  m0_axis_tuser           ),
   .m0_axis_tvalid            (  m0_axis_tvalid          ),
   .m0_axis_tready            (  m0_axis_tready          ),
   .m0_axis_tlast             (  m0_axis_tlast           ),
                                                
   .m1_axis_tdata             (  m1_axis_tdata           ),
   .m1_axis_tkeep             (  m1_axis_tkeep           ),
   .m1_axis_tuser             (  m1_axis_tuser           ),
   .m1_axis_tvalid            (  m1_axis_tvalid          ),
   .m1_axis_tready            (  m1_axis_tready          ),
   .m1_axis_tlast             (  m1_axis_tlast           ),
                                                
   .m2_axis_tdata             (  m2_axis_tdata           ),
   .m2_axis_tkeep             (  m2_axis_tkeep           ),
   .m2_axis_tuser             (  m2_axis_tuser           ),
   .m2_axis_tvalid            (  m2_axis_tvalid          ),
   .m2_axis_tready            (  m2_axis_tready          ),
   .m2_axis_tlast             (  m2_axis_tlast           ),
                                                
   .m3_axis_tdata             (  m3_axis_tdata           ),
   .m3_axis_tkeep             (  m3_axis_tkeep           ),
   .m3_axis_tuser             (  m3_axis_tuser           ),
   .m3_axis_tvalid            (  m3_axis_tvalid          ),
   .m3_axis_tready            (  m3_axis_tready          ),
   .m3_axis_tlast             (  m3_axis_tlast           ),

   //Slave from external Memory Stream Ports
   .s0_axis_tdata             (  s00_axis_tdata          ),
   .s0_axis_tkeep             (  s00_axis_tkeep          ),
   .s0_axis_tuser             (  s00_axis_tuser          ),
   .s0_axis_tvalid            (  s00_axis_tvalid         ),
   .s0_axis_tready            (  s00_axis_tready         ),
   .s0_axis_tlast             (  s00_axis_tlast          ),
              
   .s1_axis_tdata             (  s01_axis_tdata          ),
   .s1_axis_tkeep             (  s01_axis_tkeep          ),
   .s1_axis_tuser             (  s01_axis_tuser          ),
   .s1_axis_tvalid            (  s01_axis_tvalid         ),
   .s1_axis_tready            (  s01_axis_tready         ),
   .s1_axis_tlast             (  s01_axis_tlast          ),
              
   .s2_axis_tdata             (  s02_axis_tdata          ),
   .s2_axis_tkeep             (  s02_axis_tkeep          ),
   .s2_axis_tuser             (  s02_axis_tuser          ),
   .s2_axis_tvalid            (  s02_axis_tvalid         ),
   .s2_axis_tready            (  s02_axis_tready         ),
   .s2_axis_tlast             (  s02_axis_tlast          ),
              
   .s3_axis_tdata             (  s03_axis_tdata          ),
   .s3_axis_tkeep             (  s03_axis_tkeep          ),
   .s3_axis_tuser             (  s03_axis_tuser          ),
   .s3_axis_tvalid            (  s03_axis_tvalid         ),
   .s3_axis_tready            (  s03_axis_tready         ),
   .s3_axis_tlast             (  s03_axis_tlast          )
);

// -- AXILITE Registers
axi_lite_regs
#(
   .C_S_AXI_DATA_WIDTH        (  C_S_AXI_DATA_WIDTH      ),
   .C_S_AXI_ADDR_WIDTH        (  C_S_AXI_ADDR_WIDTH      ),
   .C_USE_WSTRB               (  C_USE_WSTRB             ),
   .C_DPHASE_TIMEOUT          (  C_DPHASE_TIMEOUT        ),
   .C_BAR0_BASEADDR           (  C_BASEADDR              ),
   .C_BAR0_HIGHADDR           (  C_HIGHADDR              ),
   .C_S_AXI_ACLK_FREQ_HZ      (  C_S_AXI_ACLK_FREQ_HZ    ),
   .NUM_RW_REGS               (  NUM_RW_REGS             ),
   .NUM_WO_REGS               (  NUM_WO_REGS             ),
   .NUM_RO_REGS               (  NUM_RO_REGS             )
)
axi_lite_regs
(
   .s_axi_aclk                (  s_axi_aclk              ),
   .s_axi_aresetn             (  s_axi_aresetn | ~sw_rst ),
   .s_axi_awaddr              (  s_axi_awaddr            ),
   .s_axi_awvalid             (  s_axi_awvalid           ),
   .s_axi_wdata               (  s_axi_wdata             ),
   .s_axi_wstrb               (  s_axi_wstrb             ),
   .s_axi_wvalid              (  s_axi_wvalid            ),
   .s_axi_bready              (  s_axi_bready            ),
   .s_axi_araddr              (  s_axi_araddr            ),
   .s_axi_arvalid             (  s_axi_arvalid           ),
   .s_axi_rready              (  s_axi_rready            ),
   .s_axi_arready             (  s_axi_arready           ),
   .s_axi_rdata               (  s_axi_rdata             ),
   .s_axi_rresp               (  s_axi_rresp             ),
   .s_axi_rvalid              (  s_axi_rvalid            ),
   .s_axi_wready              (  s_axi_wready            ),
   .s_axi_bresp               (  s_axi_bresp             ),
   .s_axi_bvalid              (  s_axi_bvalid            ),
   .s_axi_awready             (  s_axi_awready           ),

   .rw_regs                   (  rw_regs                 ),
   .rw_defaults               (  {NUM_RW_REGS*C_S_AXI_DATA_WIDTH{1'b0}}), 
   .wo_regs                   (),
   .wo_defaults               (0),
   .ro_regs                   () 
);

// -- Register assignments
assign sw_rst           = rw_regs[(C_S_AXI_DATA_WIDTH*0)+1-1:(C_S_AXI_DATA_WIDTH*0)]; //0x0000

assign q0_start_replay  = rw_regs[(C_S_AXI_DATA_WIDTH*1)+1-1:(C_S_AXI_DATA_WIDTH*1)]; //0x0004
assign q1_start_replay  = rw_regs[(C_S_AXI_DATA_WIDTH*2)+1-1:(C_S_AXI_DATA_WIDTH*2)]; //0x0008
assign q2_start_replay  = rw_regs[(C_S_AXI_DATA_WIDTH*3)+1-1:(C_S_AXI_DATA_WIDTH*3)]; //0x000c
assign q3_start_replay  = rw_regs[(C_S_AXI_DATA_WIDTH*4)+1-1:(C_S_AXI_DATA_WIDTH*4)]; //0x0010

assign q0_replay_count  = rw_regs[(C_S_AXI_DATA_WIDTH*5)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*5)]; //0x0014
assign q1_replay_count  = rw_regs[(C_S_AXI_DATA_WIDTH*6)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*6)]; //0x0018
assign q2_replay_count  = rw_regs[(C_S_AXI_DATA_WIDTH*7)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*7)]; //0x001c
assign q3_replay_count  = rw_regs[(C_S_AXI_DATA_WIDTH*8)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*8)]; //0x0020 

assign q0_addr_low      = rw_regs[(C_S_AXI_DATA_WIDTH*9)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*9)]; //0x0024 
assign q0_addr_high     = rw_regs[(C_S_AXI_DATA_WIDTH*10)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*10)]; //0x0028 
assign q1_addr_low      = rw_regs[(C_S_AXI_DATA_WIDTH*11)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*11)]; //0x002c 
assign q1_addr_high     = rw_regs[(C_S_AXI_DATA_WIDTH*12)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*12)]; //0x0030 
assign q2_addr_low      = rw_regs[(C_S_AXI_DATA_WIDTH*13)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*13)]; //0x0034 
assign q2_addr_high     = rw_regs[(C_S_AXI_DATA_WIDTH*14)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*14)]; //0x0038 
assign q3_addr_low      = rw_regs[(C_S_AXI_DATA_WIDTH*15)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*15)]; //0x003c 
assign q3_addr_high     = rw_regs[(C_S_AXI_DATA_WIDTH*16)+C_S_AXI_DATA_WIDTH-1:(C_S_AXI_DATA_WIDTH*16)]; //0x0040 

assign q0_enable        = rw_regs[(C_S_AXI_DATA_WIDTH*17)+1-1:(C_S_AXI_DATA_WIDTH*17)]; //0x0044
assign q1_enable        = rw_regs[(C_S_AXI_DATA_WIDTH*18)+1-1:(C_S_AXI_DATA_WIDTH*18)]; //0x0048
assign q2_enable        = rw_regs[(C_S_AXI_DATA_WIDTH*19)+1-1:(C_S_AXI_DATA_WIDTH*19)]; //0x004c
assign q3_enable        = rw_regs[(C_S_AXI_DATA_WIDTH*20)+1-1:(C_S_AXI_DATA_WIDTH*20)]; //0x0050

assign q0_wr_done       = rw_regs[(C_S_AXI_DATA_WIDTH*21)+1-1:(C_S_AXI_DATA_WIDTH*21)]; //0x0054
assign q1_wr_done       = rw_regs[(C_S_AXI_DATA_WIDTH*22)+1-1:(C_S_AXI_DATA_WIDTH*22)]; //0x0058
assign q2_wr_done       = rw_regs[(C_S_AXI_DATA_WIDTH*23)+1-1:(C_S_AXI_DATA_WIDTH*23)]; //0x005c
assign q3_wr_done       = rw_regs[(C_S_AXI_DATA_WIDTH*24)+1-1:(C_S_AXI_DATA_WIDTH*24)]; //0x0060

// 0x0 : default, 0x1: path 0, 0x2: path 1, 0x4: path 2, 0x8: path 3.
assign conf_path        = rw_regs[(C_S_AXI_DATA_WIDTH*25)+32-1:(C_S_AXI_DATA_WIDTH*25)]; //0x0064

endmodule
