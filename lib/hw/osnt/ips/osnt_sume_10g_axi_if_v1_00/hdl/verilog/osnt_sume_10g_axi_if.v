//
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

`timescale 1ns/1ps

module osnt_sume_10g_axi_if
#(
   parameter C_S_AXI_DATA_WIDTH  = 32,          
   parameter C_S_AXI_ADDR_WIDTH  = 32,          
   parameter C_USE_WSTRB         = 0,
   parameter C_DPHASE_TIMEOUT    = 0,
   parameter C_BASEADDR          = 32'hFFFFFFFF,
   parameter C_HIGHADDR          = 32'h00000000
)
(
   // Slave AXI Ports
   input                                           S_AXI_ACLK,
   input                                           S_AXI_ARESETN,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]       S_AXI_AWADDR,
   input                                           S_AXI_AWVALID,
   input          [C_S_AXI_DATA_WIDTH-1 : 0]       S_AXI_WDATA,
   input          [C_S_AXI_DATA_WIDTH/8-1 : 0]     S_AXI_WSTRB,
   input                                           S_AXI_WVALID,
   input                                           S_AXI_BREADY,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]       S_AXI_ARADDR,
   input                                           S_AXI_ARVALID,
   input                                           S_AXI_RREADY,
   output                                          S_AXI_ARREADY,
   output         [C_S_AXI_DATA_WIDTH-1 : 0]       S_AXI_RDATA,
   output         [1 : 0]                          S_AXI_RRESP,
   output                                          S_AXI_RVALID,
   output                                          S_AXI_WREADY,
   output         [1 :0]                           S_AXI_BRESP,
   output                                          S_AXI_BVALID,
   output                                          S_AXI_AWREADY,

   output                                          clear,

   output         [79:0]                           mac_rx_config_0,
   output         [79:0]                           mac_tx_config_0,
   output         [535:0]                          pcspma_config_0,

   input          [1:0]                            mac_status_0,
   input          [7:0]                            pcspma_status_0,

   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_pkt_count_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_pkt_count_0,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_ts_pos_0,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         tx_ts_pos_0,

   output         [79:0]                           mac_rx_config_1,
   output         [79:0]                           mac_tx_config_1,
   output         [535:0]                          pcspma_config_1,

   input          [1:0]                            mac_status_1,
   input          [7:0]                            pcspma_status_1,

   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_pkt_count_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_pkt_count_1,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_ts_pos_1,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         tx_ts_pos_1,

   output         [79:0]                           mac_rx_config_2,
   output         [79:0]                           mac_tx_config_2,
   output         [535:0]                          pcspma_config_2,

   input          [1:0]                            mac_status_2,
   input          [7:0]                            pcspma_status_2,

   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_pkt_count_2,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_pkt_count_2,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_ts_pos_2,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         tx_ts_pos_2,

   output         [79:0]                           mac_rx_config_3,
   output         [79:0]                           mac_tx_config_3,
   output         [535:0]                          pcspma_config_3,

   input          [1:0]                            mac_status_3,
   input          [7:0]                            pcspma_status_3,

   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_pkt_count_3,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_pkt_count_3,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_ts_pos_3,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         tx_ts_pos_3,

   output                                          clear_addr,

   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         cfg_ts_0,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_addr_rd_0,
   output                                          rx_rden_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_0,
   
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         cfg_ts_1,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_addr_rd_1,
   output                                          rx_rden_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_1,
   
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         cfg_ts_2,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_addr_rd_2,
   output                                          rx_rden_2,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_2,
   
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         cfg_ts_3,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]         rx_addr_rd_3,
   output                                          rx_rden_3,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_3,

   output         [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_rden_0,
   input          [1:0]                            rx_rd_ready_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_0_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_0_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_0_2,
   
   output         [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_rden_1,
   input          [1:0]                            rx_rd_ready_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_1_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_1_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_1_2,
   
   output         [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_rden_2,
   input          [1:0]                            rx_rd_ready_2,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_2_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_2_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_2_2,

   output         [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_rden_3,
   input          [1:0]                            rx_rd_ready_3,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_3_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_3_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         rx_rd_data_3_2,

   output         [C_S_AXI_DATA_WIDTH-1:0]         tx_rden_0,
   input          [1:0]                            tx_rd_ready_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_0_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_0_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_0_2,
   
   output         [C_S_AXI_DATA_WIDTH-1:0]         tx_rden_1,
   input          [1:0]                            tx_rd_ready_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_1_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_1_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_1_2,
   
   output         [C_S_AXI_DATA_WIDTH-1:0]         tx_rden_2,
   input          [1:0]                            tx_rd_ready_2,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_2_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_2_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_2_2,

   output         [C_S_AXI_DATA_WIDTH-1:0]         tx_rden_3,
   input          [1:0]                            tx_rd_ready_3,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_3_0,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_3_1,
   input          [C_S_AXI_DATA_WIDTH-1:0]         tx_rd_data_3_2
);

wire                                            Bus2IP_Clk;
wire                                            Bus2IP_Resetn;
wire     [C_S_AXI_ADDR_WIDTH-1 : 0]             Bus2IP_Addr;
wire     [0:0]                                  Bus2IP_CS;
wire                                            Bus2IP_RNW;
wire     [C_S_AXI_DATA_WIDTH-1 : 0]             Bus2IP_Data;
wire     [C_S_AXI_DATA_WIDTH/8-1 : 0]           Bus2IP_BE;
reg      [C_S_AXI_DATA_WIDTH-1 : 0]             IP2Bus_Data;
reg                                             IP2Bus_RdAck;
reg                                             IP2Bus_WrAck;
wire                                            IP2Bus_Error = 0;


reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_rx_config_0;
reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_tx_config_0;
reg   [(17*C_S_AXI_DATA_WIDTH)-1:0]    reg_pcspma_config_0;

reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_rx_config_1;
reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_tx_config_1;
reg   [(17*C_S_AXI_DATA_WIDTH)-1:0]    reg_pcspma_config_1;

reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_rx_config_2;
reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_tx_config_2;
reg   [(17*C_S_AXI_DATA_WIDTH)-1:0]    reg_pcspma_config_2;

reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_rx_config_3;
reg   [(3*C_S_AXI_DATA_WIDTH)-1:0]     reg_mac_tx_config_3;
reg   [(17*C_S_AXI_DATA_WIDTH)-1:0]    reg_pcspma_config_3;

wire  wren = Bus2IP_CS & ~Bus2IP_RNW;
wire  rden = Bus2IP_CS &  Bus2IP_RNW;

assign mac_rx_config_0 = reg_mac_rx_config_0[79:0];
assign mac_tx_config_0 = reg_mac_tx_config_0[79:0];
assign pcspma_config_0 = reg_pcspma_config_0[535:0];

assign mac_rx_config_1 = reg_mac_rx_config_1[79:0];
assign mac_tx_config_1 = reg_mac_tx_config_1[79:0];
assign pcspma_config_1 = reg_pcspma_config_1[535:0];

assign mac_rx_config_2 = reg_mac_rx_config_2[79:0];
assign mac_tx_config_2 = reg_mac_tx_config_2[79:0];
assign pcspma_config_2 = reg_pcspma_config_2[535:0];

assign mac_rx_config_3 = reg_mac_rx_config_3[79:0];
assign mac_tx_config_3 = reg_mac_tx_config_3[79:0];
assign pcspma_config_3 = reg_pcspma_config_3[535:0];

reg   [3:0] count;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      count          <= 0;
      IP2Bus_RdAck   <= 0;
      IP2Bus_WrAck   <= 0;
   end
   else if (wren || rden) begin
      if (count == 5) begin
         count          <= count + 1;
         IP2Bus_WrAck   <= wren;
         IP2Bus_RdAck   <= rden;
      end
      else if (count == 6) begin
         count          <= count;
         IP2Bus_WrAck   <= 0;
         IP2Bus_RdAck   <= 0;
      end
      else begin
         count          <= count + 1;
         IP2Bus_WrAck   <= 0;
         IP2Bus_RdAck   <= 0;
      end
   end
   else begin
      count          <= 0;
      IP2Bus_RdAck   <= 0;
      IP2Bus_WrAck   <= 0;
   end

reg   r_clear;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN)
      r_clear  <= 0;
   else
      r_clear  <= wren && (Bus2IP_Addr[15:0] == 16'h0000);

assign clear = (wren && (Bus2IP_Addr[15:0] == 16'h0000)) & ~r_clear;

assign clear_addr = (Bus2IP_Addr[15:0] == 16'ha000) && wren;

assign rx_rden_0 = (Bus2IP_Addr[15:0] == 16'ha010) && rden;
assign rx_rden_1 = (Bus2IP_Addr[15:0] == 16'ha020) && rden;
assign rx_rden_2 = (Bus2IP_Addr[15:0] == 16'ha030) && rden;
assign rx_rden_3 = (Bus2IP_Addr[15:0] == 16'ha040) && rden;

assign tx_rden_0 = (Bus2IP_Addr[15:0] == 16'ha050) && wren;
assign tx_rden_1 = (Bus2IP_Addr[15:0] == 16'ha070) && wren;
assign tx_rden_2 = (Bus2IP_Addr[15:0] == 16'ha090) && wren;
assign tx_rden_3 = (Bus2IP_Addr[15:0] == 16'ha0b0) && wren;

assign rx_rd_rden_0 = (Bus2IP_Addr[15:0] == 16'hb050) && wren;
assign rx_rd_rden_1 = (Bus2IP_Addr[15:0] == 16'hb070) && wren;
assign rx_rd_rden_2 = (Bus2IP_Addr[15:0] == 16'hb090) && wren;
assign rx_rd_rden_3 = (Bus2IP_Addr[15:0] == 16'hb0b0) && wren;


reg   [1:0]    r_mac_status_0;
reg   [7:0]    r_pcspma_status_0;
reg   [1:0]    r_mac_status_1;
reg   [7:0]    r_pcspma_status_1;
reg   [1:0]    r_mac_status_2;
reg   [7:0]    r_pcspma_status_2;
reg   [1:0]    r_mac_status_3;
reg   [7:0]    r_pcspma_status_3;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      r_mac_status_0       <= 0;
      r_pcspma_status_0    <= 0;
      r_mac_status_1       <= 0;
      r_pcspma_status_1    <= 0;
      r_mac_status_2       <= 0;
      r_pcspma_status_2    <= 0;
      r_mac_status_3       <= 0;
      r_pcspma_status_3    <= 0;
   end
   else begin
      r_mac_status_0       <= mac_status_0;
      r_pcspma_status_0    <= pcspma_status_0;
      r_mac_status_1       <= mac_status_1;
      r_pcspma_status_1    <= pcspma_status_1;
      r_mac_status_2       <= mac_status_2;
      r_pcspma_status_2    <= pcspma_status_2;
      r_mac_status_3       <= mac_status_3;
      r_pcspma_status_3    <= pcspma_status_3;
   end


always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      reg_mac_rx_config_0  <= 2;
      reg_mac_tx_config_0  <= 2;
      reg_pcspma_config_0  <= 0;
      reg_mac_rx_config_1  <= 2;
      reg_mac_tx_config_1  <= 2;
      reg_pcspma_config_1  <= 0;
      reg_mac_rx_config_2  <= 2;
      reg_mac_tx_config_2  <= 2;
      reg_pcspma_config_2  <= 0;
      reg_mac_rx_config_3  <= 2;
      reg_mac_tx_config_3  <= 2;
      reg_pcspma_config_3  <= 0;
   end
   else if (wren) begin
      case (Bus2IP_Addr[15:0])
         16'h0004 : begin
            reg_mac_rx_config_0     <= 2;
            reg_mac_tx_config_0     <= 2;
            reg_pcspma_config_0     <= 0;
         end
         16'h2004 : begin
            reg_mac_rx_config_1     <= 2;
            reg_mac_tx_config_1     <= 2;
            reg_pcspma_config_1     <= 0;
         end
         16'h4004 : begin
            reg_mac_rx_config_2     <= 2;
            reg_mac_tx_config_2     <= 2;
            reg_pcspma_config_2     <= 0;
         end
         16'h6004 : begin
            reg_mac_rx_config_3     <= 2;
            reg_mac_tx_config_3     <= 2;
            reg_pcspma_config_3     <= 0;
         end
         16'h0010 : reg_mac_rx_config_0[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h0014 : reg_mac_rx_config_0[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h0018 : reg_mac_rx_config_0[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h0020 : reg_mac_tx_config_0[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h0024 : reg_mac_tx_config_0[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h0028 : reg_mac_tx_config_0[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1000 : reg_pcspma_config_0[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h1004 : reg_pcspma_config_0[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h1008 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h100c : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1010 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1014 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1018 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h101c : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1020 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1024 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h1028 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h102c : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h1020 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h1024 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h1028 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h102c : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h1030 : reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h1050 : rx_ts_pos_0   <= Bus2IP_Data;
         16'h1054 : tx_ts_pos_0   <= Bus2IP_Data;

         16'h2010 : reg_mac_rx_config_1[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h2014 : reg_mac_rx_config_1[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h2018 : reg_mac_rx_config_1[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h2020 : reg_mac_tx_config_1[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h2024 : reg_mac_tx_config_1[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h2028 : reg_mac_tx_config_1[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3000 : reg_pcspma_config_1[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h3004 : reg_pcspma_config_1[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h3008 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h300c : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3010 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3014 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3018 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h301c : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3020 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3024 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h3028 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h302c : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h3020 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h3024 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h3028 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h302c : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h3030 : reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h3050 : rx_ts_pos_1   <= Bus2IP_Data;
         16'h3054 : tx_ts_pos_1   <= Bus2IP_Data;

         16'h4010 : reg_mac_rx_config_2[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h4014 : reg_mac_rx_config_2[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h4018 : reg_mac_rx_config_2[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h4020 : reg_mac_tx_config_2[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h4024 : reg_mac_tx_config_2[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h4028 : reg_mac_tx_config_2[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h5000 : reg_pcspma_config_2[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h5004 : reg_pcspma_config_2[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h5008 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h500c : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h5010 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h5014 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h5018 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h501c : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h5020 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h5024 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h502c : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h5020 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h5024 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h5028 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h502c : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h5030 : reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h5050 : rx_ts_pos_2   <= Bus2IP_Data;
         16'h5054 : tx_ts_pos_2   <= Bus2IP_Data;

         16'h6010 : reg_mac_rx_config_3[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h6014 : reg_mac_rx_config_3[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h6018 : reg_mac_rx_config_3[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h6020 : reg_mac_tx_config_3[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h6024 : reg_mac_tx_config_3[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h6028 : reg_mac_tx_config_3[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7000 : reg_pcspma_config_3[0+:C_S_AXI_DATA_WIDTH]                         <= Bus2IP_Data;
         16'h7004 : reg_pcspma_config_3[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH]        <= Bus2IP_Data;
         16'h7008 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h700c : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7010 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7014 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7018 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h701c : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7020 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7024 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH]    <= Bus2IP_Data;
         16'h7028 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h702c : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h7020 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h7024 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h7028 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h702c : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h7030 : reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH]   <= Bus2IP_Data;
         16'h7050 : rx_ts_pos_3   <= Bus2IP_Data;
         16'h7054 : tx_ts_pos_3   <= Bus2IP_Data;

         16'ha010 : rx_addr_rd_0                                                       <= Bus2IP_Data;
         16'ha014 : cfg_ts_0                                                           <= Bus2IP_Data;
         16'ha020 : rx_addr_rd_1                                                       <= Bus2IP_Data;
         16'ha024 : cfg_ts_1                                                           <= Bus2IP_Data;
         16'ha030 : rx_addr_rd_2                                                       <= Bus2IP_Data;
         16'ha034 : cfg_ts_2                                                           <= Bus2IP_Data;
         16'ha040 : rx_addr_rd_3                                                       <= Bus2IP_Data;
         16'ha044 : cfg_ts_3                                                           <= Bus2IP_Data;
      endcase
   end



always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      IP2Bus_Data  <= 0;
   end
   else if (rden) begin
      case (Bus2IP_Addr[15:0])
         16'h0008 : IP2Bus_Data     <= rx_pkt_count_0;
         16'h000c : IP2Bus_Data     <= tx_pkt_count_0;
         16'h0010 : IP2Bus_Data     <= reg_mac_rx_config_0[0+:C_S_AXI_DATA_WIDTH];
         16'h0014 : IP2Bus_Data     <= reg_mac_rx_config_0[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h0018 : IP2Bus_Data     <= reg_mac_rx_config_0[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h0020 : IP2Bus_Data     <= reg_mac_tx_config_0[0+:C_S_AXI_DATA_WIDTH];
         16'h0024 : IP2Bus_Data     <= reg_mac_tx_config_0[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h0028 : IP2Bus_Data     <= reg_mac_tx_config_0[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h1000 : IP2Bus_Data     <= reg_pcspma_config_0[0+:C_S_AXI_DATA_WIDTH];
         16'h1004 : IP2Bus_Data     <= reg_pcspma_config_0[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h1008 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h100c : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH];
         16'h1010 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH];
         16'h1014 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH];
         16'h1018 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH];
         16'h101c : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH];
         16'h1020 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH];
         16'h1024 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH];
         16'h1028 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH];
         16'h102c : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH];
         16'h1020 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH];
         16'h1024 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH];
         16'h1028 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH];
         16'h102c : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH];
         16'h1030 : IP2Bus_Data     <= reg_pcspma_config_0[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH];
         16'h1040 : IP2Bus_Data     <= {8'b0,r_pcspma_status_0[7:0],14'b0,r_mac_status_0[1:0]};
         16'h1050 : IP2Bus_Data     <= rx_ts_pos_0;
         16'h1054 : IP2Bus_Data     <= tx_ts_pos_0;

         16'h2008 : IP2Bus_Data     <= rx_pkt_count_1;
         16'h200c : IP2Bus_Data     <= tx_pkt_count_1;
         16'h2010 : IP2Bus_Data     <= reg_mac_rx_config_1[0+:C_S_AXI_DATA_WIDTH];
         16'h2014 : IP2Bus_Data     <= reg_mac_rx_config_1[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h2018 : IP2Bus_Data     <= reg_mac_rx_config_1[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h2020 : IP2Bus_Data     <= reg_mac_tx_config_1[0+:C_S_AXI_DATA_WIDTH];
         16'h2024 : IP2Bus_Data     <= reg_mac_tx_config_1[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h2028 : IP2Bus_Data     <= reg_mac_tx_config_1[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h3000 : IP2Bus_Data     <= reg_pcspma_config_1[0+:C_S_AXI_DATA_WIDTH];
         16'h3004 : IP2Bus_Data     <= reg_pcspma_config_1[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h3008 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h300c : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH];
         16'h3010 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH];
         16'h3014 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH];
         16'h3018 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH];
         16'h301c : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH];
         16'h3020 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH];
         16'h3024 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH];
         16'h3028 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH];
         16'h302c : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH];
         16'h3020 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH];
         16'h3024 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH];
         16'h3028 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH];
         16'h302c : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH];
         16'h3030 : IP2Bus_Data     <= reg_pcspma_config_1[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH];
         16'h3040 : IP2Bus_Data     <= {8'b0,r_pcspma_status_1[7:0],14'b0,r_mac_status_1[1:0]};
         16'h3050 : IP2Bus_Data     <= rx_ts_pos_1;
         16'h3054 : IP2Bus_Data     <= tx_ts_pos_1;

         16'h4008 : IP2Bus_Data     <= rx_pkt_count_2;
         16'h400c : IP2Bus_Data     <= tx_pkt_count_2;
         16'h4010 : IP2Bus_Data     <= reg_mac_rx_config_2[0+:C_S_AXI_DATA_WIDTH];
         16'h4014 : IP2Bus_Data     <= reg_mac_rx_config_2[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h4018 : IP2Bus_Data     <= reg_mac_rx_config_2[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h4020 : IP2Bus_Data     <= reg_mac_tx_config_2[0+:C_S_AXI_DATA_WIDTH];
         16'h4024 : IP2Bus_Data     <= reg_mac_tx_config_2[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h4028 : IP2Bus_Data     <= reg_mac_tx_config_2[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h5000 : IP2Bus_Data     <= reg_pcspma_config_2[0+:C_S_AXI_DATA_WIDTH];
         16'h5004 : IP2Bus_Data     <= reg_pcspma_config_2[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h5008 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h500c : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH];
         16'h5010 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH];
         16'h5014 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH];
         16'h5018 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH];
         16'h501c : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH];
         16'h5020 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH];
         16'h5024 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH];
         16'h5028 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH];
         16'h502c : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH];
         16'h5020 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH];
         16'h5024 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH];
         16'h5028 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH];
         16'h502c : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH];
         16'h5030 : IP2Bus_Data     <= reg_pcspma_config_2[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH];
         16'h5040 : IP2Bus_Data     <= {8'b0,r_pcspma_status_2[7:0],14'b0,r_mac_status_2[1:0]};
         16'h5050 : IP2Bus_Data     <= rx_ts_pos_2;
         16'h5054 : IP2Bus_Data     <= tx_ts_pos_2;


         16'h6008 : IP2Bus_Data     <= rx_pkt_count_3;
         16'h600c : IP2Bus_Data     <= tx_pkt_count_3;
         16'h6010 : IP2Bus_Data     <= reg_mac_rx_config_3[0+:C_S_AXI_DATA_WIDTH];
         16'h6014 : IP2Bus_Data     <= reg_mac_rx_config_3[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h6018 : IP2Bus_Data     <= reg_mac_rx_config_3[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h6020 : IP2Bus_Data     <= reg_mac_tx_config_3[0+:C_S_AXI_DATA_WIDTH];
         16'h6024 : IP2Bus_Data     <= reg_mac_tx_config_3[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h6028 : IP2Bus_Data     <= reg_mac_tx_config_3[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h7000 : IP2Bus_Data     <= reg_pcspma_config_3[0+:C_S_AXI_DATA_WIDTH];
         16'h7004 : IP2Bus_Data     <= reg_pcspma_config_3[C_S_AXI_DATA_WIDTH+:C_S_AXI_DATA_WIDTH];
         16'h7008 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*2)+:C_S_AXI_DATA_WIDTH];
         16'h700c : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*3)+:C_S_AXI_DATA_WIDTH];
         16'h7010 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*4)+:C_S_AXI_DATA_WIDTH];
         16'h7014 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*5)+:C_S_AXI_DATA_WIDTH];
         16'h7018 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*6)+:C_S_AXI_DATA_WIDTH];
         16'h701c : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*7)+:C_S_AXI_DATA_WIDTH];
         16'h7020 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*8)+:C_S_AXI_DATA_WIDTH];
         16'h7024 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*9)+:C_S_AXI_DATA_WIDTH];
         16'h7028 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*10)+:C_S_AXI_DATA_WIDTH];
         16'h702c : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*11)+:C_S_AXI_DATA_WIDTH];
         16'h7020 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*12)+:C_S_AXI_DATA_WIDTH];
         16'h7024 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*13)+:C_S_AXI_DATA_WIDTH];
         16'h7028 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*14)+:C_S_AXI_DATA_WIDTH];
         16'h702c : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*15)+:C_S_AXI_DATA_WIDTH];
         16'h7030 : IP2Bus_Data     <= reg_pcspma_config_3[(C_S_AXI_DATA_WIDTH*16)+:C_S_AXI_DATA_WIDTH];
         16'h7040 : IP2Bus_Data     <= {8'b0,r_pcspma_status_3[7:0],14'b0,r_mac_status_3[1:0]};
         16'h7050 : IP2Bus_Data     <= rx_ts_pos_3;
         16'h7054 : IP2Bus_Data     <= tx_ts_pos_3;

         16'ha010 : IP2Bus_Data     <= rx_rd_data_0;
         16'ha014 : IP2Bus_Data     <= cfg_ts_0;
         16'ha020 : IP2Bus_Data     <= rx_rd_data_1;
         16'ha024 : IP2Bus_Data     <= cfg_ts_1;
         16'ha030 : IP2Bus_Data     <= rx_rd_data_2;
         16'ha034 : IP2Bus_Data     <= cfg_ts_2;
         16'ha040 : IP2Bus_Data     <= rx_rd_data_3;
         16'ha044 : IP2Bus_Data     <= cfg_ts_3;
         16'ha054 : IP2Bus_Data     <= {30'b0, tx_rd_ready_0};
         16'ha058 : IP2Bus_Data     <= tx_rd_data_0_0;
         16'ha05c : IP2Bus_Data     <= tx_rd_data_0_1;
         16'ha060 : IP2Bus_Data     <= tx_rd_data_0_2;
         16'ha074 : IP2Bus_Data     <= {30'b0, tx_rd_ready_1};
         16'ha078 : IP2Bus_Data     <= tx_rd_data_1_0;
         16'ha07c : IP2Bus_Data     <= tx_rd_data_1_1;
         16'ha080 : IP2Bus_Data     <= tx_rd_data_1_2;
         16'ha094 : IP2Bus_Data     <= {30'b0, tx_rd_ready_2};
         16'ha098 : IP2Bus_Data     <= tx_rd_data_2_0;
         16'ha09c : IP2Bus_Data     <= tx_rd_data_2_1;
         16'ha0a0 : IP2Bus_Data     <= tx_rd_data_2_2;
         16'ha0b4 : IP2Bus_Data     <= {30'b0, tx_rd_ready_3};
         16'ha0b8 : IP2Bus_Data     <= tx_rd_data_3_0;
         16'ha0bc : IP2Bus_Data     <= tx_rd_data_3_1;
         16'ha0c0 : IP2Bus_Data     <= tx_rd_data_3_2;
         16'hb054 : IP2Bus_Data     <= {30'b0, rx_rd_ready_0};
         16'hb058 : IP2Bus_Data     <= rx_rd_data_0_0;
         16'hb05c : IP2Bus_Data     <= rx_rd_data_0_1;
         16'hb060 : IP2Bus_Data     <= rx_rd_data_0_2;
         16'hb074 : IP2Bus_Data     <= {30'b0, rx_rd_ready_1};
         16'hb078 : IP2Bus_Data     <= rx_rd_data_1_0;
         16'hb07c : IP2Bus_Data     <= rx_rd_data_1_1;
         16'hb080 : IP2Bus_Data     <= rx_rd_data_1_2;
         16'hb094 : IP2Bus_Data     <= {30'b0, rx_rd_ready_2};
         16'hb098 : IP2Bus_Data     <= rx_rd_data_2_0;
         16'hb09c : IP2Bus_Data     <= rx_rd_data_2_1;
         16'hb0a0 : IP2Bus_Data     <= rx_rd_data_2_2;
         16'hb0b4 : IP2Bus_Data     <= {30'b0, rx_rd_ready_3};
         16'hb0b8 : IP2Bus_Data     <= rx_rd_data_3_0;
         16'hb0bc : IP2Bus_Data     <= rx_rd_data_3_1;
         16'hb0c0 : IP2Bus_Data     <= rx_rd_data_3_2;
      endcase
   end


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
  
endmodule
