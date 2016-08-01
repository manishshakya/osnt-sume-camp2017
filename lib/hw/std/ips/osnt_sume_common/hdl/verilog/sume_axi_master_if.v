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

module sume_axi_master_if
#(
   parameter   C_M_AXI_DATA_WIDTH   = 32,
   parameter   C_M_AXI_ADDR_WIDTH   = 32
)
(
   // AXI Lite ports
   input                                        M_AXI_ACLK,
   input                                        M_AXI_ARESETN,

   output   reg   [C_M_AXI_ADDR_WIDTH-1:0]      M_AXI_AWADDR,
   output   reg   [C_M_AXI_DATA_WIDTH-1:0]      M_AXI_WDATA,
   output   reg   [C_M_AXI_DATA_WIDTH/8-1:0]    M_AXI_WSTRB,
   output   reg                                 M_AXI_AWVALID,
   input                                        M_AXI_AWREADY,
   output   reg                                 M_AXI_WVALID,
   input                                        M_AXI_WREADY,
   input                                        M_AXI_BVALID,
   output   reg                                 M_AXI_BREADY,
   input          [1:0]                         M_AXI_BRESP,

   output   reg   [C_M_AXI_ADDR_WIDTH-1:0]      M_AXI_ARADDR,
   output   reg                                 M_AXI_ARVALID,
   input                                        M_AXI_ARREADY,
   input          [C_M_AXI_DATA_WIDTH-1:0]      M_AXI_RDATA,
   input                                        M_AXI_RVALID,
   output   reg                                 M_AXI_RREADY,
   input          [1:0]                         M_AXI_RRESP,

   //Output for master axi lite
   input                                        IP2Bus_MstRd_Req,
   input                                        IP2Bus_MstWr_Req,
   input          [C_M_AXI_ADDR_WIDTH-1:0]      IP2Bus_Mst_Addr,
   input          [(C_M_AXI_DATA_WIDTH/8)-1:0]  IP2Bus_Mst_BE,
   output   reg                                 Bus2IP_Mst_CmdAck,
   output   reg                                 Bus2IP_Mst_Cmplt,
   output   reg   [C_M_AXI_DATA_WIDTH-1:0]      Bus2IP_MstRd_d,
   input          [C_M_AXI_DATA_WIDTH-1:0]      IP2Bus_MstWr_d
);

`define     ST_IDLE           0
`define     ST_WR_START       1
`define     ST_WR_ACK         2
`define     ST_WR_ADDR_ACK    3
`define     ST_WR_DATA_ACK    4
`define     ST_WR_DONE        5
`define     ST_WR_COMP        6
`define     ST_RD_START       7
`define     ST_RD_ACK         8
`define     ST_RD_DONE        9
`define     ST_RD_COMP        10

reg   [3:0]    st_current, st_next;

reg   r_wrreq_delay, r_rdreq_delay;
always @(posedge M_AXI_ACLK)
   if (~M_AXI_ARESETN) begin
      r_wrreq_delay  <= 0;
      r_rdreq_delay  <= 0;
   end
   else begin
      r_wrreq_delay  <= IP2Bus_MstWr_Req;
      r_rdreq_delay  <= IP2Bus_MstRd_Req;
   end

wire  w_wrreq = IP2Bus_MstWr_Req & ~r_wrreq_delay;
wire  w_rdreq = IP2Bus_MstRd_Req & ~r_rdreq_delay;

always @(posedge M_AXI_ACLK)
   if (~M_AXI_ARESETN)
      Bus2IP_MstRd_d <= 0;
   else if (M_AXI_RVALID)
      Bus2IP_MstRd_d <= M_AXI_RDATA;


reg   [C_M_AXI_ADDR_WIDTH-1:0]      axi_addr;
reg   [C_M_AXI_DATA_WIDTH-1:0]      axi_data;
reg   [(C_M_AXI_DATA_WIDTH/8)-1:0]  axi_be;

always @(posedge M_AXI_ACLK)
   if (~M_AXI_ARESETN) begin
      axi_addr <= 0;
      axi_data <= 0;
      axi_be   <= 0;
   end
   else if (w_wrreq) begin
      axi_addr <= IP2Bus_Mst_Addr;
      axi_data <= IP2Bus_MstWr_d;
      axi_be   <= IP2Bus_Mst_BE;
   end
   else if (w_rdreq) begin
      axi_addr <= IP2Bus_Mst_Addr;
      axi_data <= 0;
      axi_be   <= 0;
   end

always @(*) begin
   Bus2IP_Mst_CmdAck = 0; 
   Bus2IP_Mst_Cmplt  = 0; 
   M_AXI_AWADDR      = 0; 
   M_AXI_AWVALID     = 0;
   M_AXI_WDATA       = 0;
   M_AXI_WSTRB       = 0;
   M_AXI_WVALID      = 0;
   M_AXI_BREADY      = 1;
   M_AXI_ARADDR      = 0;
   M_AXI_ARVALID     = 0;
   M_AXI_RREADY      = 1;
   st_next           = 0;
   case (st_current)
      `ST_IDLE : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_AWADDR      = 0;
         M_AXI_AWVALID     = 0;
         M_AXI_WDATA       = 0;
         M_AXI_WSTRB       = 0;
         M_AXI_WVALID      = 0;
         M_AXI_ARADDR      = 0;
         M_AXI_ARVALID     = 0;
         st_next           = (w_wrreq) ? `ST_WR_START :
                             (w_rdreq) ? `ST_RD_START : `ST_IDLE;
      end
      `ST_WR_START : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_AWADDR      = axi_addr; 
         M_AXI_AWVALID     = 1;
         M_AXI_WDATA       = axi_data;
         M_AXI_WSTRB       = axi_be;
         M_AXI_WVALID      = 1;
         st_next           = (M_AXI_AWREADY & M_AXI_WREADY) ? `ST_WR_ACK :
                             (M_AXI_AWREADY               ) ? `ST_WR_ADDR_ACK :
                             (M_AXI_WREADY                ) ? `ST_WR_DATA_ACK :  `ST_WR_START;
      end
      `ST_WR_ADDR_ACK : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_AWADDR      = 0; 
         M_AXI_AWVALID     = 0;
         M_AXI_WDATA       = axi_data;
         M_AXI_WSTRB       = axi_be;
         M_AXI_WVALID      = 1;
         st_next           = (M_AXI_WREADY) ? `ST_WR_ACK : `ST_WR_ADDR_ACK;
      end
      `ST_WR_DATA_ACK : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_AWADDR      = axi_addr; 
         M_AXI_AWVALID     = 1;
         M_AXI_WDATA       = 0;
         M_AXI_WSTRB       = 0;
         M_AXI_WVALID      = 0;
         st_next           = (M_AXI_AWREADY) ? `ST_WR_ACK : `ST_WR_DATA_ACK;
      end
      `ST_WR_ACK : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_AWADDR      = 0; 
         M_AXI_AWVALID     = 0;
         M_AXI_WDATA       = 0;
         M_AXI_WSTRB       = 0;
         M_AXI_WVALID      = 0;
         st_next           = (M_AXI_BVALID) ? `ST_WR_DONE : `ST_WR_ACK;
      end
      `ST_WR_DONE : begin
         Bus2IP_Mst_CmdAck = 1; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_AWADDR      = 0; 
         M_AXI_AWVALID     = 0;
         M_AXI_WDATA       = 0;
         M_AXI_WSTRB       = 0;
         M_AXI_WVALID      = 0;
         st_next           = `ST_WR_COMP;
      end
      `ST_WR_COMP : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 1; 
         M_AXI_AWADDR      = 0; 
         M_AXI_AWVALID     = 0;
         M_AXI_WDATA       = 0;
         M_AXI_WSTRB       = 0;
         M_AXI_WVALID      = 0;
         st_next           = `ST_IDLE;
      end
      `ST_RD_START : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_ARADDR      = axi_addr;
         M_AXI_ARVALID     = 1;
         st_next           = (M_AXI_ARREADY) ? `ST_RD_ACK : `ST_RD_START;
      end
      `ST_RD_ACK : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_ARADDR      = 0;
         M_AXI_ARVALID     = 0;
         st_next           = (M_AXI_RVALID) ? `ST_RD_DONE : `ST_RD_ACK;
      end
      `ST_RD_DONE : begin
         Bus2IP_Mst_CmdAck = 1; 
         Bus2IP_Mst_Cmplt  = 0; 
         M_AXI_ARADDR      = 0;
         M_AXI_ARVALID     = 0;
         st_next           = `ST_RD_COMP;
      end
      `ST_RD_COMP : begin
         Bus2IP_Mst_CmdAck = 0; 
         Bus2IP_Mst_Cmplt  = 1; 
         M_AXI_ARADDR      = 0;
         M_AXI_ARVALID     = 0;
         st_next           = `ST_IDLE;
      end
   endcase
end

always @(posedge M_AXI_ACLK)
   if (~M_AXI_ARESETN)
      st_current  <= 0;
   else
      st_current  <= st_next;
         

endmodule
