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
/*******************************************************************************
 *  File:
 *        osnt_inter_packet_delay.v
 *
 *  Author:
 *        Muhammad Shahbaz
 *
 *  Description:
 */

`timescale 1ns/1ps

module osnt_sume_inter_packet_delay
#(
  parameter C_S_AXI_DATA_WIDTH    = 32,
  parameter C_S_AXI_ADDR_WIDTH    = 32,
  parameter C_BASEADDR            = 32'hFFFFFFFF,
  parameter C_HIGHADDR            = 32'h00000000,
  parameter C_USE_WSTRB           = 0,
  parameter C_DPHASE_TIMEOUT      = 0,
  parameter C_S_AXI_ACLK_FREQ_HZ  = 100,
  parameter C_M_AXIS_DATA_WIDTH   = 256,
  parameter C_S_AXIS_DATA_WIDTH   = 256,
  parameter C_M_AXIS_TUSER_WIDTH  = 128,
  parameter C_S_AXIS_TUSER_WIDTH  = 128,
   parameter C_TUSER_TIMESTAMP_POS  = 32,
   parameter C_NUM_QUEUES           = 4,
   parameter SIM_ONLY              = 0
)
(
  // Clock and Reset

  // Slave AXI Ports
  input                                           s_axi_aclk,
  input                                           s_axi_aresetn,
  input      [C_S_AXI_ADDR_WIDTH-1:0]             s_axi_awaddr,
  input                                           s_axi_awvalid,
  input      [C_S_AXI_DATA_WIDTH-1:0]             s_axi_wdata,
  input      [C_S_AXI_DATA_WIDTH/8-1:0]           s_axi_wstrb,
  input                                           s_axi_wvalid,
  input                                           s_axi_bready,
  input      [C_S_AXI_ADDR_WIDTH-1:0]             s_axi_araddr,
  input                                           s_axi_arvalid,
  input                                           s_axi_rready,
  output                                          s_axi_arready,
  output     [C_S_AXI_DATA_WIDTH-1:0]             s_axi_rdata,
  output     [1:0]                                s_axi_rresp,
  output                                          s_axi_rvalid,
  output                                          s_axi_wready,
  output     [1:0]                                s_axi_bresp,
  output                                          s_axi_bvalid,
  output                                          s_axi_awready,

  // Master Stream Ports (interface to data path)
   input                                           axis_aclk,
   input                                           axis_aresetn,
   
  output     [C_M_AXIS_DATA_WIDTH-1:0]            m0_axis_tdata,
  output     [((C_M_AXIS_DATA_WIDTH/8))-1:0]      m0_axis_tkeep,
  output     [C_M_AXIS_TUSER_WIDTH-1:0]           m0_axis_tuser,
  output                                          m0_axis_tvalid,
  input                                           m0_axis_tready,
  output                                          m0_axis_tlast,

  output     [C_M_AXIS_DATA_WIDTH-1:0]            m1_axis_tdata,
  output     [((C_M_AXIS_DATA_WIDTH/8))-1:0]      m1_axis_tkeep,
  output     [C_M_AXIS_TUSER_WIDTH-1:0]           m1_axis_tuser,
  output                                          m1_axis_tvalid,
  input                                           m1_axis_tready,
  output                                          m1_axis_tlast,

  output     [C_M_AXIS_DATA_WIDTH-1:0]            m2_axis_tdata,
  output     [((C_M_AXIS_DATA_WIDTH/8))-1:0]      m2_axis_tkeep,
  output     [C_M_AXIS_TUSER_WIDTH-1:0]           m2_axis_tuser,
  output                                          m2_axis_tvalid,
  input                                           m2_axis_tready,
  output                                          m2_axis_tlast,

  output     [C_M_AXIS_DATA_WIDTH-1:0]            m3_axis_tdata,
  output     [((C_M_AXIS_DATA_WIDTH/8))-1:0]      m3_axis_tkeep,
  output     [C_M_AXIS_TUSER_WIDTH-1:0]           m3_axis_tuser,
  output                                          m3_axis_tvalid,
  input                                           m3_axis_tready,
  output                                          m3_axis_tlast,

  output     [C_M_AXIS_DATA_WIDTH-1:0]            m4_axis_tdata,
  output     [((C_M_AXIS_DATA_WIDTH/8))-1:0]      m4_axis_tkeep,
  output     [C_M_AXIS_TUSER_WIDTH-1:0]           m4_axis_tuser,
  output                                          m4_axis_tvalid,
  input                                           m4_axis_tready,
  output                                          m4_axis_tlast,

  // Slave Stream Ports (interface to RX queues)
  input      [C_S_AXIS_DATA_WIDTH-1:0]            s0_axis_tdata,
  input      [((C_S_AXIS_DATA_WIDTH/8))-1:0]      s0_axis_tkeep,
  input      [C_S_AXIS_TUSER_WIDTH-1:0]           s0_axis_tuser,
  input                                           s0_axis_tvalid,
  output                                          s0_axis_tready,
  input                                           s0_axis_tlast,

  input      [C_S_AXIS_DATA_WIDTH-1:0]            s1_axis_tdata,
  input      [((C_S_AXIS_DATA_WIDTH/8))-1:0]      s1_axis_tkeep,
  input      [C_S_AXIS_TUSER_WIDTH-1:0]           s1_axis_tuser,
  input                                           s1_axis_tvalid,
  output                                          s1_axis_tready,
  input                                           s1_axis_tlast,

  input      [C_S_AXIS_DATA_WIDTH-1:0]            s2_axis_tdata,
  input      [((C_S_AXIS_DATA_WIDTH/8))-1:0]      s2_axis_tkeep,
  input      [C_S_AXIS_TUSER_WIDTH-1:0]           s2_axis_tuser,
  input                                           s2_axis_tvalid,
  output                                          s2_axis_tready,
  input                                           s2_axis_tlast,

  input      [C_S_AXIS_DATA_WIDTH-1:0]            s3_axis_tdata,
  input      [((C_S_AXIS_DATA_WIDTH/8))-1:0]      s3_axis_tkeep,
  input      [C_S_AXIS_TUSER_WIDTH-1:0]           s3_axis_tuser,
  input                                           s3_axis_tvalid,
  output                                          s3_axis_tready,
  input                                           s3_axis_tlast,

  input      [C_S_AXIS_DATA_WIDTH-1:0]            s4_axis_tdata,
  input      [((C_S_AXIS_DATA_WIDTH/8))-1:0]      s4_axis_tkeep,
  input      [C_S_AXIS_TUSER_WIDTH-1:0]           s4_axis_tuser,
  input                                           s4_axis_tvalid,
  output                                          s4_axis_tready,
  input                                           s4_axis_tlast
);

  // -- Internal Parameters
  localparam NUM_RW_REGS = 4*C_NUM_QUEUES;
localparam NUM_WO_REGS = 0;
localparam NUM_RO_REGS = 0;

  // -- Signals
	
	genvar																					i;
	
  wire     [NUM_RW_REGS*C_S_AXI_DATA_WIDTH-1:0]   rw_regs;

  wire                                            sw_rst[0:C_NUM_QUEUES-1];
  wire                                            ipd_en[0:C_NUM_QUEUES-1];
  wire                                            use_reg_val[0:C_NUM_QUEUES-1];
  wire     [C_S_AXI_DATA_WIDTH-1:0]               delay_reg_val[0:C_NUM_QUEUES-1];
	

  // -- AXILITE Registers
  axi_lite_regs
  #(
    .C_S_AXI_DATA_WIDTH   (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH   (C_S_AXI_ADDR_WIDTH),
    .C_USE_WSTRB          (C_USE_WSTRB),
    .C_DPHASE_TIMEOUT     (C_DPHASE_TIMEOUT),
    .C_BAR0_BASEADDR      (C_BASEADDR),
    .C_BAR0_HIGHADDR      (C_HIGHADDR),
    .C_S_AXI_ACLK_FREQ_HZ (C_S_AXI_ACLK_FREQ_HZ),
    .NUM_RW_REGS          (NUM_RW_REGS),
    .NUM_WO_REGS          (NUM_WO_REGS),
    .NUM_RO_REGS          (NUM_RO_REGS)
  )
    axi_lite_regs_1bar_inst
  (
    .s_axi_aclk      (s_axi_aclk),
    .s_axi_aresetn   (s_axi_aresetn),
    .s_axi_awaddr    (s_axi_awaddr),
    .s_axi_awvalid   (s_axi_awvalid),
    .s_axi_wdata     (s_axi_wdata),
    .s_axi_wstrb     (s_axi_wstrb),
    .s_axi_wvalid    (s_axi_wvalid),
    .s_axi_bready    (s_axi_bready),
    .s_axi_araddr    (s_axi_araddr),
    .s_axi_arvalid   (s_axi_arvalid),
    .s_axi_rready    (s_axi_rready),
    .s_axi_arready   (s_axi_arready),
    .s_axi_rdata     (s_axi_rdata),
    .s_axi_rresp     (s_axi_rresp),
    .s_axi_rvalid    (s_axi_rvalid),
    .s_axi_wready    (s_axi_wready),
    .s_axi_bresp     (s_axi_bresp),
    .s_axi_bvalid    (s_axi_bvalid),
    .s_axi_awready   (s_axi_awready),

    .rw_regs         (rw_regs),
		.rw_defaults     ((SIM_ONLY==0) ? {NUM_RW_REGS*C_S_AXI_DATA_WIDTH{1'b0}} :
										 {
											 {32'd0},
											 {31'b0, 1'b0},
											 {31'b0, 1'b1},
											 {31'b0, 1'b0},
											  
											 {32'd0},
											 {31'b0, 1'b0},
											 {31'b0, 1'b1},
											 {31'b0, 1'b0},
											  
											 {32'd0},
											 {31'b0, 1'b0},
											 {31'b0, 1'b1},
											 {31'b0, 1'b0},
											  
											 {32'd2000},
											 {31'b0, 1'b1},
											 {31'b0, 1'b1},
											 {31'b0, 1'b0}
										 }
										 ),
		.wo_regs         (),
		.wo_defaults     (0),
		.ro_regs         ()
  );

  // -- Register assignments

	generate 
		for (i=0; i<C_NUM_QUEUES; i=i+1) begin: _regs
  		assign sw_rst[i]        = rw_regs[C_S_AXI_DATA_WIDTH*((i*4)+0)+( 1-1):C_S_AXI_DATA_WIDTH*((i*4)+0)];
  		assign ipd_en[i]        = rw_regs[C_S_AXI_DATA_WIDTH*((i*4)+1)+( 1-1):C_S_AXI_DATA_WIDTH*((i*4)+1)];
  		assign use_reg_val[i]   = rw_regs[C_S_AXI_DATA_WIDTH*((i*4)+2)+( 1-1):C_S_AXI_DATA_WIDTH*((i*4)+2)];
  		assign delay_reg_val[i] = rw_regs[C_S_AXI_DATA_WIDTH*((i*4)+3)+(32-1):C_S_AXI_DATA_WIDTH*((i*4)+3)];
		end
	endgenerate

  // -- Inter Packet Delay
	generate
		if (C_NUM_QUEUES > 0) begin: _ipd_0
  		inter_packet_delay #
  		(
  		  .C_M_AXIS_DATA_WIDTH   ( C_M_AXIS_DATA_WIDTH ),
  		  .C_S_AXIS_DATA_WIDTH   ( C_S_AXIS_DATA_WIDTH ),
  		  .C_M_AXIS_TUSER_WIDTH  ( C_M_AXIS_TUSER_WIDTH ),
  		  .C_S_AXIS_TUSER_WIDTH  ( C_S_AXIS_TUSER_WIDTH ),
  		  .C_S_AXI_DATA_WIDTH    ( C_S_AXI_DATA_WIDTH ),
				.C_TUSER_TIMESTAMP_POS ( C_TUSER_TIMESTAMP_POS )
  		) 
  			_inst
  		(
  		  // Global Ports
  		  .axi_aclk             ( axis_aclk ),
  		  .axi_aresetn          ( axis_aresetn ),
  		
  		  // Master Stream Ports (interface to data path)
  		  .m_axis_tdata         ( m0_axis_tdata ),
  		  .m_axis_tstrb         ( m0_axis_tkeep ),
  		  .m_axis_tuser         ( m0_axis_tuser ),
  		  .m_axis_tvalid        ( m0_axis_tvalid ),
  		  .m_axis_tready        ( m0_axis_tready ),
  		  .m_axis_tlast         ( m0_axis_tlast ),
  		
  		  // Slave Stream Ports (interface to RX queues)
  		  .s_axis_tdata         ( s0_axis_tdata ),
  		  .s_axis_tstrb         ( s0_axis_tkeep ),
  		  .s_axis_tuser         ( s0_axis_tuser ),
  		  .s_axis_tvalid        ( s0_axis_tvalid ),
  		  .s_axis_tready        ( s0_axis_tready ),
  		  .s_axis_tlast         ( s0_axis_tlast ),
  		
  		  .sw_rst               ( sw_rst[0] ),
  		  .ipd_en               ( ipd_en[0] ),
  		  .use_reg_val          ( use_reg_val[0] ),
  		  .delay_reg_val        ( delay_reg_val[0] )
  		);
		end
		
		if (C_NUM_QUEUES > 1) begin: _ipd_1
  		inter_packet_delay #
  		(
  		  .C_M_AXIS_DATA_WIDTH   ( C_M_AXIS_DATA_WIDTH ),
  		  .C_S_AXIS_DATA_WIDTH   ( C_S_AXIS_DATA_WIDTH ),
  		  .C_M_AXIS_TUSER_WIDTH  ( C_M_AXIS_TUSER_WIDTH ),
  		  .C_S_AXIS_TUSER_WIDTH  ( C_S_AXIS_TUSER_WIDTH ),
  		  .C_S_AXI_DATA_WIDTH    ( C_S_AXI_DATA_WIDTH ),
				.C_TUSER_TIMESTAMP_POS ( C_TUSER_TIMESTAMP_POS )
  		) 
  			_inst
  		(
  		  // Global Ports
  		  .axi_aclk             ( axis_aclk ),
  		  .axi_aresetn          ( axis_aresetn ),
  		
  		  // Master Stream Ports (interface to data path)
  		  .m_axis_tdata         ( m1_axis_tdata ),
  		  .m_axis_tstrb         ( m1_axis_tkeep ),
  		  .m_axis_tuser         ( m1_axis_tuser ),
  		  .m_axis_tvalid        ( m1_axis_tvalid ),
  		  .m_axis_tready        ( m1_axis_tready ),
  		  .m_axis_tlast         ( m1_axis_tlast ),
  		
  		  // Slave Stream Ports (interface to RX queues)
  		  .s_axis_tdata         ( s1_axis_tdata ),
  		  .s_axis_tstrb         ( s1_axis_tkeep ),
  		  .s_axis_tuser         ( s1_axis_tuser ),
  		  .s_axis_tvalid        ( s1_axis_tvalid ),
  		  .s_axis_tready        ( s1_axis_tready ),
  		  .s_axis_tlast         ( s1_axis_tlast ),
  		
  		  .sw_rst               ( sw_rst[1] ),
  		  .ipd_en               ( ipd_en[1] ),
  		  .use_reg_val          ( use_reg_val[1] ),
  		  .delay_reg_val        ( delay_reg_val[1] )
  		);
		end
		
		if (C_NUM_QUEUES > 2) begin: _ipd_2
  		inter_packet_delay #
  		(
  		  .C_M_AXIS_DATA_WIDTH   ( C_M_AXIS_DATA_WIDTH ),
  		  .C_S_AXIS_DATA_WIDTH   ( C_S_AXIS_DATA_WIDTH ),
  		  .C_M_AXIS_TUSER_WIDTH  ( C_M_AXIS_TUSER_WIDTH ),
  		  .C_S_AXIS_TUSER_WIDTH  ( C_S_AXIS_TUSER_WIDTH ),
  		  .C_S_AXI_DATA_WIDTH    ( C_S_AXI_DATA_WIDTH ),
				.C_TUSER_TIMESTAMP_POS ( C_TUSER_TIMESTAMP_POS )
  		) 
  			_inst
  		(
  		  // Global Ports
  		  .axi_aclk             ( axis_aclk ),
  		  .axi_aresetn          ( axis_aresetn ),
  		
  		  // Master Stream Ports (interface to data path)
  		  .m_axis_tdata         ( m2_axis_tdata ),
  		  .m_axis_tstrb         ( m2_axis_tkeep ),
  		  .m_axis_tuser         ( m2_axis_tuser ),
  		  .m_axis_tvalid        ( m2_axis_tvalid ),
  		  .m_axis_tready        ( m2_axis_tready ),
  		  .m_axis_tlast         ( m2_axis_tlast ),
  		
  		  // Slave Stream Ports (interface to RX queues)
  		  .s_axis_tdata         ( s2_axis_tdata ),
  		  .s_axis_tstrb         ( s2_axis_tkeep ),
  		  .s_axis_tuser         ( s2_axis_tuser ),
  		  .s_axis_tvalid        ( s2_axis_tvalid ),
  		  .s_axis_tready        ( s2_axis_tready ),
  		  .s_axis_tlast         ( s2_axis_tlast ),
  		
  		  .sw_rst               ( sw_rst[2] ),
  		  .ipd_en               ( ipd_en[2] ),
  		  .use_reg_val          ( use_reg_val[2] ),
  		  .delay_reg_val        ( delay_reg_val[2] )
  		);
		end
		
		if (C_NUM_QUEUES > 3) begin: _ipd_3
  		inter_packet_delay #
  		(
  		  .C_M_AXIS_DATA_WIDTH   ( C_M_AXIS_DATA_WIDTH ),
  		  .C_S_AXIS_DATA_WIDTH   ( C_S_AXIS_DATA_WIDTH ),
  		  .C_M_AXIS_TUSER_WIDTH  ( C_M_AXIS_TUSER_WIDTH ),
  		  .C_S_AXIS_TUSER_WIDTH  ( C_S_AXIS_TUSER_WIDTH ),
  		  .C_S_AXI_DATA_WIDTH    ( C_S_AXI_DATA_WIDTH ),
				.C_TUSER_TIMESTAMP_POS ( C_TUSER_TIMESTAMP_POS )
  		) 
  			_inst
  		(
  		  // Global Ports
  		  .axi_aclk             ( axis_aclk ),
  		  .axi_aresetn          ( axis_aresetn ),
  		
  		  // Master Stream Ports (interface to data path)
  		  .m_axis_tdata         ( m3_axis_tdata ),
  		  .m_axis_tstrb         ( m3_axis_tkeep ),
  		  .m_axis_tuser         ( m3_axis_tuser ),
  		  .m_axis_tvalid        ( m3_axis_tvalid ),
  		  .m_axis_tready        ( m3_axis_tready ),
  		  .m_axis_tlast         ( m3_axis_tlast ),
  		
  		  // Slave Stream Ports (interface to RX queues)
  		  .s_axis_tdata         ( s3_axis_tdata ),
  		  .s_axis_tstrb         ( s3_axis_tkeep ),
  		  .s_axis_tuser         ( s3_axis_tuser ),
  		  .s_axis_tvalid        ( s3_axis_tvalid ),
  		  .s_axis_tready        ( s3_axis_tready ),
  		  .s_axis_tlast         ( s3_axis_tlast ),
  		
  		  .sw_rst               ( sw_rst[3] ),
  		  .ipd_en               ( ipd_en[3] ),
  		  .use_reg_val          ( use_reg_val[3] ),
  		  .delay_reg_val        ( delay_reg_val[3] )
  		);
		end
		
		if (C_NUM_QUEUES > 4) begin: _ipd_4
  		inter_packet_delay #
  		(
  		  .C_M_AXIS_DATA_WIDTH   ( C_M_AXIS_DATA_WIDTH ),
  		  .C_S_AXIS_DATA_WIDTH   ( C_S_AXIS_DATA_WIDTH ),
  		  .C_M_AXIS_TUSER_WIDTH  ( C_M_AXIS_TUSER_WIDTH ),
  		  .C_S_AXIS_TUSER_WIDTH  ( C_S_AXIS_TUSER_WIDTH ),
  		  .C_S_AXI_DATA_WIDTH    ( C_S_AXI_DATA_WIDTH ),
				.C_TUSER_TIMESTAMP_POS ( C_TUSER_TIMESTAMP_POS )
  		) 
  			_inst
  		(
  		  // Global Ports
  		  .axi_aclk             ( axis_aclk ),
  		  .axi_aresetn          ( axis_aresetn ),
  		
  		  // Master Stream Ports (interface to data path)
  		  .m_axis_tdata         ( m4_axis_tdata ),
  		  .m_axis_tstrb         ( m4_axis_tkeep ),
  		  .m_axis_tuser         ( m4_axis_tuser ),
  		  .m_axis_tvalid        ( m4_axis_tvalid ),
  		  .m_axis_tready        ( m4_axis_tready ),
  		  .m_axis_tlast         ( m4_axis_tlast ),
  		
  		  // Slave Stream Ports (interface to RX queues)
  		  .s_axis_tdata         ( s4_axis_tdata ),
  		  .s_axis_tstrb         ( s4_axis_tkeep ),
  		  .s_axis_tuser         ( s4_axis_tuser ),
  		  .s_axis_tvalid        ( s4_axis_tvalid ),
  		  .s_axis_tready        ( s4_axis_tready ),
  		  .s_axis_tlast         ( s4_axis_tlast ),
  		
  		  .sw_rst               ( sw_rst[4] ),
  		  .ipd_en               ( ipd_en[4] ),
  		  .use_reg_val          ( use_reg_val[4] ),
  		  .delay_reg_val        ( delay_reg_val[4] )
  		);
		end
	endgenerate
endmodule
