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
 *        ipif_table_regs.v
 *
 *  Author:
 *        Muhammad Shahbaz
 *
 *  Description:
 *        WARNING: This module does *not* implement the table.
 */
 
 module ipif_table_regs 
 #(
   parameter C_S_AXI_DATA_WIDTH = 32,          
   parameter C_S_AXI_ADDR_WIDTH = 32,   
   parameter TBL_NUM_COLS       = 4,
   parameter TBL_NUM_ROWS       = 4
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
   
   // -- Table ports
   output reg                                          tbl_rd_req,       // Request a read
   input                                               tbl_rd_ack,       // Pulses hi on ACK
   output reg [log2(TBL_NUM_ROWS)-1 : 0]               tbl_rd_addr,      // Address in table to read
   input [(C_S_AXI_DATA_WIDTH*TBL_NUM_COLS)-1 : 0]     tbl_rd_data,      // Value in table
   output reg                                          tbl_wr_req,       // Request a write
   input                                               tbl_wr_ack,       // Pulses hi on ACK
   output reg [log2(TBL_NUM_ROWS)-1 : 0]               tbl_wr_addr,      // Address in table to write
   output [(C_S_AXI_DATA_WIDTH*TBL_NUM_COLS)-1 : 0]    tbl_wr_data       // Value to write to table
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
   localparam addr_width = log2(TBL_NUM_COLS+2);
   localparam addr_width_lsb = log2(C_S_AXI_ADDR_WIDTH/8);
   localparam addr_width_msb = addr_width+addr_width_lsb;

   localparam tbl_num_rows_in_bits = log2(TBL_NUM_ROWS);
   
   // Address Mapping
   //         COLUMNS [N]
   localparam TBL_WR_ADDR = TBL_NUM_COLS;
   localparam TBL_RD_ADDR = TBL_NUM_COLS+1;
   
   // States
   localparam WAIT_FOR_REQ = 2'b00;
   localparam PROCESS_REQ  = 2'b01;
   localparam DONE         = 2'b10;
 
   // -- interal wire/regs
   genvar i;
   integer j;
   
   reg  [1 : 0]                    state;
   
   reg [C_S_AXI_DATA_WIDTH-1 : 0] tbl_cells_rd_port [0 : TBL_NUM_COLS-1];
   reg  [C_S_AXI_DATA_WIDTH-1 : 0] tbl_cells_wr_port [0 : TBL_NUM_COLS-1];
   
   generate
	 // Unpacking Read/Write port
	 for (i=0; i<TBL_NUM_COLS; i=i+1) begin : CELL
	   assign tbl_wr_data[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i] = tbl_cells_wr_port[i];
           
	   always @ (posedge Bus2IP_Clk) begin
              if (tbl_rd_ack) tbl_cells_rd_port[i] <= tbl_rd_data[C_S_AXI_DATA_WIDTH*(i+1)-1 : C_S_AXI_DATA_WIDTH*i];
           end
	 end
   endgenerate
 
   // -- Implementation
   
   assign IP2Bus_Error = 1'b0;
   
   // Writes
   always @ (posedge Bus2IP_Clk) begin 
     if (~Bus2IP_Resetn) begin
	   for (j=0; j<TBL_NUM_COLS; j=j+1) 
	     tbl_cells_wr_port[j] <= {C_S_AXI_DATA_WIDTH{1'b0}};
	   tbl_wr_addr <= {tbl_num_rows_in_bits{1'b0}};
	   tbl_wr_req <= 1'b0;
	   tbl_rd_addr <= {tbl_num_rows_in_bits{1'b0}};
	   tbl_rd_req <= 1'b0;

	   IP2Bus_WrAck <= 1'b0;

	   state <= WAIT_FOR_REQ;
	 end
	 else begin
	   case (state)
	     WAIT_FOR_REQ: begin
		   if (Bus2IP_CS & ~Bus2IP_RNW) begin
	         if (Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] < TBL_NUM_COLS) begin
	           tbl_cells_wr_port[Bus2IP_Addr[addr_width_msb-1:addr_width_lsb]] <= Bus2IP_Data;
		       IP2Bus_WrAck <= 1'b1;
			   state <= DONE;
		     end
		     else if (Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] == TBL_WR_ADDR) begin
		       tbl_wr_addr <= Bus2IP_Data[tbl_num_rows_in_bits-1:0];
		       tbl_wr_req <= 1'b1;
			   state <= PROCESS_REQ;
		     end
		     else if (Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] == TBL_RD_ADDR) begin
		       tbl_rd_addr <= Bus2IP_Data[tbl_num_rows_in_bits-1:0];
		       tbl_rd_req <= 1'b1;
			   state <= PROCESS_REQ;
		     end
	       end
		 end
		 PROCESS_REQ: begin
		   if (tbl_wr_ack) tbl_wr_req <= 1'b0;
		   else if (tbl_rd_ack) tbl_rd_req <= 1'b0;

                   if (tbl_wr_ack | tbl_rd_ack) begin
		      IP2Bus_WrAck <= 1'b1;
		      state <= DONE;
                   end
		 end
		 DONE: begin		   
		   if (~Bus2IP_CS) begin
		     IP2Bus_WrAck <= 1'b0;
	         state <= WAIT_FOR_REQ;
		   end
		 end
		 default: begin
		   state <= WAIT_FOR_REQ;
		 end
	   endcase
	 end
   end

   reg   [3:0] rd_count;
    always @ (posedge Bus2IP_Clk) 
     if (~Bus2IP_Resetn) begin
         rd_count    <= 0;
         IP2Bus_RdAck <= 1'b0;
      end
      else if (rd_count > 6) begin
         rd_count    <= (Bus2IP_CS) ? 0 : rd_count;
         IP2Bus_RdAck   <= 0;
      end
      else if (rd_count == 6) begin
         rd_count    <= rd_count + 1;
         IP2Bus_RdAck   <= 1;
      end
      else if (rd_count > 0) begin
         rd_count    <= rd_count + 1;
         IP2Bus_RdAck   <= 0;
      end
      else if (Bus2IP_CS & Bus2IP_RNW) begin
         rd_count    <= 1;
         IP2Bus_RdAck   <= 0;
      end
      else begin
         rd_count    <= 0;
         IP2Bus_RdAck   <= 0;
      end
  
   
   // Reads
   always @ (posedge Bus2IP_Clk) begin 
     if (~Bus2IP_Resetn) begin
	   IP2Bus_Data <= {C_S_AXI_DATA_WIDTH{1'b0}};
	 end
	 else begin
      if (IP2Bus_RdAck) begin
      end
	   else if (Bus2IP_CS & Bus2IP_RNW) begin
	     if (Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] < TBL_NUM_COLS) begin
	       IP2Bus_Data <= tbl_cells_rd_port[Bus2IP_Addr[addr_width_msb-1:addr_width_lsb]];
		 end
		 else if (Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] == TBL_WR_ADDR) begin
		   IP2Bus_Data <= tbl_wr_addr;
		 end
		 else if (Bus2IP_Addr[addr_width_msb-1:addr_width_lsb] == TBL_RD_ADDR) begin
		   IP2Bus_Data <= tbl_rd_addr;
		 end
       else begin
            IP2Bus_Data <= 0;
         end
	   end
	 end
   end
    
 endmodule 
