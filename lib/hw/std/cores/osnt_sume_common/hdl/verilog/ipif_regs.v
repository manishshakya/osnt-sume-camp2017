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
 *        ipif_regs.v
 *
 *  Author:
 *        Muhammad Shahbaz
 *
 *  Description:
 */
 
 module ipif_regs 
 #(
   parameter C_S_AXI_DATA_WIDTH = 32,          
   parameter C_S_AXI_ADDR_WIDTH = 32,   
   parameter NUM_WO_REGS = 0, // Number of registers written by software and read by hardware only
   parameter NUM_RW_REGS = 0, // Number of registers written by software and read by both hardware and software
   parameter NUM_RO_REGS = 0  // Number of registers written by hardware and read by software only
   // Address Mapping
   //  ------  = base_address
   // |  WO  |         
   // |------|         |
   // |  RW  |         |
   // |------|         \/
   // |  RO  |
   //  ------  = high_address
 )
 (   
   // -- IPIF ports
   input                                               Bus2IP_Clk,
   input                                               Bus2IP_Resetn,
   input      [C_S_AXI_ADDR_WIDTH-1 : 0]               Bus2IP_Addr,
   input                                               Bus2IP_CS,
   input                                               Bus2IP_RNW,
   input      [C_S_AXI_DATA_WIDTH-1 : 0]               Bus2IP_Data,
   input      [C_S_AXI_DATA_WIDTH/8-1 : 0]             Bus2IP_BE,
   output     reg [C_S_AXI_DATA_WIDTH-1 : 0]           IP2Bus_Data,
   output     reg                                      IP2Bus_RdAck,
   output     reg                                      IP2Bus_WrAck,
   output                                              IP2Bus_Error,
   
   // -- Register ports
   output    [NUM_WO_REGS*C_S_AXI_DATA_WIDTH : 0]    	 wo_regs,
   input     [NUM_WO_REGS*C_S_AXI_DATA_WIDTH : 0]      wo_defaults,
   output    [NUM_RW_REGS*C_S_AXI_DATA_WIDTH : 0]      rw_regs,
   input     [NUM_RW_REGS*C_S_AXI_DATA_WIDTH : 0]      rw_defaults,
   input     [NUM_RO_REGS*C_S_AXI_DATA_WIDTH : 0]      ro_regs
 );

    function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction
   
   // -- internal parameters
   localparam addr_width = log2(NUM_WO_REGS+NUM_RW_REGS+NUM_RO_REGS);
   localparam addr_width_lsb = log2(C_S_AXI_ADDR_WIDTH/8);
   localparam addr_width_msb = addr_width+addr_width_lsb;
 
   // -- interal wire/regs
   genvar i;
   integer j;
   
   wire [C_S_AXI_DATA_WIDTH-1 : 0] reg_file_rd_port  [0 : NUM_RW_REGS+NUM_RO_REGS];
   reg  [C_S_AXI_DATA_WIDTH-1 : 0] reg_file_wr_port  [0 : NUM_WO_REGS+NUM_RW_REGS];
   wire [C_S_AXI_DATA_WIDTH-1 : 0] reg_file_defaults [0 : NUM_WO_REGS+NUM_RW_REGS];
   
 generate	 
	 // Unpacking Write Only registers
	 if (NUM_WO_REGS > 0)       
	   for (i=0; i<NUM_WO_REGS; i=i+1) begin : WO
	     assign wo_regs[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i] = reg_file_wr_port[i];
       assign reg_file_defaults[i] = wo_defaults[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i];
	   end

	 // Unpacking Read Write registers
	 if (NUM_RW_REGS > 0)       
	   for (i=0; i<NUM_RW_REGS; i=i+1) begin : RW
	     assign rw_regs[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i] = reg_file_wr_port[NUM_WO_REGS+i];
		   assign reg_file_rd_port[i] = reg_file_wr_port[NUM_WO_REGS+i];
       assign reg_file_defaults[NUM_WO_REGS+i] = rw_defaults[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i];
	   end

   // Unpacking Read Only registers
   if (NUM_RO_REGS > 0)       
	   for (i=0; i<NUM_RO_REGS; i=i+1) begin : RO
	     assign reg_file_rd_port[NUM_RW_REGS+i] = ro_regs[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i];
     end
 endgenerate
 
 	 // -- Implementation
   assign IP2Bus_Error = 1'b0;
   
   // SW writes
   always @ (posedge Bus2IP_Clk) begin
     if (~Bus2IP_Resetn) begin
	     for (j=0; j<(NUM_WO_REGS+NUM_RW_REGS); j=j+1) 
	       reg_file_wr_port[j] <= reg_file_defaults[j];
	   
	     IP2Bus_WrAck <= 1'b0;
	   end
	   else begin
	     IP2Bus_WrAck <= 1'b0;
	   
	     if (Bus2IP_CS && !Bus2IP_RNW && Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] < (NUM_WO_REGS+NUM_RW_REGS)) begin
	       reg_file_wr_port[Bus2IP_Addr[addr_width_msb-1:addr_width_lsb]] <= Bus2IP_Data;
		     IP2Bus_WrAck <= 1'b1;
	     end
         if (Bus2IP_CS && !Bus2IP_RNW) begin
            IP2Bus_WrAck   <= 1;
         end
	   end
   end
   
   // SW reads
   reg   r_IP2Bus_RdAck;
   always @ (posedge Bus2IP_Clk) begin
     if (~Bus2IP_Resetn) begin
	     IP2Bus_Data <= {C_S_AXI_DATA_WIDTH{1'b0}};
	     IP2Bus_RdAck <= 1'b0;
	     r_IP2Bus_RdAck <= 1'b0;
	   end
	   else begin
         if (r_IP2Bus_RdAck)
            r_IP2Bus_RdAck    <= (Bus2IP_CS) ? 1 : 0;
         else if (IP2Bus_RdAck) begin
            IP2Bus_RdAck   <= 0;
            r_IP2Bus_RdAck    <= 1;
         end	   
	     else if (Bus2IP_CS && Bus2IP_RNW && Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] >= (NUM_WO_REGS)) begin
	       IP2Bus_Data <= reg_file_rd_port[Bus2IP_Addr[addr_width_msb-1:addr_width_lsb]-NUM_WO_REGS];
		     IP2Bus_RdAck <= 1'b1;
	     end
         else if (Bus2IP_CS && Bus2IP_RNW) begin
            IP2Bus_Data <= 0;
            IP2Bus_RdAck   <= 1;
         end
	   end
   end
    
 endmodule 
