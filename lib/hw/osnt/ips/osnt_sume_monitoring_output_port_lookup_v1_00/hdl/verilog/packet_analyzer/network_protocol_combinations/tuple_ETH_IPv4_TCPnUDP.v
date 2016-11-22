//
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
// Junior University
// Copyright (c) 2016 University of Cambridge
// Copyright (c) 2016 Jong Hun Han, Gianni Antichi
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
 *        ETH_IPv4_TCPnUDP.v
 *
 *  Author:
 *        Muhammad Shahbaz, Gianni Antichi
 *
 *  Description:
 *        Hardwire the hardware interfaces to CPU and vice versa
 */
`timescale 1ns/1ps

`include "../defines.vh"

module tuple_ETH_IPv4_TCPnUDP
#(
   parameter   C_S_AXIS_DATA_WIDTH     = 256,
   parameter   C_S_AXIS_TUSER_WIDTH    = 128,
   parameter   TUPLE_WIDTH             = 104,
   parameter   NUM_INPUT_QUEUES        = 8,
   parameter   PRTCL_ID_WIDTH          = 2,
   parameter   SRC_PORT_POS            = 16,
   parameter   BYTES_COUNT_WIDTH       = 16,
   parameter   ATTRIBUTE_DATA_WIDTH    = 192 
)
(  
   // --- Interface to the previous stage
   input          [C_S_AXIS_DATA_WIDTH-1:0]     in_tdata,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]    in_tuser,
   input                                        in_valid,
   input                                        in_tlast,
   input                                        in_eoh,

   input                                        tuple_pkt_en,
   // --- Results
   output   reg                                 pkt_valid,
   output         [ATTRIBUTE_DATA_WIDTH-1:0]    pkt_attributes,

   // --- Misc
   input                                        reset,
   input                                        clk
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

//------------------ Internal Parameter ---------------------------
localparam NUM_STATES   = 3;
localparam WAIT_PKT     = 1;
localparam PKT_WORD1    = 2;
localparam PKT_WAIT_EOP = 4;

localparam IP_WIDTH        = 32;
localparam PORT_WIDTH      = 16;
localparam PROTO_WIDTH     = 8;
localparam TCP_FLAGS_WIDTH = 8;

localparam PROTO_OFFSET             = 0;
localparam IP_SRC_OFFSET            = PROTO_WIDTH;
localparam IP_DST_OFFSET            = IP_SRC_OFFSET + IP_WIDTH;
localparam PORT_SRC_OFFSET          = IP_DST_OFFSET + IP_WIDTH;
localparam PORT_DST_OFFSET          = PORT_SRC_OFFSET + PORT_WIDTH;
localparam BYTES_COUNT_OFFSET       = PORT_DST_OFFSET + PORT_WIDTH;
localparam PKT_FLAGS_OFFSET         = BYTES_COUNT_OFFSET + BYTES_COUNT_WIDTH;
localparam PRTCL_ID_OFFSET          = PKT_FLAGS_OFFSET + `PKT_FLAGS;
localparam NUM_INPUT_QUEUES_OFFSET  = PRTCL_ID_OFFSET + PRTCL_ID_WIDTH;
localparam TCP_FLAGS_OFFSET		   = NUM_INPUT_QUEUES_OFFSET + NUM_INPUT_QUEUES;	

//---------------------- Wires/Regs -------------------------------
reg   [C_S_AXIS_DATA_WIDTH-1:0]     in_tdata_d0;
reg   [C_S_AXIS_TUSER_WIDTH-1:0]    in_tuser_d0;
reg   in_valid_d0;
reg   in_tlast_d0;
reg   in_eoh_d0;

reg   [3:0]                      pkt_ip_hdr_len;
reg   [IP_WIDTH-1:0]             pkt_src_ip;
reg   [IP_WIDTH-1:0]             pkt_dst_ip;
reg   [PORT_WIDTH-1:0]           pkt_src_port;
reg   [PORT_WIDTH-1:0]           pkt_dst_port;
reg   [PROTO_WIDTH-1:0]          pkt_l4_proto;
reg   [`PKT_FLAGS-1:0]           pkt_flags;
reg   [NUM_INPUT_QUEUES-1:0]     pkt_input_if;
reg   [BYTES_COUNT_WIDTH-1:0]    pkt_bytes;
reg   [TCP_FLAGS_WIDTH-1:0]   	pkt_tcp_flags;
reg   [63:0]                     pkt_dst_mac;

reg   pkt_valid_w;
reg   [3:0]                      pkt_ip_hdr_len_w;
reg   [IP_WIDTH-1:0]             pkt_src_ip_w;
reg   [IP_WIDTH-1:0]             pkt_dst_ip_w;
reg   [PORT_WIDTH-1:0]           pkt_src_port_w;
reg   [PORT_WIDTH-1:0]           pkt_dst_port_w;
reg   [PROTO_WIDTH-1:0]          pkt_l4_proto_w;
reg   [`PKT_FLAGS-1:0]           pkt_flags_w;
reg   [NUM_INPUT_QUEUES-1:0]     pkt_input_if_w;
reg   [BYTES_COUNT_WIDTH-1:0]    pkt_bytes_w;
reg   [TCP_FLAGS_WIDTH-1:0]      pkt_tcp_flags_w;
reg   [63:0]                     pkt_dst_mac_w;
 
reg   [NUM_STATES-1:0]           cur_state;
reg   [NUM_STATES-1:0]           nxt_state;

//------------------------ Logic ----------------------------------
always @ (posedge clk or posedge reset)
   if (reset) begin
      in_valid_d0    <= 0;
      in_tlast_d0    <= 0;
      in_eoh_d0      <= 0;
      in_tdata_d0    <= 0;
      in_tuser_d0    <= 0;
   end
   else begin          
      in_valid_d0    <= in_valid;
      in_tlast_d0    <= in_tlast;
      in_eoh_d0      <= in_eoh;
      in_tdata_d0    <= in_tdata;
      in_tuser_d0    <= in_tuser;
   end

always @ (*) begin
   nxt_state         = WAIT_PKT;
   pkt_valid_w       = 1'b0;
   pkt_ip_hdr_len_w  = pkt_ip_hdr_len;
   pkt_src_ip_w      = pkt_src_ip;
   pkt_dst_ip_w      = pkt_dst_ip;
   pkt_src_port_w    = pkt_src_port;
   pkt_dst_port_w    = pkt_dst_port;
   pkt_flags_w       = pkt_flags;
   pkt_bytes_w       = pkt_bytes;
   pkt_input_if_w    = pkt_input_if;
   pkt_l4_proto_w    = pkt_l4_proto;
	pkt_tcp_flags_w   = pkt_tcp_flags;
   pkt_dst_mac_w     = pkt_dst_mac;
   case (cur_state)
      WAIT_PKT: begin
         nxt_state = WAIT_PKT;
         pkt_ip_hdr_len_w  = 4'b0;
         pkt_src_ip_w      = {IP_WIDTH{1'b0}};
         pkt_dst_ip_w      = {IP_WIDTH{1'b0}};
         pkt_src_port_w    = {PORT_WIDTH{1'b0}};
         pkt_dst_port_w    = {PORT_WIDTH{1'b0}};
         pkt_flags_w       = {`PKT_FLAGS{1'b0}};
         pkt_l4_proto_w    = {PROTO_WIDTH{1'b0}};
         pkt_input_if_w    = {NUM_INPUT_QUEUES{1'b0}};
         pkt_bytes_w       = {BYTES_COUNT_WIDTH{1'b0}};
			pkt_tcp_flags_w   = {TCP_FLAGS_WIDTH{1'b0}};
         pkt_dst_mac_w     = 0;
         if (in_valid_d0) begin
            nxt_state                  = PKT_WORD1;
            pkt_input_if_w             = in_tuser_d0[SRC_PORT_POS+NUM_INPUT_QUEUES-1:SRC_PORT_POS];
            pkt_flags_w[`PKT_FLG_IPv4] = (in_tdata_d0[159:144] == `ETH_IP);
            pkt_bytes_w                = in_tuser_d0[15:0];
            pkt_dst_mac_w              = in_tdata_d0[255:(255-63)];
            pkt_ip_hdr_len_w           = in_tdata_d0[139:136];
            if (pkt_flags_w[`PKT_FLG_IPv4]) begin
               pkt_flags_w[`PKT_FLG_TCP]  = (in_tdata_d0[71:64] == `IP_TCP);
               pkt_flags_w[`PKT_FLG_UDP]  = (in_tdata_d0[71:64] == `IP_UDP);
               pkt_l4_proto_w             = in_tdata_d0[71:64];
               pkt_src_ip_w               = {in_tdata_d0[47:16]};
               pkt_dst_ip_w               = {in_tdata_d0[15:0], pkt_dst_ip[15:0]};
            end
         end
      end
      PKT_WORD1: begin
         nxt_state = PKT_WORD1;
         if(in_valid_d0) begin
            pkt_valid_w = 1'b1;
            pkt_dst_ip_w   = {pkt_dst_ip[31:16], in_tdata_d0[255:240]};
            if (pkt_flags[`PKT_FLG_TCP]) begin
               case(pkt_ip_hdr_len)
                  4'd5: begin
                     pkt_src_port_w    = in_tdata_d0[239:224];
                     pkt_dst_port_w    = in_tdata_d0[223:208];
						   pkt_tcp_flags_w   = in_tdata_d0[135:128];
                     if (in_tlast_d0) /*small pkt*/
                        nxt_state   = WAIT_PKT;
                     else
                        nxt_state = PKT_WAIT_EOP;
                  end
                  default: begin
                     pkt_src_port_w    = {PORT_WIDTH{1'b0}};
                     pkt_dst_port_w    = {PORT_WIDTH{1'b0}};
						   pkt_tcp_flags_w   = {TCP_FLAGS_WIDTH{1'b0}};;
                     if (in_tlast_d0) /*small pkt*/
                        nxt_state   = WAIT_PKT;
                     else
                        nxt_state = PKT_WAIT_EOP;
                  end
               endcase
            end
            else
               nxt_state = (in_tlast_d0) ? WAIT_PKT : PKT_WAIT_EOP;
         end
      end
      PKT_WAIT_EOP: begin
          nxt_state  = PKT_WAIT_EOP;
          if (in_valid_d0 && in_tlast_d0)
             nxt_state  = WAIT_PKT;
      end
   endcase
end

always @(posedge clk or posedge reset)
   if (reset) begin
      cur_state      <= WAIT_PKT;
      pkt_valid      <= 1'b0;
      pkt_ip_hdr_len <= 4'b0;
      pkt_l4_proto   <= {PROTO_WIDTH{1'b0}};
      pkt_src_ip     <= {IP_WIDTH{1'b0}};
      pkt_dst_ip     <= {IP_WIDTH{1'b0}};
      pkt_src_port   <= {PORT_WIDTH{1'b0}};
      pkt_dst_port   <= {PORT_WIDTH{1'b0}};
      pkt_flags      <= {`PKT_FLAGS{1'b0}};
      pkt_input_if   <= {NUM_INPUT_QUEUES{1'b0}};
      pkt_bytes      <= {BYTES_COUNT_WIDTH{1'b0}};
		pkt_tcp_flags  <= {TCP_FLAGS_WIDTH{1'b0}};
      pkt_dst_mac    <= 0;
   end
   else begin
      cur_state      <= nxt_state;
      pkt_valid      <= pkt_valid_w;
      pkt_ip_hdr_len <= pkt_ip_hdr_len_w;
      pkt_src_ip     <= pkt_src_ip_w;
      pkt_dst_ip     <= pkt_dst_ip_w;
      pkt_src_port   <= pkt_src_port_w;
      pkt_dst_port   <= pkt_dst_port_w;
      pkt_flags      <= pkt_flags_w;
      pkt_input_if   <= pkt_input_if_w;
      pkt_l4_proto   <= pkt_l4_proto_w;
      pkt_bytes      <= pkt_bytes_w;
		pkt_tcp_flags  <= pkt_tcp_flags_w;
      pkt_dst_mac    <= pkt_dst_mac_w;
   end

wire  [ATTRIBUTE_DATA_WIDTH-1:0] w_pkt_attributes;

assign w_pkt_attributes[(PROTO_WIDTH+PROTO_OFFSET)-1:PROTO_OFFSET] 					               = pkt_l4_proto;
assign w_pkt_attributes[(IP_WIDTH+IP_SRC_OFFSET)-1:IP_SRC_OFFSET] 					               = pkt_src_ip;
assign w_pkt_attributes[(IP_WIDTH+IP_DST_OFFSET)-1:IP_DST_OFFSET] 					               = pkt_dst_ip;
assign w_pkt_attributes[(PORT_WIDTH+PORT_SRC_OFFSET)-1:PORT_SRC_OFFSET] 					         = pkt_src_port;
assign w_pkt_attributes[(PORT_WIDTH+PORT_DST_OFFSET)-1:PORT_DST_OFFSET] 					         = pkt_dst_port;
assign w_pkt_attributes[(BYTES_COUNT_WIDTH+BYTES_COUNT_OFFSET)-1:BYTES_COUNT_OFFSET]			   = pkt_bytes;
assign w_pkt_attributes[(`PKT_FLAGS+PKT_FLAGS_OFFSET)-1:PKT_FLAGS_OFFSET] 				            = pkt_flags;
assign w_pkt_attributes[(PRTCL_ID_WIDTH+PRTCL_ID_OFFSET)-1:PRTCL_ID_OFFSET] 				         = `PRIORITY_ETH_IPv4_TCPnUDP;
assign w_pkt_attributes[(NUM_INPUT_QUEUES+NUM_INPUT_QUEUES_OFFSET)-1:NUM_INPUT_QUEUES_OFFSET]	= pkt_input_if;
assign w_pkt_attributes[(TCP_FLAGS_WIDTH+TCP_FLAGS_OFFSET)-1:TCP_FLAGS_OFFSET]             		= pkt_tcp_flags;

assign pkt_attributes = {pkt_dst_mac, w_pkt_attributes[119:0], w_pkt_attributes[142:135]};

endmodule
