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

module osnt_sume_axi_if
#(
   parameter   C_BASEADDR            = 32'hFFFFFFFF,
   parameter   C_HIGHADDR            = 32'h00000000,
   parameter   C_S_AXI_DATA_WIDTH    = 32,
   parameter   C_S_AXI_ADDR_WIDTH    = 32
)
(
    // AXI Lite ports
    input                                       S_AXI_ACLK,
    input                                       S_AXI_ARESETN,

    input         [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_AWADDR,
    input         [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_WDATA,
    input         [C_S_AXI_DATA_WIDTH/8-1:0]    S_AXI_WSTRB,
    input                                       S_AXI_AWVALID,
    input                                       S_AXI_WVALID,
    output                                      S_AXI_WREADY,
    output                                      S_AXI_AWREADY,
    input                                       S_AXI_BREADY,
    output                                      S_AXI_BVALID,

    input         [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_ARADDR,
    input                                       S_AXI_ARVALID,
    input                                       S_AXI_RREADY,
    output                                      S_AXI_ARREADY,
    output                                      S_AXI_RVALID,
    output        [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_RDATA,
    output        [1:0]                         S_AXI_RRESP,
    output        [1:0]                         S_AXI_BRESP
);

wire  [C_S_AXI_ADDR_WIDTH-1:0]      Bus2IP_Addr;
wire                                Bus2IP_CS;
wire                                Bus2IP_RNW;
wire  [C_S_AXI_DATA_WIDTH-1:0]      Bus2IP_Data;
wire  [C_S_AXI_DATA_WIDTH/8-1:0]    Bus2IP_BE;
wire  [C_S_AXI_DATA_WIDTH-1:0]      IP2Bus_Data;
wire                                IP2Bus_RdAck;
wire                                IP2Bus_WrAck;

`define  ST_IDLE     0
`define  WR_RDY      1
`define  WR_DONE     2
`define  RD_RDY      3
`define  RD_DONE     4

reg   [2:0]    current_state, next_state;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN)
      current_state  <= 0;
   else
      current_state  <= next_state;

always @(*) begin
   next_state     = `ST_IDLE;
   case (current_state)
      `ST_IDLE : begin
         next_state     = (Bus2IP_CS & ~Bus2IP_RNW) ? `WR_RDY :
                          (Bus2IP_CS &  Bus2IP_RNW) ? `RD_RDY : `ST_IDLE;
      end
      `WR_RDY : begin
         next_state     = (IP2Bus_WrAck) ? `WR_DONE : `WR_RDY;
      end         
      `WR_DONE : begin
         next_state     = (Bus2IP_CS) ? `WR_DONE : `ST_IDLE;
      end
      `RD_RDY : begin
         next_state     = (IP2Bus_RdAck) ? `RD_DONE : `RD_RDY;
      end
      `RD_DONE : begin
         next_state     = (Bus2IP_CS) ? `RD_DONE : `ST_IDLE;
      end
   endcase
end

reg   [C_S_AXI_DATA_WIDTH-1:0]   wr_data;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      wr_data  <= 0;
   end
   else if (Bus2IP_CS & ~Bus2IP_RNW) begin
      wr_data  <= Bus2IP_Data;
   end

reg   [7:0] wr_ack_cnt;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      wr_ack_cnt  <= 0;
   end
   else if (current_state == `ST_IDLE) begin
      wr_ack_cnt  <= 0;
   end
   else if (wr_ack_cnt > 0) begin
      wr_ack_cnt  <= wr_ack_cnt + 1;
   end
   else if (current_state == `WR_RDY) begin
      wr_ack_cnt  <= 1;
   end

assign IP2Bus_WrAck = (wr_ack_cnt > 2);


reg   [7:0] rd_ack_cnt;

always @(posedge S_AXI_ACLK)
   if (~S_AXI_ARESETN) begin
      rd_ack_cnt  <= 0;
   end
   else if (current_state == `ST_IDLE) begin
      rd_ack_cnt  <= 0;
   end
   else if (rd_ack_cnt > 0) begin
      rd_ack_cnt  <= rd_ack_cnt + 1;
   end
   else if (current_state == `RD_RDY) begin
      rd_ack_cnt  <= 1;
   end


assign IP2Bus_RdAck = (rd_ack_cnt > 2);
assign IP2Bus_Data  = wr_data;

sume_axi_ipif
#(
   .C_BASEADDR             (  C_BASEADDR           ),
   .C_HIGHADDR             (  C_HIGHADDR           ),
   .C_S_AXI_DATA_WIDTH     (  C_S_AXI_DATA_WIDTH   ),
   .C_S_AXI_ADDR_WIDTH     (  C_S_AXI_ADDR_WIDTH   )
)
sume_axi_ipif
(
   .S_AXI_ACLK             (  S_AXI_ACLK           ),
   .S_AXI_ARESETN          (  S_AXI_ARESETN        ),
                                   
   .S_AXI_AWADDR           (  S_AXI_AWADDR         ),
   .S_AXI_WDATA            (  S_AXI_WDATA          ),
   .S_AXI_WSTRB            (  S_AXI_WSTRB          ),
   .S_AXI_AWVALID          (  S_AXI_AWVALID        ),
   .S_AXI_WVALID           (  S_AXI_WVALID         ),
   .S_AXI_WREADY           (  S_AXI_WREADY         ),
   .S_AXI_AWREADY          (  S_AXI_AWREADY        ),
   .S_AXI_BREADY           (  S_AXI_BREADY         ),
   .S_AXI_BVALID           (  S_AXI_BVALID         ),
                                        
   .S_AXI_ARADDR           (  S_AXI_ARADDR         ),
   .S_AXI_ARVALID          (  S_AXI_ARVALID        ),
   .S_AXI_RREADY           (  S_AXI_RREADY         ),
   .S_AXI_ARREADY          (  S_AXI_ARREADY        ),
   .S_AXI_RVALID           (  S_AXI_RVALID         ),
   .S_AXI_RDATA            (  S_AXI_RDATA          ),
   .S_AXI_RRESP            (  S_AXI_RRESP          ),
   .S_AXI_BRESP            (  S_AXI_BRESP          ),
                                         
   .Bus2IP_Clk             (  ),
   .Bus2IP_Resetn          (  ),
   .Bus2IP_Addr            (  Bus2IP_Addr          ),
   .Bus2IP_CS              (  Bus2IP_CS            ),
   .Bus2IP_RNW             (  Bus2IP_RNW           ),
   .Bus2IP_Data            (  Bus2IP_Data          ),
   .Bus2IP_BE              (  Bus2IP_BE            ),
   .IP2Bus_Data            (  IP2Bus_Data          ),
   .IP2Bus_RdAck           (  IP2Bus_RdAck         ),
   .IP2Bus_WrAck           (  IP2Bus_WrAck         ),
   .IP2Bus_Error           (  )
);

endmodule
