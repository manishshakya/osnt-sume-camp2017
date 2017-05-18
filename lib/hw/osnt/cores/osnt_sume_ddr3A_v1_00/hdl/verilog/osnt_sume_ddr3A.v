//
// Copyright (c) 2017 University of Cambridge
// Copyright (c) 2017 Jong Hun Han
// All rights reserved
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

module osnt_sume_ddr3A
#(
   parameter   C_S_AXI_DATA_WIDTH      = 32,          
   parameter   C_S_AXI_ADDR_WIDTH      = 32,          
   parameter   C_USE_WSTRB             = 0,
   parameter   C_DPHASE_TIMEOUT        = 0,
   parameter   C_BASEADDR              = 32'hFFFFFFFF,
   parameter   C_HIGHADDR              = 32'h00000000,

   parameter   C_M_AXIS_TDATA_WIDTH    = 256,
   parameter   C_M_AXIS_TUSER_WIDTH    = 128,
   parameter   C_S_AXIS_TDATA_WIDTH    = 256,
   parameter   C_S_AXIS_TUSER_WIDTH    = 128
)
(
   input                                                 sys_clk_i,
   input                                                 sys_rst,
   input                                                 clk_ref_i,

   inout          [63:0]                                 ddr3_dq,
   inout          [7:0]                                  ddr3_dqs_n,
   inout          [7:0]                                  ddr3_dqs_p,

   output         [15:0]                                 ddr3_addr,
   output         [2:0]                                  ddr3_ba,
   output                                                ddr3_ras_n,
   output                                                ddr3_cas_n,
   output                                                ddr3_we_n,
   output                                                ddr3_reset_n,
   output                                                ddr3_ck_p,
   output                                                ddr3_ck_n,
   output                                                ddr3_cke,
   output                                                ddr3_cs_n,
   output         [7:0]                                  ddr3_dm,
   output                                                ddr3_odt,

   output                                                clk,
   output                                                resetn,

   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   output         [C_M_AXIS_TDATA_WIDTH-1:0]             m_axis_tdata,
   output         [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         m_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m_axis_tuser,
   output                                                m_axis_tvalid,
   input                                                 m_axis_tready,
   output                                                m_axis_tlast,

   input          [C_S_AXIS_TDATA_WIDTH-1:0]             s_axis_tdata,
   input          [(C_S_AXIS_TDATA_WIDTH/8)-1:0]         s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast,

   input                                                 sw_rst,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             replay_count,
   input                                                 start_replay,
   input                                                 wr_done,

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

localparam  MAX_PKT_SIZE      = 4000; //In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_TDATA_WIDTH/8));

wire  [29:0]      app_addr_i;
wire  [2:0]       app_cmd_i; // read;001, write;000
wire              app_en_i;
wire  [511:0]     app_wdf_data_i;
wire              app_wdf_end_i;
wire  [63:0]      app_wdf_mask_i;
wire              app_wdf_wren_i;
wire              app_wdf_rdy_o;
wire  [511:0]     app_rd_data_o;
wire              app_rd_data_end_o;
wire              app_rd_data_valid_o;
wire              app_rdy_o;
wire              init_calib_complete_o;

wire              app_ref_req_i;
wire              app_ref_ack_o;

wire              rst_clk;
wire              st_valid;

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

assign resetn = ~rst_clk;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             m_async_tdata;
wire  [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         m_async_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             m_async_tuser;
wire                                         m_async_tvalid;
wire                                         m_async_tready;
wire                                         m_async_tlast;

wire                                         s_async_tready;

wire  fifo_empty;
wire  fifo_full;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             fifo_in_tdata;
wire  [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         fifo_in_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_in_tuser;
wire                                         fifo_in_tlast;
wire  [94:0]                                 fifo_in_meta;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             fifo_out_tdata;
wire  [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         fifo_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser;
wire                                         fifo_out_tlast;
wire  [94:0]                                 fifo_out_meta;

ddr_if_controller
#(
   .C_S_AXI_DATA_WIDTH     (  C_S_AXI_DATA_WIDTH      ),
   .C_S_AXI_ADDR_WIDTH     (  C_S_AXI_ADDR_WIDTH      ),
   .C_M_AXIS_TDATA_WIDTH   (  C_M_AXIS_TDATA_WIDTH    ),
   .C_M_AXIS_TUSER_WIDTH   (  C_M_AXIS_TUSER_WIDTH    ),
   .C_S_AXIS_TDATA_WIDTH   (  C_S_AXIS_TDATA_WIDTH    ),
   .C_S_AXIS_TUSER_WIDTH   (  C_S_AXIS_TUSER_WIDTH    )
)
ddr_if_controller
(
   .clk                    (  clk                     ),
   .rst_clk                (  rst_clk                 ),
                                                    
   .axis_aclk              (  axis_aclk               ),
   .axis_aresetn           (  axis_aresetn            ),
                                                    
   .m_async_tdata          (  m_async_tdata           ),
   .m_async_tkeep          (  m_async_tkeep           ),
   .m_async_tuser          (  m_async_tuser           ),
   .m_async_tvalid         (  m_async_tvalid          ),
   .m_async_tready         (  m_async_tready          ),
   .m_async_tlast          (  m_async_tlast           ),
                                                    
   .s_async_tready         (  s_async_tready          ),

   .sw_rst                 (  sw_rst                  ),
   .replay_count           (  replay_count            ),
   .start_replay           (  start_replay            ),
   .wr_done                (  wr_done                 ),
                                                    
   .app_addr_i             (  app_addr_i              ),
   .app_cmd_i              (  app_cmd_i               ), // read;001, write;000
   .app_en_i               (  app_en_i                ),
   .app_wdf_data_i         (  app_wdf_data_i          ),
   .app_wdf_end_i          (  app_wdf_end_i           ),
   .app_wdf_mask_i         (  app_wdf_mask_i          ),
   .app_wdf_wren_i         (  app_wdf_wren_i          ),
                                                    
   .app_wdf_rdy_o          (  app_wdf_rdy_o           ),
   .app_rd_data_o          (  app_rd_data_o           ),
   .app_rd_data_end_o      (  app_rd_data_end_o       ),
   .app_rd_data_valid_o    (  app_rd_data_valid_o     ),
   .app_rdy_o              (  app_rdy_o               ),
   .init_calib_complete_o  (  init_calib_complete_o   ),

   .app_ref_req_i          (  app_ref_req_i           ),
   .app_ref_ack_o          (  app_ref_ack_o           ),
                                                    
   .Bus2IP_Addr            (  Bus2IP_Addr             ),
   .Bus2IP_CS              (  Bus2IP_CS               ),
   .Bus2IP_RNW             (  Bus2IP_RNW              ), // 0: wr, 1: rd
   .Bus2IP_Data            (  Bus2IP_Data             ),
   .Bus2IP_BE              (  Bus2IP_BE               ),
                                                    
   .IP2Bus_Data            (  IP2Bus_Data             ),
   .IP2Bus_RdAck           (  IP2Bus_RdAck            ),
   .IP2Bus_WrAck           (  IP2Bus_WrAck            ),

   .st_valid               (  st_valid                )
);


// -- AXILITE IPIF
sume_axi_ipif #
(
   .C_S_AXI_DATA_WIDTH     (  C_S_AXI_DATA_WIDTH      ),
   .C_S_AXI_ADDR_WIDTH     (  C_S_AXI_ADDR_WIDTH      ),
   .C_BASEADDR             (  C_BASEADDR              ),
   .C_HIGHADDR             (  C_HIGHADDR              )
)
sume_axi_ipif
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

ddr3A_async_fifo_0
ddr3A_async_fifo_b2m_0
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

ddr3A_async_fifo_0
ddr3A_async_fifo_m2b_1
(
   .s_axis_aclk            (  clk                     ),
   .s_axis_aresetn         (  resetn                  ),

   .s_axis_tvalid          (  ~fifo_empty             ),
   .s_axis_tready          (  s_async_tready          ),
   .s_axis_tdata           (  fifo_out_tdata          ),
   .s_axis_tkeep           (  fifo_out_tkeep          ),
   .s_axis_tlast           (  fifo_out_tlast          ),
   .s_axis_tuser           (  fifo_out_tuser          ),
                                             
   .m_axis_aclk            (  axis_aclk               ),
   .m_axis_aresetn         (  axis_aresetn            ),
   .m_axis_tvalid          (  m_axis_tvalid           ),
   .m_axis_tready          (  m_axis_tready           ),
   .m_axis_tdata           (  m_axis_tdata            ),
   .m_axis_tkeep           (  m_axis_tkeep            ),
   .m_axis_tlast           (  m_axis_tlast            ),
   .m_axis_tuser           (  m_axis_tuser            )
);

assign fifo_in_tdata = app_rd_data_o[0+:256];
assign fifo_in_tkeep = app_rd_data_o[256+:32];
assign fifo_in_tuser = app_rd_data_o[288+:128];
assign fifo_in_tlast = app_rd_data_o[416+:1];

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_M_AXIS_TDATA_WIDTH/8)+C_M_AXIS_TDATA_WIDTH       ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                          )
)
mem_fifo
(
   //Outputs
   .dout             (  {fifo_out_tlast, fifo_out_tuser, fifo_out_tkeep, fifo_out_tdata}           ),
   .full             (                                                                             ),
   .nearly_full      (  fifo_full                                                                  ),
   .prog_full        (                                                                             ),
   .empty            (  fifo_empty                                                                 ),
   //Inputs
   .din              (  {fifo_in_tlast, fifo_in_tuser, fifo_in_tkeep, fifo_in_tdata}               ),
   .wr_en            (  app_rd_data_valid_o & ~fifo_full & ~Bus2IP_CS & st_valid                   ),
   .rd_en            (  s_async_tready & ~fifo_empty                                               ),
   .reset            (  rst_clk                                                                    ),
   .clk              (  clk                                                                        )
);

mig_ddr3A
mig_ddr3A
(
   // Inouts
   .ddr3_dq                (  ddr3_dq                 ),
   .ddr3_dqs_n             (  ddr3_dqs_n              ),
   .ddr3_dqs_p             (  ddr3_dqs_p              ),
   // Outputs
   .ddr3_addr              (  ddr3_addr               ),
   .ddr3_ba                (  ddr3_ba                 ),
   .ddr3_ras_n             (  ddr3_ras_n              ),
   .ddr3_cas_n             (  ddr3_cas_n              ),
   .ddr3_we_n              (  ddr3_we_n               ),
   .ddr3_reset_n           (  ddr3_reset_n            ),
   .ddr3_ck_p              (  ddr3_ck_p               ),
   .ddr3_ck_n              (  ddr3_ck_n               ),
   .ddr3_cke               (  ddr3_cke                ),
   .ddr3_cs_n              (  ddr3_cs_n               ),
   .ddr3_dm                (  ddr3_dm                 ),
   .ddr3_odt               (  ddr3_odt                ),
   // Inputs
   // Single-ended system clock
   .sys_clk_i              (  sys_clk_i               ),
   .clk_ref_i              (  clk_ref_i               ),
   // user interface signals
   .app_addr               (  app_addr_i              ),
   .app_cmd                (  app_cmd_i               ),
   .app_en                 (  app_en_i                ),
   .app_wdf_data           (  app_wdf_data_i          ),
   .app_wdf_end            (  app_wdf_end_i           ),
   .app_wdf_mask           (  app_wdf_mask_i          ),
   .app_wdf_wren           (  app_wdf_wren_i          ),
   .app_wdf_rdy            (  app_wdf_rdy_o           ),
   .app_rd_data            (  app_rd_data_o           ),
   .app_rd_data_end        (  app_rd_data_end_o       ),
   .app_rd_data_valid      (  app_rd_data_valid_o     ),
   .app_rdy                (  app_rdy_o               ),
   .app_sr_req             (  0), //0
   .app_ref_req            (  0), //app_ref_req_i           ), //for refresh
   .app_zq_req             (  0), //for cal
   .app_sr_active          (  ), 
   .app_ref_ack            (  app_ref_ack_o           ),
   .app_zq_ack             (  ),
   .ui_clk                 (  clk                     ),
   .ui_clk_sync_rst        (  rst_clk                 ),
   .init_calib_complete    (  init_calib_complete_o   ),
   // The 12 MSB bits of the temperature sensor transfer
   // function need to be connected to this port. This port
   // will be synchronized w.r.t. to fabric clock internally.
   .device_temp            (  ),
   .sys_rst                (  sys_rst                 )
  );
  
endmodule
