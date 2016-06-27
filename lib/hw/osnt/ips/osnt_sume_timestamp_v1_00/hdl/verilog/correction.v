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
 *        correction.v
 *
 *  Author:
 *        Gianni Antichi
 *
 *  Description:
 *        Timestamp Correction Module.
 */

 
module correction
	#(parameter TIMESTAMP_WIDTH = 64,
	  parameter DDS_WIDTH = 32)
   	(
    	// input
    		input [TIMESTAMP_WIDTH-1:0]     time_pps,
    		input                           pps_valid,
		input				correction_mode,

    	// output
    		output reg [DDS_WIDTH-1:0]	dds,

    	// misc
    		input                           reset,
    		input                           clk
    	);
          
  
	localparam NUM_STATES	      = 3;
     	localparam WAIT_FIRST_PPS     = 1;
     	localparam WAIT_PPS           = 2;
     	localparam UPDATE_DDS 	      = 4;
	localparam CORRECTION_WEIGHT  = 10;
	//localparam DDS_RATE_DEFAULT   = 32'hd6bf94d6; 
	//localparam DDS_RATE_DEFAULT   = 32'h4aedcca; //78568650.580673916
	localparam DDS_RATE_DEFAULT   = 32'h4c533c0; //1-28/27.xxx 80032704


	reg [NUM_STATES-1:0]     state,state_next;
	reg [TIMESTAMP_WIDTH-1:0]time_prev_pps,time_prev_pps_next;
     	reg [DDS_WIDTH-1:0]      dds_rate,dds_rate_next;
     	reg [TIMESTAMP_WIDTH-1:0]error_signed,error_signed_next;
 
    

    	always @(*) begin
     		state_next = state;
     		dds_rate_next = dds_rate;
     		time_prev_pps_next = time_prev_pps;
    		error_signed_next = time_pps - time_prev_pps;  

		case(state)
        	WAIT_FIRST_PPS: begin
        		if(pps_valid) begin
                		time_prev_pps_next  = time_pps;
				state_next = WAIT_PPS;
           		end
        	end

		WAIT_PPS: begin
        		if(pps_valid) begin
				time_prev_pps_next = time_pps;
                		state_next = UPDATE_DDS;
			end
        	end

        	UPDATE_DDS: begin
			if(error_signed[TIMESTAMP_WIDTH-1])
				state_next = WAIT_FIRST_PPS;
			else begin
				state_next = WAIT_PPS;
        			if(error_signed[TIMESTAMP_WIDTH-2:32])
               				dds_rate_next = dds_rate - (error_signed[31:0]>>CORRECTION_WEIGHT);
	    			else
               				dds_rate_next = dds_rate + ((~error_signed[31:0])>>CORRECTION_WEIGHT);
			end
         	end
       		endcase
	end


   	always @(posedge clk) begin
        	if(reset) begin
	     		dds_rate    	<= DDS_RATE_DEFAULT;
			dds		<= DDS_RATE_DEFAULT;
             		error_signed	<= 0;
             		time_prev_pps	<= 0;
             		state       	<= WAIT_FIRST_PPS;
        	end
		else begin
             		error_signed	<= error_signed_next;
             		time_prev_pps 	<= time_prev_pps_next;
			state		<= state_next;
			dds_rate	<= dds_rate_next;
			if(correction_mode)
				dds	<= dds_rate;
        	end
   	end

endmodule // correction
