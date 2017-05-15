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
// Version 1.0 (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at:
//
// http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@

`timescale 1ns/1ps

module system_wrapper_tb();

reg fpga_sysclk_n, fpga_sysclk_p;
reg reset;

integer i;

initial begin
   fpga_sysclk_n   = 1'b0;
   fpga_sysclk_p   = 1'b1;
   $display("[%t] : System Reset Asserted...", $realtime);
   reset = 1'b1;
   for (i = 0; i < 50; i = i + 1) begin
      @(posedge fpga_sysclk_p);
   end
   $display("[%t] : System Reset De-asserted...", $realtime);
   reset = 1'b0;
end

always #2.5 fpga_sysclk_n = ~fpga_sysclk_n;//200MHz
always #2.5 fpga_sysclk_p = ~fpga_sysclk_p;//200MHz

system system_i
       (.fpga_sysclk_n(fpga_sysclk_n),
        .fpga_sysclk_p(fpga_sysclk_p),
        .reset(reset));

endmodule
