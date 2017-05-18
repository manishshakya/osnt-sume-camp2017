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

`timescale 1ps/1ps

module osnt_sume_qdrC
#(
   parameter   C_S_AXI_DATA_WIDTH      = 32,          
   parameter   C_S_AXI_ADDR_WIDTH      = 32,          
   parameter   C_BASEADDR              = 32'hFFFFFFFF,
   parameter   C_HIGHADDR              = 32'h00000000,

   parameter   C_M_AXIS_TDATA_WIDTH    = 256,
   parameter   C_M_AXIS_TUSER_WIDTH    = 128,
   parameter   C_S_AXIS_TDATA_WIDTH    = 256,
   parameter   C_S_AXIS_TUSER_WIDTH    = 128 
)
(
   // Differential system clocks
   input                                                 sys_clk_p,
   input                                                 sys_clk_n,
   input                                                 sys_rst,
   //Memory Interface
   input                                                 qdriip_cq_p,
   input                                                 qdriip_cq_n,
   input          [35:0]                                 qdriip_q,
   inout                                                 qdriip_k_p,
   inout                                                 qdriip_k_n,
   output         [35:0]                                 qdriip_d,
   output         [18:0]                                 qdriip_sa,
   output                                                qdriip_w_n,
   output                                                qdriip_r_n,
   output         [3:0]                                  qdriip_bw_n,
   output                                                qdriip_dll_off_n,

   output                                                clk,
   output                                                resetn,

   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   output         [C_M_AXIS_TDATA_WIDTH-1:0]             m_axis_tdata,
   output         [((C_M_AXIS_TDATA_WIDTH/8))-1:0]       m_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m_axis_tuser,
   output                                                m_axis_tvalid,
   input                                                 m_axis_tready,
   output                                                m_axis_tlast,

   input          [C_S_AXIS_TDATA_WIDTH-1:0]             s_axis_tdata,
   input          [((C_S_AXIS_TDATA_WIDTH/8))-1:0]       s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast,

   input                                                 sw_rst,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             replay_count,
   input                                                 start_replay,
   input                                                 wr_done,

   // Slave AXI Ports
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             S_AXI_AWADDR,
   input                                                 S_AXI_AWVALID,
   input          [C_S_AXI_DATA_WIDTH-1 : 0]             S_AXI_WDATA,
   input          [C_S_AXI_DATA_WIDTH/8-1 : 0]           S_AXI_WSTRB,
   input                                                 S_AXI_WVALID,
   input                                                 S_AXI_BREADY,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             S_AXI_ARADDR,
   input                                                 S_AXI_ARVALID,
   input                                                 S_AXI_RREADY,
   output                                                S_AXI_ARREADY,
   output         [C_S_AXI_DATA_WIDTH-1 : 0]             S_AXI_RDATA,
   output         [1 : 0]                                S_AXI_RRESP,
   output                                                S_AXI_RVALID,
   output                                                S_AXI_WREADY,
   output         [1 :0]                                 S_AXI_BRESP,
   output                                                S_AXI_BVALID,
   output                                                S_AXI_AWREADY
);

function integer log2;
   input integer number;
   begin
      log2=0;
      while(2**log2<number) begin
         log2=log2+1;
      end
   end
endfunction

localparam  MAX_PKT_SIZE      = 2000; //In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_TDATA_WIDTH/8));

// User Interface signals of Channel-0
wire           app_wr_cmd_i;
wire  [18:0]   app_wr_addr_i;
wire  [143:0]  app_wr_data_i;
wire  [15:0]   app_wr_bw_n_i; // default : 1
wire           app_rd_cmd_i;
wire  [18:0]   app_rd_addr_i;
wire           app_rd_valid_o;
wire  [143:0]  app_rd_data_o;
wire           init_calib_complete_o;

wire  mem_wr_en;

wire  rst_clk;
assign resetn = ~rst_clk;

wire                                         Bus2IP_Clk;
wire                                         Bus2IP_Resetn;
wire  [C_S_AXI_ADDR_WIDTH-1:0]               Bus2IP_Addr;
wire  [0:0]                                  Bus2IP_CS;
wire                                         Bus2IP_RNW; // 0: wr, 1: rd
wire  [C_S_AXI_DATA_WIDTH-1:0]               Bus2IP_Data;
wire  [C_S_AXI_DATA_WIDTH/8-1:0]             Bus2IP_BE;
wire  [C_S_AXI_DATA_WIDTH-1:0]               IP2Bus_Data;
wire                                         IP2Bus_RdAck;
wire                                         IP2Bus_WrAck;
wire                                         IP2Bus_Error = 0;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             m_async_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8))-1:0]       m_async_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             m_async_tuser;
wire                                         m_async_tvalid;
wire                                         m_async_tready;
wire                                         m_async_tlast;

wire  [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         m_conv_b2m_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     m_conv_b2m_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             m_conv_b2m_tuser;
wire                                         m_conv_b2m_tvalid;
wire                                         m_conv_b2m_tready;
wire                                         m_conv_b2m_tlast;

wire  [C_S_AXIS_TDATA_WIDTH-1:0]             s_async_tdata;
wire  [((C_S_AXIS_TDATA_WIDTH/8))-1:0]       s_async_tkeep;
wire  [2*C_S_AXIS_TUSER_WIDTH-1:0]           s_async_tuser;
wire                                         s_async_tvalid;
wire                                         s_async_tready;
wire                                         s_async_tlast;

wire                                         conv_m2b_tready;

wire  fifo_empty;
wire  fifo_full;
wire  fifo_tvalid;

wire  [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         fifo_in_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     fifo_in_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_in_tuser;
wire                                         fifo_in_tlast;

wire  [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         fifo_out_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     fifo_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser;
wire                                         fifo_out_tlast;

wire  mem_data_empty;
wire  mem_data_full;
wire  mem_data_rd;
wire  [143:0]     mem_data_out;

qdr_if_controller
#(
   .C_S_AXI_DATA_WIDTH     (  C_S_AXI_DATA_WIDTH      ),
   .C_S_AXI_ADDR_WIDTH     (  C_S_AXI_ADDR_WIDTH      ),
                                                  
   .C_M_AXIS_TDATA_WIDTH   (  C_M_AXIS_TDATA_WIDTH    ),
   .C_M_AXIS_TUSER_WIDTH   (  C_M_AXIS_TUSER_WIDTH    ),
   .C_S_AXIS_TDATA_WIDTH   (  C_S_AXIS_TDATA_WIDTH    ),
   .C_S_AXIS_TUSER_WIDTH   (  C_S_AXIS_TUSER_WIDTH    )
)
qdr_if_controller
(
   .clk                    (  clk                     ),
   .rst_clk                (  rst_clk                 ),
                                                   
   .app_wr_cmd_i           (  app_wr_cmd_i            ),
   .app_wr_addr_i          (  app_wr_addr_i           ),
   .app_wr_data_i          (  app_wr_data_i           ),
   .app_wr_bw_n_i          (  app_wr_bw_n_i           ), // default : 1
   .app_rd_cmd_i           (  app_rd_cmd_i            ),
   .app_rd_addr_i          (  app_rd_addr_i           ),
                                                   
   .app_rd_valid_o         (  app_rd_valid_o          ),
   .app_rd_data_o          (  app_rd_data_o           ),
   .mem_wr_en              (  mem_wr_en               ),
   .init_calib_complete_o  (  init_calib_complete_o   ),
                                                   
   .Bus2IP_Addr            (  Bus2IP_Addr             ),
   .Bus2IP_CS              (  Bus2IP_CS               ),
   .Bus2IP_RNW             (  Bus2IP_RNW              ), // 0: wr, 1: rd
   .Bus2IP_Data            (  Bus2IP_Data             ),
   .Bus2IP_BE              (  Bus2IP_BE               ),
   .IP2Bus_Data            (  IP2Bus_Data             ),
   .IP2Bus_RdAck           (  IP2Bus_RdAck            ),
   .IP2Bus_WrAck           (  IP2Bus_WrAck            ),
                                                   
   .m_conv_b2m_tdata       (  m_conv_b2m_tdata        ),
   .m_conv_b2m_tkeep       (  m_conv_b2m_tkeep        ),
   .m_conv_b2m_tuser       (  m_conv_b2m_tuser        ),
   .m_conv_b2m_tvalid      (  m_conv_b2m_tvalid       ),
   .m_conv_b2m_tready      (  m_conv_b2m_tready       ),
   .m_conv_b2m_tlast       (  m_conv_b2m_tlast        ),
                                                   
   .s_async_tready         (  s_async_tready          ),
                                                   
   .mem_data_empty         (  mem_data_empty          ),
   .mem_data_full          (  mem_data_full           ),
   .mem_data_rd            (  mem_data_rd             ),
   .mem_data_out           (  mem_data_out            ),
                                                   
   .fifo_tvalid            (  fifo_tvalid             ),
                                                   
   .fifo_in_tdata          (  fifo_in_tdata           ),
   .fifo_in_tkeep          (  fifo_in_tkeep           ),
   .fifo_in_tuser          (  fifo_in_tuser           ),
   .fifo_in_tlast          (  fifo_in_tlast           ),
                                                   
   .sw_rst                 (  sw_rst                  ),
   .replay_count           (  replay_count            ),
   .start_replay           (  start_replay            ),
   .wr_done                (  wr_done                 )
);

// -- AXILITE IPIF
sume_axi_ipif #
(
   .C_S_AXI_DATA_WIDTH     (  C_S_AXI_DATA_WIDTH      ),
   .C_S_AXI_ADDR_WIDTH     (  C_S_AXI_ADDR_WIDTH      ),
   .C_BASEADDR             (  C_BASEADDR              ),
   .C_HIGHADDR             (  C_HIGHADDR              )
) sume_axi_ipif
(
   .S_AXI_ACLK             (  clk                     ),
   .S_AXI_ARESETN          (  resetn                  ),
   .S_AXI_AWADDR           (  S_AXI_AWADDR            ),
   .S_AXI_AWVALID          (  S_AXI_AWVALID           ),
   .S_AXI_WDATA            (  S_AXI_WDATA             ),
   .S_AXI_WSTRB            (  S_AXI_WSTRB             ),
   .S_AXI_WVALID           (  S_AXI_WVALID            ),
   .S_AXI_BREADY           (  S_AXI_BREADY            ),
   .S_AXI_ARADDR           (  S_AXI_ARADDR            ),
   .S_AXI_ARVALID          (  S_AXI_ARVALID           ),
   .S_AXI_RREADY           (  S_AXI_RREADY            ),
   .S_AXI_ARREADY          (  S_AXI_ARREADY           ),
   .S_AXI_RDATA            (  S_AXI_RDATA             ),
   .S_AXI_RRESP            (  S_AXI_RRESP             ),
   .S_AXI_RVALID           (  S_AXI_RVALID            ),
   .S_AXI_WREADY           (  S_AXI_WREADY            ),
   .S_AXI_BRESP            (  S_AXI_BRESP             ),
   .S_AXI_BVALID           (  S_AXI_BVALID            ),
   .S_AXI_AWREADY          (  S_AXI_AWREADY           ),
 
   // Controls to the IP/IPIF modules
   .Bus2IP_Clk             (  Bus2IP_Clk              ),
   .Bus2IP_Resetn          (  Bus2IP_Resetn           ),
   .Bus2IP_Addr            (  Bus2IP_Addr             ),
   .Bus2IP_RNW             (  Bus2IP_RNW              ),
   .Bus2IP_BE              (  Bus2IP_BE               ),
   .Bus2IP_CS              (  Bus2IP_CS               ),
   .Bus2IP_Data            (  Bus2IP_Data             ),
   .IP2Bus_Data            (  IP2Bus_Data             ),
   .IP2Bus_WrAck           (  IP2Bus_WrAck            ),
   .IP2Bus_RdAck           (  IP2Bus_RdAck            ),
   .IP2Bus_Error           (  IP2Bus_Error            )
);

qdrC_async_fifo_0
qdrC_async_fifo_b2m_0
(
   .s_axis_aclk            (  axis_aclk               ),
   .s_axis_aresetn         (  axis_aresetn            ),
   .s_axis_tvalid          (  s_axis_tvalid           ),
   .s_axis_tready          (  s_axis_tready           ),
   .s_axis_tdata           (  s_axis_tdata            ),
   .s_axis_tkeep           (  s_axis_tkeep            ),
   .s_axis_tlast           (  s_axis_tlast            ),
   .s_axis_tuser           (  s_axis_tuser            ),
                                             
   .m_axis_aclk            (  clk                     ),
   .m_axis_aresetn         (  resetn                  ),
   .m_axis_tvalid          (  m_async_tvalid          ),
   .m_axis_tready          (  m_async_tready          ),
   .m_axis_tdata           (  m_async_tdata           ),
   .m_axis_tkeep           (  m_async_tkeep           ),
   .m_axis_tlast           (  m_async_tlast           ),
   .m_axis_tuser           (  m_async_tuser           )
);

qdrC_fifo_conv_b2m_0
qdrC_fifo_conv_b2m_0
(
   .aclk                   (  clk                     ),
   .aresetn                (  resetn                  ),

   .s_axis_tvalid          (  m_async_tvalid          ),
   .s_axis_tready          (  m_async_tready          ),
   .s_axis_tdata           (  m_async_tdata           ),
   .s_axis_tkeep           (  m_async_tkeep           ),
   .s_axis_tlast           (  m_async_tlast           ),
   .s_axis_tuser           (  {128'b0, m_async_tuser} ),
                                             
   .m_axis_tvalid          (  m_conv_b2m_tvalid       ),
   .m_axis_tready          (  m_conv_b2m_tready       ),
   .m_axis_tdata           (  m_conv_b2m_tdata        ),
   .m_axis_tkeep           (  m_conv_b2m_tkeep        ),
   .m_axis_tlast           (  m_conv_b2m_tlast        ),
   .m_axis_tuser           (  m_conv_b2m_tuser        )
);

qdrC_async_fifo_0
qdrC_async_fifo_m2b_1
(
   .s_axis_aclk            (  clk                     ),
   .s_axis_aresetn         (  resetn                  ),

   .s_axis_tvalid          (  s_async_tvalid          ),
   .s_axis_tready          (  s_async_tready          ),
   .s_axis_tdata           (  s_async_tdata           ),
   .s_axis_tkeep           (  s_async_tkeep           ),
   .s_axis_tlast           (  s_async_tlast           ),
   .s_axis_tuser           (  s_async_tuser[127:0]    ),
                                             
   .m_axis_aclk            (  axis_aclk               ),
   .m_axis_aresetn         (  axis_aresetn            ),
   .m_axis_tvalid          (  m_axis_tvalid           ),
   .m_axis_tready          (  m_axis_tready           ),
   .m_axis_tdata           (  m_axis_tdata            ),
   .m_axis_tkeep           (  m_axis_tkeep            ),
   .m_axis_tlast           (  m_axis_tlast            ),
   .m_axis_tuser           (  m_axis_tuser            )
);

qdrC_fifo_conv_m2b_0
qdrC_fifo_conv_m2b_0
(
   .aclk                   (  clk                     ),
   .aresetn                (  resetn                  ),

   .s_axis_tvalid          (  ~fifo_empty             ),
   .s_axis_tready          (  conv_m2b_tready         ),
   .s_axis_tdata           (  fifo_out_tdata          ),
   .s_axis_tkeep           (  fifo_out_tkeep          ),
   .s_axis_tlast           (  fifo_out_tlast          ),
   .s_axis_tuser           (  fifo_out_tuser          ),
                                             
   .m_axis_tvalid          (  s_async_tvalid          ),
   .m_axis_tready          (  s_async_tready          ),
   .m_axis_tdata           (  s_async_tdata           ),
   .m_axis_tkeep           (  s_async_tkeep           ),
   .m_axis_tlast           (  s_async_tlast           ),
   .m_axis_tuser           (  s_async_tuser           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+((C_M_AXIS_TDATA_WIDTH/8)/2)+(C_M_AXIS_TDATA_WIDTH/2)  ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                             )
)
mem_fifo
(
   //Outputs
   .dout             (  {fifo_out_tlast, fifo_out_tuser, fifo_out_tkeep, fifo_out_tdata}              ),
   .full             (                                                                                ),
   .nearly_full      (  fifo_full                                                                     ),
   .prog_full        (                                                                                ),
   .empty            (  fifo_empty                                                                    ),
   //Inputs
   .din              (  {fifo_in_tlast, fifo_in_tuser, fifo_in_tkeep, fifo_in_tdata}                  ),
   .wr_en            (  fifo_tvalid & ~fifo_full                                                      ),
   .rd_en            (  conv_m2b_tready & ~fifo_empty                                                 ),
   .reset            (  rst_clk                                                                       ),
   .clk              (  clk                                                                           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  144                           ),
   .MAX_DEPTH_BITS   (  10                            )
)
mem_store
(
   //Outputs
   .dout             (  mem_data_out                  ),
   .full             (                                ),
   .nearly_full      (  mem_data_full                 ),
   .prog_full        (                                ),
   .empty            (  mem_data_empty                ),
   //Inputs
   .din              (  app_rd_data_o                 ),
   .wr_en            (  app_rd_valid_o & mem_wr_en    ),
   .rd_en            (  mem_data_rd                   ),
   .reset            (  rst_clk                       ),
   .clk              (  clk                           )
);

mig_qdrC
mig_qdrC
(
   // Differential system clocks
   .sys_clk_p              (  sys_clk_p               ),
   .sys_clk_n              (  sys_clk_n               ),
   //Memory Interface
   .qdriip_cq_p            (  qdriip_cq_p             ),
   .qdriip_cq_n            (  qdriip_cq_n             ),
   .qdriip_q               (  qdriip_q                ),
   .qdriip_k_p             (  qdriip_k_p              ),
   .qdriip_k_n             (  qdriip_k_n              ),
   .qdriip_d               (  qdriip_d                ),
   .qdriip_sa              (  qdriip_sa               ),
   .qdriip_w_n             (  qdriip_w_n              ),
   .qdriip_r_n             (  qdriip_r_n              ),
   .qdriip_bw_n            (  qdriip_bw_n             ),
   .qdriip_dll_off_n       (  qdriip_dll_off_n        ),
   // User Interface signals of Channel-0
   .app_wr_cmd0            (  app_wr_cmd_i            ),
   .app_wr_addr0           (  app_wr_addr_i           ),
   .app_wr_data0           (  app_wr_data_i           ),
   .app_wr_bw_n0           (  app_wr_bw_n_i           ),
   .app_rd_cmd0            (  app_rd_cmd_i            ),
   .app_rd_addr0           (  app_rd_addr_i           ),
   .app_rd_valid0          (  app_rd_valid_o          ),
   .app_rd_data0           (  app_rd_data_o           ),
   // User Interface signals of Channel-1. It is useful only for BL2 designs.
   // All inputs of Channel-1 can be grounded for BL4 designs.
   .app_wr_cmd1            (  0),
   .app_wr_addr1           (  0),
   .app_wr_data1           (  0),
   .app_wr_bw_n1           (  0),
   .app_rd_cmd1            (  0),
   .app_rd_addr1           (  0),
   .app_rd_valid1          (),
   .app_rd_data1           (),
   // source 233MHz => 250MHz
   .clk                    (  clk                     ),
   .rst_clk                (  rst_clk                 ),
   .init_calib_complete    (  init_calib_complete_o   ),
   .sys_rst                (  sys_rst                 )
);
  
endmodule
