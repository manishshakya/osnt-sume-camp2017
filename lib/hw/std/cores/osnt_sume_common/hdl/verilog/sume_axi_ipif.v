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
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor license
// agreements.  See the NOTICE file distributed with this work for additional
// information regarding copyright ownership.  NetFPGA licenses this file to
// you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//

`timescale 1ns/1ps

module sume_axi_ipif
#(
   parameter   C_BASEADDR            = 32'hFFFFFFFF,
   parameter   C_HIGHADDR            = 32'h00000000,
   parameter   C_S_AXI_DATA_WIDTH    = 32,
   parameter   C_S_AXI_ADDR_WIDTH    = 32
)
(
   // AXI Lite ports
   input                                        S_AXI_ACLK,
   input                                        S_AXI_ARESETN,

   input          [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_AWADDR,
   input          [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_WDATA,
   input          [C_S_AXI_DATA_WIDTH/8-1:0]    S_AXI_WSTRB,
   input                                        S_AXI_AWVALID,
   input                                        S_AXI_WVALID,
   output   reg                                 S_AXI_WREADY,
   output   reg                                 S_AXI_AWREADY,
   input                                        S_AXI_BREADY,
   output   reg                                 S_AXI_BVALID,

   input          [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_ARADDR,
   input                                        S_AXI_ARVALID,
   input                                        S_AXI_RREADY,
   output   reg                                 S_AXI_ARREADY,
   output   reg                                 S_AXI_RVALID,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_RDATA,
   output         [1:0]                         S_AXI_RRESP,
   output         [1:0]                         S_AXI_BRESP,

   output                                       Bus2IP_Clk,
   output                                       Bus2IP_Resetn,
   output   reg   [C_S_AXI_ADDR_WIDTH-1:0]      Bus2IP_Addr,
   output   reg                                 Bus2IP_CS,
   output   reg                                 Bus2IP_RNW,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]      Bus2IP_Data,
   output   reg   [C_S_AXI_DATA_WIDTH/8-1:0]    Bus2IP_BE,
   input          [C_S_AXI_DATA_WIDTH-1:0]      IP2Bus_Data,
   input                                        IP2Bus_RdAck,
   input                                        IP2Bus_WrAck,
   input                                        IP2Bus_Error
);

assign S_AXI_RRESP = 0;
assign S_AXI_BRESP = 0;

assign Bus2IP_Clk = S_AXI_ACLK;
assign Bus2IP_Resetn = S_AXI_ARESETN;

`define     ST_IDLE     0
`define     ST_WR_START 1
`define     ST_WR_ACK   2
`define     ST_WR_DONE  3
`define     ST_RD_START 4
`define     ST_RD_ACK   5
`define     ST_RD_DONE  6

reg   [3:0]    st_current, st_next;

reg   r_wrack_delay, r_rdack_delay;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      r_wrack_delay  <= 0;
      r_rdack_delay <= 0;
   end
   else begin
      r_wrack_delay  <= IP2Bus_WrAck;
      r_rdack_delay <= IP2Bus_RdAck;
   end

wire  w_wrack = IP2Bus_WrAck & ~r_wrack_delay;
wire  w_rdack = IP2Bus_RdAck & ~r_rdack_delay;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN)
      S_AXI_RDATA <= 0;
   else if (w_rdack)
      S_AXI_RDATA <= IP2Bus_Data;


reg r_axi_wren;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN)
      r_axi_wren  <= 0;
   else
      r_axi_wren  <= S_AXI_AWVALID & S_AXI_WVALID;

wire  w_axi_wren = (S_AXI_AWVALID & S_AXI_WVALID) & r_axi_wren;

reg r_axi_rden;
always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN)
      r_axi_rden  <= 0;
   else
      r_axi_rden  <= S_AXI_ARVALID;

wire  w_axi_rden = S_AXI_ARVALID & r_axi_rden;

reg   [C_S_AXI_ADDR_WIDTH-1:0]      axi_addr;
reg   [C_S_AXI_DATA_WIDTH-1:0]      axi_data;
reg   [(C_S_AXI_DATA_WIDTH/8)-1:0]  axi_be;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      axi_addr <= 0;
      axi_data <= 0;
      axi_be   <= 0;
   end
   else if (w_axi_wren) begin
      axi_addr <= S_AXI_AWADDR;
      axi_data <= S_AXI_WDATA;
      axi_be   <= S_AXI_WSTRB;
   end
   else if (w_axi_rden) begin
      axi_addr <= S_AXI_ARADDR;
      axi_data <= 0;
      axi_be   <= 0;
   end

always @(*) begin
   Bus2IP_Addr    = 0; 
   Bus2IP_CS      = 0; 
   Bus2IP_RNW     = 0; 
   Bus2IP_Data    = 0; 
   Bus2IP_BE      = 0; 
   S_AXI_AWREADY  = 0;
   S_AXI_WREADY   = 0;
   S_AXI_BVALID   = 0;
   S_AXI_ARREADY  = 0;
   S_AXI_RVALID   = 0;
   st_next        = 0;
   case (st_current)
      `ST_IDLE : begin
         Bus2IP_Addr    = 0; 
         Bus2IP_CS      = 0; 
         Bus2IP_RNW     = 0; 
         Bus2IP_Data    = 0; 
         Bus2IP_BE      = 0; 
         S_AXI_AWREADY  = 0;
         S_AXI_WREADY   = 0;
         S_AXI_BVALID   = 0;
         S_AXI_ARREADY  = 0;
         S_AXI_RVALID   = 0;
         st_next        = (w_axi_wren) ? `ST_WR_START :
                          (w_axi_rden) ? `ST_RD_START : `ST_IDLE;
      end
      `ST_WR_START : begin
         Bus2IP_Addr    = axi_addr; 
         Bus2IP_CS      = 1; 
         Bus2IP_RNW     = 0; 
         Bus2IP_Data    = axi_data; 
         Bus2IP_BE      = axi_be; 
         S_AXI_AWREADY  = (w_wrack) ? 1 : 0;
         S_AXI_WREADY   = (w_wrack) ? 1 : 0;
         S_AXI_BVALID   = 0;
         S_AXI_ARREADY  = 0;
         S_AXI_RVALID   = 0;
         st_next        = (w_wrack) ? `ST_WR_ACK : `ST_WR_START;
      end
      `ST_WR_ACK : begin
         Bus2IP_Addr    = 0; 
         Bus2IP_CS      = 0; 
         Bus2IP_RNW     = 0; 
         Bus2IP_Data    = 0; 
         Bus2IP_BE      = 0; 
         S_AXI_AWREADY  = 0;
         S_AXI_WREADY   = 0;
         S_AXI_BVALID   = (S_AXI_AWVALID & S_AXI_WVALID) ? 0 : (S_AXI_BREADY) ? 1 : 0;
         S_AXI_ARREADY  = 0;
         S_AXI_RVALID   = 0;
         st_next        = (S_AXI_AWVALID & S_AXI_WVALID) ? `ST_WR_ACK : (S_AXI_BREADY) ? `ST_IDLE : `ST_WR_DONE;
      end
      `ST_WR_DONE : begin
         Bus2IP_Addr    = 0; 
         Bus2IP_CS      = 0; 
         Bus2IP_RNW     = 0; 
         Bus2IP_Data    = 0; 
         Bus2IP_BE      = 0; 
         S_AXI_AWREADY  = 0;
         S_AXI_WREADY   = 0;
         S_AXI_BVALID   = 1;
         S_AXI_ARREADY  = 0;
         S_AXI_RVALID   = 0;
         st_next        = (S_AXI_BREADY) ? `ST_IDLE : `ST_WR_DONE;
      end
      `ST_RD_START : begin
         Bus2IP_Addr    = axi_addr; 
         Bus2IP_CS      = 1; 
         Bus2IP_RNW     = 1; 
         Bus2IP_Data    = 0; 
         Bus2IP_BE      = 0; 
         S_AXI_AWREADY  = 0;
         S_AXI_WREADY   = 0;
         S_AXI_BVALID   = 0;
         S_AXI_ARREADY  = (w_rdack) ? 1 : 0;
         S_AXI_RVALID   = 0;
         st_next        = (w_rdack) ? `ST_RD_ACK : `ST_RD_START;
      end
      `ST_RD_ACK : begin
         Bus2IP_Addr    = 0; 
         Bus2IP_CS      = 0; 
         Bus2IP_RNW     = 0; 
         Bus2IP_Data    = 0; 
         Bus2IP_BE      = 0; 
         S_AXI_AWREADY  = 0;
         S_AXI_WREADY   = 0;
         S_AXI_BVALID   = 0;
         S_AXI_ARREADY  = 0;
         S_AXI_RVALID   = (S_AXI_ARVALID) ? 0 : (S_AXI_RREADY) ? 1 : 0;
         st_next        = (S_AXI_ARVALID) ? `ST_RD_ACK : (S_AXI_RREADY) ? `ST_IDLE : `ST_RD_DONE;
      end
      `ST_RD_DONE : begin
         Bus2IP_Addr    = 0; 
         Bus2IP_CS      = 0; 
         Bus2IP_RNW     = 0; 
         Bus2IP_Data    = 0; 
         Bus2IP_BE      = 0; 
         S_AXI_AWREADY  = 0;
         S_AXI_WREADY   = 0;
         S_AXI_BVALID   = 0;
         S_AXI_ARREADY  = 0;
         S_AXI_RVALID   = 1;
         st_next        = (S_AXI_RREADY) ? `ST_IDLE : `ST_RD_DONE;
      end
   endcase
end

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN)
      st_current  <= 0;
   else
      st_current  <= st_next;
         


endmodule
