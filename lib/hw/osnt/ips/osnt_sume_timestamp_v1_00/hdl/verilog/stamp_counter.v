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
 *        stamp_counter.v
 *
 *  Author:
 *        Gianni Antichi
 *
 *  Description:
 *        Stamp Counter module
 */

module stamp_counter
	#(
      parameter   C_S_AXI_DATA_WIDTH = 32,
    		parameter TIMESTAMP_WIDTH = 64)
	(
    
		output [TIMESTAMP_WIDTH-1:0]	stamp_counter,
		output reg			gps_connected,

    		input [1:0]          	        restart_time,
    		input [TIMESTAMP_WIDTH-1:0]     ntp_timestamp,

		input				correction_mode,
		input				pps_rx,

    		input                           axi_aclk,
    		input                           axi_resetn
 	);



localparam PPS       = 27'h5F5E100;
localparam OVERFLOW  = 32'hffffffff;
localparam CNT_INIT  = 32'h1312d000;
localparam DDS_WIDTH = 32;

   	//reg [TIMESTAMP_WIDTH-6:0]	temp;
   	reg [TIMESTAMP_WIDTH-1:0]	temp;
	wire[TIMESTAMP_WIDTH-1:0]	stamp_cnt;

        wire                            pps_valid;
        reg                             pps_rx_d1;
        reg                             pps_rx_d2;
        reg                             pps_rx_d3;

   	reg [DDS_WIDTH:0]             accumulator;
	reg [31:0]			counter;
   
        wire [DDS_WIDTH-1:0]            dds_rate;
 
   	//assign stamp_counter = {temp,5'b0};
	//assign stamp_cnt = {temp,5'b0};
   	assign stamp_counter = temp;
	assign stamp_cnt = temp;
  	assign pps_valid = !pps_rx_d2 & pps_rx_d3;


        correction
        #(
                .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
                .DDS_WIDTH(DDS_WIDTH))
        correction
        (
        // input
                .time_pps      	(stamp_cnt),
                .pps_valid     	(pps_valid),
		.correction_mode(correction_mode),
        // output
                .dds      	(dds_rate),
        // misc
                .reset         	(~axi_resetn),
                .clk           	(axi_aclk)
        );


        always @(posedge axi_aclk) begin
                if (~axi_resetn) begin
                        pps_rx_d1  <= 0;
                	pps_rx_d2  <= 0;
                	pps_rx_d3  <= 0;
			counter		<= CNT_INIT;
			gps_connected	<= 0;
                end
                else begin
			pps_rx_d1 <= pps_rx;
                	pps_rx_d2 <= pps_rx_d1;
                	pps_rx_d3 <= pps_rx_d2;
			if(pps_valid) begin
				counter		<= CNT_INIT;
				gps_connected	<= 1;
			end
			else begin
				if(!counter)
					gps_connected <= 0;
				else begin
					gps_connected <= 1;
					counter	<= counter - 1;
				end
			end  
		end
	end

always @(posedge axi_aclk) begin
   if(~axi_resetn) begin
      temp     <= 0;
      accumulator <= 0;
   end
	else begin
	   if(restart_time[0]) begin
         temp        <= ntp_timestamp;
      end
		else if (restart_time[1]) begin
	      temp        <= 0;
         accumulator <= 0;
      end
      else begin
         // 2^32/156.25Mhz
         //accumulator <= accumulator + dds_rate;
         //if((OVERFLOW-accumulator)>dds_rate) temp  <= temp + 28;
         if (accumulator[DDS_WIDTH]) begin
            accumulator    <= {1'b0,accumulator[0+:32]};
         end
         else begin
            accumulator    <= accumulator + dds_rate;
            temp           <= temp + 28;
         end
		end
	end
end

endmodule // stamp_counter




