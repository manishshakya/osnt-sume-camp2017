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
//

`timescale 1ns/1ps

module osnt_sume_bram 
#(
	parameter	ADDR_WIDTH		= 20,
	parameter	DATA_WIDTH		= 512 
)
(
   input    [ADDR_WIDTH-1:0]     bram_addr_a,
   input                         bram_clk_a,
   input    [DATA_WIDTH-1:0]     bram_wrdata_a,
   output   reg   [DATA_WIDTH-1:0]     bram_rddata_a,
   input                         bram_en_a,
   input                         bram_rst_a,
   input    [DATA_WIDTH/8-1:0]   bram_we_a,

   input    [ADDR_WIDTH-1:0]     bram_addr_b,
   input                         bram_clk_b,
   input    [DATA_WIDTH-1:0]     bram_wrdata_b,
   output   reg   [DATA_WIDTH-1:0]     bram_rddata_b,
   input                         bram_en_b,
   input                         bram_rst_b,
   input    [DATA_WIDTH/8-1:0]   bram_we_b
);

(* ram_style = "block" *) reg   [DATA_WIDTH-1:0]    bootmem[0:(2**(ADDR_WIDTH-6))-1];

reg   [ADDR_WIDTH-1-6:0]   addr_dly_a, addr_dly_b;

integer i;

always @(posedge bram_clk_a) begin
   if (bram_en_a) begin
      bram_rddata_a  <= bootmem[bram_addr_a[ADDR_WIDTH-1:6]];
      for (i=0; i<DATA_WIDTH/8; i=i+1) begin
         if (bram_we_a[i]) bootmem[bram_addr_a[ADDR_WIDTH-1:6]][i*8+:8] <= bram_wrdata_a[i*8+:8];
      end
   end
end

always @(posedge bram_clk_b) begin
   if (bram_en_b) begin
      bram_rddata_b  <= bootmem[bram_addr_b[ADDR_WIDTH-1:6]];
      for (i=0; i<DATA_WIDTH/8; i=i+1) begin
         if (bram_we_b[i]) bootmem[bram_addr_b[ADDR_WIDTH-1:6]][i*8+:8] <= bram_wrdata_b[i*8+:8];
      end
   end
end

endmodule
