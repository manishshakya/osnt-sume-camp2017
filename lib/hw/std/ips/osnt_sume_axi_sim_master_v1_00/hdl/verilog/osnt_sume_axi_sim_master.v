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

module osnt_sume_axi_sim_master
#(
   parameter   C_M_AXI_DATA_WIDTH   = 32,
   parameter   C_M_AXI_ADDR_WIDTH   = 32,
   parameter   REG_FILE             = "../file.axi"
)
(
   // AXI Lite ports
   input                                        M_AXI_ACLK,
   input                                        M_AXI_ARESETN,

   output         [C_M_AXI_ADDR_WIDTH-1:0]      M_AXI_AWADDR,
   output         [C_M_AXI_DATA_WIDTH-1:0]      M_AXI_WDATA,
   output         [C_M_AXI_DATA_WIDTH/8-1:0]    M_AXI_WSTRB,
   output                                       M_AXI_AWVALID,
   input                                        M_AXI_AWREADY,
   output                                       M_AXI_WVALID,
   input                                        M_AXI_WREADY,
   input                                        M_AXI_BVALID,
   output                                       M_AXI_BREADY,
   input          [1:0]                         M_AXI_BRESP,

   output         [C_M_AXI_ADDR_WIDTH-1:0]      M_AXI_ARADDR,
   output                                       M_AXI_ARVALID,
   input                                        M_AXI_ARREADY,
   input          [C_M_AXI_DATA_WIDTH-1:0]      M_AXI_RDATA,
   input                                        M_AXI_RVALID,
   output                                       M_AXI_RREADY,
   input          [1:0]                         M_AXI_RRESP
);

reg                                    IP2Bus_MstRd_Req;
reg                                    IP2Bus_MstWr_Req;
reg      [C_M_AXI_ADDR_WIDTH-1:0]      IP2Bus_Mst_Addr;
reg      [(C_M_AXI_DATA_WIDTH/8)-1:0]  IP2Bus_Mst_BE;
wire                                   Bus2IP_Mst_CmdAck;
wire                                   Bus2IP_Mst_Cmplt;
wire     [C_M_AXI_DATA_WIDTH-1:0]      Bus2IP_MstRd_d;
reg      [C_M_AXI_DATA_WIDTH-1:0]      IP2Bus_MstWr_d;

`define  ST_IDLE  0
`define  ST_WAIT  1

integer  file, wr, rd;
reg   [8*64-1:0]  line;

reg   [3:0] state;

reg   [C_M_AXI_ADDR_WIDTH-1:0]      wr_addr, rd_addr;
reg   [(C_M_AXI_DATA_WIDTH/8)-1:0]  wr_be;
reg   [C_M_AXI_DATA_WIDTH-1:0]      wr_data;

initial begin
   file = $fopen(REG_FILE, "r");
end

always @(posedge M_AXI_ACLK)
   if (~M_AXI_ARESETN) begin
      IP2Bus_MstRd_Req  <= 0;
      IP2Bus_MstWr_Req  <= 0;
      IP2Bus_Mst_Addr   <= 0;
      IP2Bus_Mst_BE     <= 0;
      IP2Bus_MstWr_d    <= 0;
      state             <= `ST_IDLE;
   end
   else begin
      case (state)
         `ST_IDLE : begin
            $fgets(line, file);
            state = `ST_IDLE;
            if (line != 0) begin
               wr = $sscanf(line, "%h, %h, %h, -.", wr_addr, wr_data, wr_be);
               rd = $sscanf(line, "-, -, -, %h.", rd_addr);

               $display("%h, %h, %h, %h", wr_addr, wr_data, wr_be, rd_addr);

               if (wr == 3) begin
                  IP2Bus_MstWr_Req = 1;
                  IP2Bus_MstRd_Req = 0;
                  IP2Bus_Mst_Addr  = wr_addr;
                  IP2Bus_MstWr_d   = wr_data;
                  IP2Bus_Mst_BE    = wr_be;
               end
               else if(rd == 1) begin
                  IP2Bus_MstWr_Req = 0;
                  IP2Bus_MstRd_Req = 1;
                  IP2Bus_Mst_Addr  = rd_addr;
                  IP2Bus_MstWr_d   = 0;
                  IP2Bus_Mst_BE    = 0;
               end
               state = `ST_WAIT;
            end
         end
         `ST_WAIT : begin
            IP2Bus_MstWr_Req = 0;
            IP2Bus_MstRd_Req = 0;
            state = `ST_WAIT;
            if (Bus2IP_Mst_Cmplt) state = `ST_IDLE;
         end
      endcase
   end


sume_axi_master_if
#(
   .C_M_AXI_DATA_WIDTH     (  C_M_AXI_DATA_WIDTH   ),
   .C_M_AXI_ADDR_WIDTH     (  C_M_AXI_ADDR_WIDTH   )
)
sume_axi_master_if
(
   .M_AXI_ACLK             (  M_AXI_ACLK           ),
   .M_AXI_ARESETN          (  M_AXI_ARESETN        ),
                                   
   .M_AXI_AWADDR           (  M_AXI_AWADDR         ),
   .M_AXI_WDATA            (  M_AXI_WDATA          ),
   .M_AXI_WSTRB            (  M_AXI_WSTRB          ),
   .M_AXI_AWVALID          (  M_AXI_AWVALID        ),
   .M_AXI_WVALID           (  M_AXI_WVALID         ),
   .M_AXI_WREADY           (  M_AXI_WREADY         ),
   .M_AXI_AWREADY          (  M_AXI_AWREADY        ),
   .M_AXI_BREADY           (  M_AXI_BREADY         ),
   .M_AXI_BVALID           (  M_AXI_BVALID         ),
                                        
   .M_AXI_ARADDR           (  M_AXI_ARADDR         ),
   .M_AXI_ARVALID          (  M_AXI_ARVALID        ),
   .M_AXI_RREADY           (  M_AXI_RREADY         ),
   .M_AXI_ARREADY          (  M_AXI_ARREADY        ),
   .M_AXI_RVALID           (  M_AXI_RVALID         ),
   .M_AXI_RDATA            (  M_AXI_RDATA          ),
   .M_AXI_RRESP            (  M_AXI_RRESP          ),
   .M_AXI_BRESP            (  M_AXI_BRESP          ),
                                         
   .IP2Bus_MstRd_Req       (  IP2Bus_MstRd_Req     ),
   .IP2Bus_MstWr_Req       (  IP2Bus_MstWr_Req     ),
   .IP2Bus_Mst_Addr        (  IP2Bus_Mst_Addr      ),
   .IP2Bus_Mst_BE          (  IP2Bus_Mst_BE        ),
   .Bus2IP_Mst_CmdAck      (  Bus2IP_Mst_CmdAck    ),
   .Bus2IP_Mst_Cmplt       (  Bus2IP_Mst_Cmplt     ),
   .Bus2IP_MstRd_d         (  Bus2IP_MstRd_d       ),
   .IP2Bus_MstWr_d         (  IP2Bus_MstWr_d       )
);

endmodule
