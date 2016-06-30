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
 *        osnt_sume_axis_sim_record.v
 *
 *  Author:
 *        James Hongyi Zeng, David J. Miller, Georgina Kalogeridou
 *
 *  Description:
 *        Records traffic received from an AXI Stream master to an
 *        AXI grammar formatted text file.
 */

`timescale 1ns/1ps

module osnt_sume_axis_sim_record
#(
    // Master AXI Stream Data Width
    parameter C_S_AXIS_DATA_WIDTH = 256,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
    parameter OUTPUT_FILE = "../../stream_data_out.axi"
)
(
    // Part 1: System side signals
    // Global Ports
    input axi_aclk,

    // Slave Stream Ports (interface to data path)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input s_axis_tvalid,
    output s_axis_tready,
    input s_axis_tlast,

    output reg [10:0] counter,
    output reg activity_rec
);

    integer f;
    integer bubble_count = 0;
    reg [8*2-1:0] terminal_flag;
    
    assign s_axis_tready = 1;
    
    initial begin
        f = $fopen(OUTPUT_FILE, "w");
        counter = 0;
    end

    always @(posedge axi_aclk) begin
        if (s_axis_tvalid == 1'b1) begin
            if (bubble_count != 0) begin
                $fwrite(f, "*%0d\n", bubble_count);
                bubble_count <= 0;
            end
            if (s_axis_tlast == 1'b1) begin
                terminal_flag = ".";
		counter <= counter + 1;
		activity_rec <= 1;
            end
            else begin
                terminal_flag = ",";
		activity_rec <= 1;
            end
            
            $fwrite(f, "%x, %x, %x%0s # %0d ns\n",
                              s_axis_tdata,
                              s_axis_tkeep,
                              s_axis_tuser,
                              terminal_flag,
                              $time
                              ); 
        end
        else begin
            bubble_count <= bubble_count + 1;
	         activity_rec <= 0;
        end
    end
endmodule
