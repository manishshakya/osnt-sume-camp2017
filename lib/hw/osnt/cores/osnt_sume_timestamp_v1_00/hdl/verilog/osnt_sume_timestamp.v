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
 *  File:
 *        osnt_timestamp.v
 *
 *  Author:
 *        Gianni Antichi
 *
 *  Description:
 */

module osnt_sume_timestamp
#(
   parameter C_FAMILY              = "virtex7",
   parameter C_S_AXI_DATA_WIDTH    = 32,          
   parameter C_S_AXI_ADDR_WIDTH    = 32,          
   parameter C_USE_WSTRB           = 0,
   parameter C_DPHASE_TIMEOUT      = 0,
   parameter C_BASEADDR            = 32'hFFFFFFFF,
   parameter C_HIGHADDR            = 32'h00000000,
   parameter C_S_AXI_ACLK_FREQ_HZ  = 100,
   parameter TIMESTAMP_WIDTH	  = 64
)
(
   // Slave AXI Ports
   input                                     S_AXI_ACLK,
   input                                     S_AXI_ARESETN,
   input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
   input                                     S_AXI_AWVALID,
   input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
   input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
   input                                     S_AXI_WVALID,
   input                                     S_AXI_BREADY,
   input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
   input                                     S_AXI_ARVALID,
   input                                     S_AXI_RREADY,
   output                                    S_AXI_ARREADY,
   output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
   output     [1 : 0]                        S_AXI_RRESP,
   output                                    S_AXI_RVALID,
   output                                    S_AXI_WREADY,
   output     [1 :0]                         S_AXI_BRESP,
   output                                    S_AXI_BVALID,
   output                                    S_AXI_AWREADY,
 
   // PPS input
   input					                        PPS_RX,

   // Programmable TS pulse
   output                                    ts_pulse_out,
   input                                     ts_pulse_in,

   output   [C_S_AXI_DATA_WIDTH-1:0]         rx_ts_pos,
   output   [C_S_AXI_DATA_WIDTH-1:0]         tx_ts_pos,
 
   // Timestamp
   output     [TIMESTAMP_WIDTH-1 : 0]        STAMP_COUNTER,
   output reg   [TIMESTAMP_WIDTH-1 : 0]      STAMP_COUNTER_156
);

  // -- Internal Parameters
  
  localparam NUM_RW_REGS       = 7;
  localparam NUM_RO_REGS       = 4;

  // -- Signals

  wire                                            Bus2IP_Clk;
  wire                                            Bus2IP_Resetn;
  wire     [C_S_AXI_ADDR_WIDTH-1 : 0]             Bus2IP_Addr;
  wire     [0:0]                                  Bus2IP_CS;
  wire                                            Bus2IP_RNW;
  wire     [C_S_AXI_DATA_WIDTH-1 : 0]             Bus2IP_Data;
  wire     [C_S_AXI_DATA_WIDTH/8-1 : 0]           Bus2IP_BE;
  wire     [C_S_AXI_DATA_WIDTH-1 : 0]             IP2Bus_Data;
  wire                                            IP2Bus_RdAck;
  wire                                            IP2Bus_WrAck;
  wire                                            IP2Bus_Error;
  
  wire     [NUM_RW_REGS*C_S_AXI_DATA_WIDTH-1 : 0] rw_regs;
  wire 	   [NUM_RW_REGS*C_S_AXI_DATA_WIDTH-1 : 0] rw_defaults;
  wire     [NUM_RO_REGS*C_S_AXI_DATA_WIDTH-1 : 0] ro_regs;

  wire						  gps_connected;
  wire	   [1:0]				  restart_time;
  wire     [TIMESTAMP_WIDTH-1:0]                  ntp_timestamp;

  wire     [C_S_AXI_DATA_WIDTH-1:0]               conf_trig;

wire  w_ts_pulse_in;

reg   ts_trigger;

//34359738368 x 6.26ns = 214748364800ns = 214.7483648sec = 3.579139413min
assign ts_pulse = STAMP_COUNTER[35];

  
  sume_axi_ipif#
  (
    .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
    .C_BASEADDR    (C_BASEADDR),
    .C_HIGHADDR    (C_HIGHADDR)
  ) sume_axi_ipif 
  (
    .S_AXI_ACLK          ( S_AXI_ACLK     ),
    .S_AXI_ARESETN       ( S_AXI_ARESETN  ),
    .S_AXI_AWADDR        ( S_AXI_AWADDR   ),
    .S_AXI_AWVALID       ( S_AXI_AWVALID  ),
    .S_AXI_WDATA         ( S_AXI_WDATA    ),
    .S_AXI_WSTRB         ( S_AXI_WSTRB    ),
    .S_AXI_WVALID        ( S_AXI_WVALID   ),
    .S_AXI_BREADY        ( S_AXI_BREADY   ),
    .S_AXI_ARADDR        ( S_AXI_ARADDR   ),
    .S_AXI_ARVALID       ( S_AXI_ARVALID  ),
    .S_AXI_RREADY        ( S_AXI_RREADY   ),
    .S_AXI_ARREADY       ( S_AXI_ARREADY  ),
    .S_AXI_RDATA         ( S_AXI_RDATA    ),
    .S_AXI_RRESP         ( S_AXI_RRESP    ),
    .S_AXI_RVALID        ( S_AXI_RVALID   ),
    .S_AXI_WREADY        ( S_AXI_WREADY   ),
    .S_AXI_BRESP         ( S_AXI_BRESP    ),
    .S_AXI_BVALID        ( S_AXI_BVALID   ),
    .S_AXI_AWREADY       ( S_AXI_AWREADY  ),
	
	// Controls to the IP/IPIF modules
    .Bus2IP_Clk          ( Bus2IP_Clk     ),
    .Bus2IP_Resetn       ( Bus2IP_Resetn  ),
    .Bus2IP_Addr         ( Bus2IP_Addr    ),
    .Bus2IP_RNW          ( Bus2IP_RNW     ),
    .Bus2IP_BE           ( Bus2IP_BE      ),
    .Bus2IP_CS           ( Bus2IP_CS      ),
    .Bus2IP_Data         ( Bus2IP_Data    ),
    .IP2Bus_Data         ( IP2Bus_Data    ),
    .IP2Bus_WrAck        ( IP2Bus_WrAck   ),
    .IP2Bus_RdAck        ( IP2Bus_RdAck   ),
    .IP2Bus_Error        ( IP2Bus_Error   )
  );

  // -- IPIF REGS
  ipif_regs #
  (
    .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),          
    .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),   
    .NUM_RW_REGS        (NUM_RW_REGS),
    .NUM_RO_REGS	(NUM_RO_REGS)
  ) ipif_regs_inst
  (   
    .Bus2IP_Clk     ( Bus2IP_Clk     ),
    .Bus2IP_Resetn  ( Bus2IP_Resetn  ), 
    .Bus2IP_Addr    ( Bus2IP_Addr    ),
    .Bus2IP_CS      ( Bus2IP_CS[0]   ),
    .Bus2IP_RNW     ( Bus2IP_RNW     ),
    .Bus2IP_Data    ( Bus2IP_Data    ),
    .Bus2IP_BE      ( Bus2IP_BE      ),
    .IP2Bus_Data    ( IP2Bus_Data    ),
    .IP2Bus_RdAck   ( IP2Bus_RdAck   ),
    .IP2Bus_WrAck   ( IP2Bus_WrAck   ),
    .IP2Bus_Error   ( IP2Bus_Error   ),
	
    .rw_regs        ( rw_regs ),
    .rw_defaults    ( rw_defaults ),
    .ro_regs        ( ro_regs )

  );

reg   r_gps_0, r_gps_1;
reg   [C_S_AXI_DATA_WIDTH-1:0]   gps_counter;
  
// -- Register assignments
assign rw_defaults       = 0;
assign restart_time      = rw_regs[1+C_S_AXI_DATA_WIDTH*0:C_S_AXI_DATA_WIDTH*0]; //0x00
assign correction_mode   = rw_regs[C_S_AXI_DATA_WIDTH]; //0x04
assign ntp_timestamp     = rw_regs[(TIMESTAMP_WIDTH+C_S_AXI_DATA_WIDTH*2)-1:C_S_AXI_DATA_WIDTH*2]; //0x08-0x0c

assign rx_ts_pos         = rw_regs[(C_S_AXI_DATA_WIDTH*5)-1:C_S_AXI_DATA_WIDTH*4]; //0x10
assign tx_ts_pos         = rw_regs[(C_S_AXI_DATA_WIDTH*6)-1:C_S_AXI_DATA_WIDTH*5]; //0x14

assign conf_trig         = rw_regs[(C_S_AXI_DATA_WIDTH*7)-1:C_S_AXI_DATA_WIDTH*6]; //0x18

//28,24,20,1c 
assign ro_regs           = {STAMP_COUNTER, gps_counter[31:0], 30'b0, r_gps_1, gps_connected};


assign ts_pulse_out = (conf_trig == 1) ? 1 :
                      (conf_trig == 2) ? ts_trigger :
                      (conf_trig == 3) ? PPS_RX : 0;


always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      r_gps_0  <= 0;
      r_gps_1  <= 0;
   end
   else begin
      r_gps_0  <= PPS_RX;
      r_gps_1  <= r_gps_0;
   end

wire  w_gps_signal = r_gps_0 & ~r_gps_1;


reg   r_ts_pulse_in_0, r_ts_pulse_in_1;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      r_ts_pulse_in_0  <= 0;
      r_ts_pulse_in_1  <= 0;
   end
   else begin
      r_ts_pulse_in_0  <= ts_pulse_in;
      r_ts_pulse_in_1  <= r_ts_pulse_in_0;
   end

assign w_ts_pulse_in = r_ts_pulse_in_0 & ~r_ts_pulse_in_1;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      gps_counter    <= 0;
   end
   else if (restart_time[1]) begin
      gps_counter    <= 0;
   end
   else if (w_gps_signal) begin
      gps_counter    <= gps_counter + 1;
   end

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      ts_trigger  <= 0;
   end
   else begin
      ts_trigger  <= STAMP_COUNTER[32];
   end

  
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      STAMP_COUNTER_156 <= 0;
   end
   else begin
      STAMP_COUNTER_156 <= STAMP_COUNTER_156 + 1;
   end

  // -- Stamp Counter Module
  stamp_counter #
  (
    .TIMESTAMP_WIDTH  (TIMESTAMP_WIDTH)
   ) stamp_counter
  (
    // Global Ports
    .axi_aclk      (S_AXI_ACLK),
    .axi_resetn    (S_AXI_ARESETN),
    .pps_rx	   (PPS_RX),
    .correction_mode(correction_mode),

    .restart_time(restart_time),
    .ntp_timestamp(ntp_timestamp),
    .stamp_counter(STAMP_COUNTER),

    .gps_connected(gps_connected)
  );
  
endmodule
