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
 *        multistage_priority_mux.v
 *
 *  Author:
 *        Muhammad Shahbaz
 *
 *  Description:
 *        Hardwire the hardware interfaces to CPU and vice versa
 */

module multistage_priority_mux 
#(
   parameter ATTRIBUTE_DATA_WIDTH   = 135,
   parameter DIVISION_FACTOR        = 2,
   parameter DATA_GROUPS            = 4
)
(
   // --- Results 
   output                                                   valid_o,
   output      [ATTRIBUTE_DATA_WIDTH-1:0]                   data_o,
      
   input       [DATA_GROUPS-1:0]                            valid_groups_i,
   input       [(DATA_GROUPS*ATTRIBUTE_DATA_WIDTH)-1:0]     data_groups_i,
                                                                                                                    
   // --- Misc
   input                                                    reset,
   input                                                    clk 
);
   
 
//------------------------ Logic ----------------------------------
reg valid;
reg [ATTRIBUTE_DATA_WIDTH-1:0] data;

always @(posedge clk or posedge reset)
   if (reset) begin
      valid    <= 1'b0;   
      data     <= {ATTRIBUTE_DATA_WIDTH{1'b0}};
   end
   else begin // Need to check the priorities.
      if (valid_groups_i[2]) begin
         valid    <= 1;   
         data     <= data_groups_i[(2*ATTRIBUTE_DATA_WIDTH)+ATTRIBUTE_DATA_WIDTH-1:(2*ATTRIBUTE_DATA_WIDTH)];
      end
      else if (valid_groups_i[1]) begin
         valid    <= 1;   
         data     <= data_groups_i[(1*ATTRIBUTE_DATA_WIDTH)+ATTRIBUTE_DATA_WIDTH-1:(1*ATTRIBUTE_DATA_WIDTH)];
      end
      else if (valid_groups_i[0]) begin
         valid    <= 1;   
         data     <= data_groups_i[(0*ATTRIBUTE_DATA_WIDTH)+ATTRIBUTE_DATA_WIDTH-1:(0*ATTRIBUTE_DATA_WIDTH)];
      end
      else begin
         valid    <= 0;   
         data     <= 0;
      end
   end

assign valid_o   = valid;    
assign data_o     = data;   

endmodule
