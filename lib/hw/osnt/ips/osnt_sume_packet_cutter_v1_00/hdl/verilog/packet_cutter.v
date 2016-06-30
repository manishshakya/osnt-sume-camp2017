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
 *        packet_cutter.v
 *
 *  Author:
 *        Gianni Antichi
 *
 *  Description:
 *        Hardwire the hardware interfaces to CPU and vice versa
 */


	module packet_cutter
	#(
    	//Master AXI Stream Data Width
    		parameter C_M_AXIS_DATA_WIDTH=256,
    		parameter C_S_AXIS_DATA_WIDTH=256,
    		parameter C_M_AXIS_TUSER_WIDTH=128,
    		parameter C_S_AXIS_TUSER_WIDTH=128,
		parameter C_S_AXI_DATA_WIDTH=32,
		parameter HASH_WIDTH=128
	)
	(
    	// Global Ports
    		input axi_aclk,
    		input axi_resetn,

    	// Master Stream Ports (interface to data path)
    		output reg [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    		output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tstrb,
    		output reg [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    		output reg m_axis_tvalid,
    		input  m_axis_tready,
    		output reg m_axis_tlast,

    	// Slave Stream Ports (interface to RX queues)
    		input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    		input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb,
    		input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    		input  s_axis_tvalid,
    		output s_axis_tready,
    		input  s_axis_tlast,
 
    	// pkt cut
    		input cut_en,
    		input [C_S_AXI_DATA_WIDTH-1:0] cut_offset,
    		input [C_S_AXI_DATA_WIDTH-1:0] cut_words,
                input [C_S_AXI_DATA_WIDTH-1:0] cut_bytes
	);


   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

	//--------------------- Internal Parameter-------------------------

   	localparam NUM_STATES               = 5;
   	localparam WAIT_PKT    		    = 1;
   	localparam IN_PACKET                = 2;
   	localparam START_HASH               = 4;
	localparam COMPLETE_PKT		    = 8;
	localparam SEND_LAST_WORD	    = 16;

   	localparam MAX_WORDS_PKT            = 2048;
	localparam HASH_BYTES		    = (HASH_WIDTH)>>3;
	localparam ALL_VALID		    = 32'hffffffff; 

	localparam BYTES_ONE_WORD           = C_M_AXIS_DATA_WIDTH >>3;   
        localparam COUNT_BIT_WIDTH	    = log2(C_M_AXIS_DATA_WIDTH);
        localparam COUNT_BYTE_WIDTH         = COUNT_BIT_WIDTH-3;

	//---------------------- Wires and regs---------------------------

   	reg [C_S_AXI_DATA_WIDTH-1:0]            cut_counter, cut_counter_next;
	reg [C_S_AXI_DATA_WIDTH-1:0]		tstrb_cut,tstrb_cut_next; 

   	reg [NUM_STATES-1:0]			state,state_next;

	wire [C_S_AXIS_TUSER_WIDTH-1:0]         tuser_fifo;
        wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]    tstrb_fifo;
        wire                                    tlast_fifo;
        wire [C_M_AXIS_DATA_WIDTH-1:0]          tdata_fifo;

        reg                                     in_fifo_rd_en;
        wire                                    in_fifo_nearly_full;
        wire                                    in_fifo_empty;

   	wire [C_S_AXI_DATA_WIDTH-1:0]		counter;

	reg					pkt_short,pkt_short_next;

	wire[C_S_AXIS_DATA_WIDTH-1:0]		first_word_hash;
	wire[C_S_AXIS_DATA_WIDTH-1:0]		last_word_hash;
	wire[C_S_AXIS_DATA_WIDTH-1:0]           one_word_hash;
	wire[C_S_AXIS_DATA_WIDTH-1:0]		final_hash;
	
	reg[COUNT_BYTE_WIDTH-1:0]		last_word_bytes_free;
	reg[COUNT_BIT_WIDTH-1:0]		pkt_boundaries_bits_free;			

	reg[COUNT_BYTE_WIDTH-1:0]	        bytes_free,bytes_free_next;
        reg[COUNT_BIT_WIDTH-1:0]                bits_free,bits_free_next;
	reg[COUNT_BYTE_WIDTH-1:0]		hash_carry_bytes,hash_carry_bytes_next;
	reg[COUNT_BIT_WIDTH-1:0]		hash_carry_bits,hash_carry_bits_next;

	reg [C_S_AXIS_DATA_WIDTH-1:0]		hash;
	reg [C_S_AXIS_DATA_WIDTH-1:0]           hash_next;

	reg [C_S_AXIS_DATA_WIDTH-1:0]		last_word_pkt_temp,last_word_pkt_temp_next;
	wire[C_S_AXIS_DATA_WIDTH-1:0]		last_word_pkt_temp_cleaned;

        wire[15:0]				len_pkt_cut;
	wire					pkt_cuttable;
        wire[15:0]				pkt_len;

   //------------------------- Modules-------------------------------


        fallthrough_small_fifo
        #(
                .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
                .MAX_DEPTH_BITS(3)
        )
        pkt_fifo
        (       .din ({s_axis_tlast, s_axis_tuser, s_axis_tstrb, s_axis_tdata}),     // Data in
                .wr_en (s_axis_tvalid & ~in_fifo_nearly_full),               // Write enable
                .rd_en (in_fifo_rd_en),       // Read the next word
                .dout ({tlast_fifo, tuser_fifo, tstrb_fifo, tdata_fifo}),
                .full (),
                .prog_full (),
                .nearly_full (in_fifo_nearly_full),
                .empty (in_fifo_empty),
                .reset (~axi_resetn),
                .clk (axi_aclk));


        assign s_axis_tready = !in_fifo_nearly_full;

	assign counter = (cut_en) ? cut_words : MAX_WORDS_PKT;
 
        assign len_pkt_cut = cut_bytes + HASH_BYTES;
	assign pkt_cuttable = (tuser_fifo[15:0] > len_pkt_cut);
	assign pkt_len = (cut_en & pkt_cuttable) ? len_pkt_cut : tuser_fifo[15:0];
	 
	assign first_word_hash = (~(({C_S_AXIS_DATA_WIDTH{1'b1}}<<bits_free))&tdata_fifo);
        assign last_word_hash  = (({C_S_AXIS_DATA_WIDTH{1'b1}}<<pkt_boundaries_bits_free)&tdata_fifo);

	assign last_word_pkt_temp_cleaned = (({C_S_AXIS_DATA_WIDTH{1'b1}}<<bits_free)&last_word_pkt_temp);

	assign one_word_hash   = ((~({C_S_AXIS_DATA_WIDTH{1'b1}}<<bits_free))&({C_S_AXIS_DATA_WIDTH{1'b1}}<<pkt_boundaries_bits_free)&tdata_fifo);
        assign final_hash      = {{HASH_WIDTH{1'b0}},hash[HASH_WIDTH-1:0]^hash[(2*HASH_WIDTH)-1:HASH_WIDTH]};
	//assign final_hash      = 128'hdeadbeefaccafeafddddeaeaccffadad; //DEBUG fixed value

        always @(*) begin
                pkt_boundaries_bits_free = 0;
                case(tstrb_fifo)
                        32'h8000_0000:   pkt_boundaries_bits_free = 8'd248;
                        32'hc000_0000:   pkt_boundaries_bits_free = 8'd240;
                        32'he000_0000:   pkt_boundaries_bits_free = 8'd232;
                        32'hf000_0000:   pkt_boundaries_bits_free = 8'd224;
                        32'hf800_0000:   pkt_boundaries_bits_free = 8'd216;
                        32'hfc00_0000:   pkt_boundaries_bits_free = 8'd208;
                        32'hfe00_0000:   pkt_boundaries_bits_free = 8'd200;
                        32'hff00_0000:   pkt_boundaries_bits_free = 8'd192;
                        32'hff80_0000:   pkt_boundaries_bits_free = 8'd184;
                        32'hffc0_0000:   pkt_boundaries_bits_free = 8'd176;
                        32'hffe0_0000:   pkt_boundaries_bits_free = 8'd168;
                        32'hfff0_0000:   pkt_boundaries_bits_free = 8'd160;
                        32'hfff8_0000:   pkt_boundaries_bits_free = 8'd152;
                        32'hfffc_0000:   pkt_boundaries_bits_free = 8'd144;
                        32'hfffe_0000:   pkt_boundaries_bits_free = 8'd136;
                        32'hffff_0000:   pkt_boundaries_bits_free = 8'd128;
                        32'hffff_8000:   pkt_boundaries_bits_free = 8'd120;
                        32'hffff_c000:   pkt_boundaries_bits_free = 8'd112;
                        32'hffff_e000:   pkt_boundaries_bits_free = 8'd104;
                        32'hffff_f000:   pkt_boundaries_bits_free = 8'd96;
                        32'hffff_f800:   pkt_boundaries_bits_free = 8'd88;
                        32'hffff_fc00:   pkt_boundaries_bits_free = 8'd80;
                        32'hffff_fe00:   pkt_boundaries_bits_free = 8'd72;
                        32'hffff_ff00:   pkt_boundaries_bits_free = 8'd64;
                        32'hffff_ff80:   pkt_boundaries_bits_free = 8'd56;
                        32'hffff_ffc0:   pkt_boundaries_bits_free = 8'd48;
                        32'hffff_ffe0:   pkt_boundaries_bits_free = 8'd40;
                        32'hffff_fff0:   pkt_boundaries_bits_free = 8'd32;
                        32'hffff_fff8:   pkt_boundaries_bits_free = 8'd24;
                        32'hffff_fffc:   pkt_boundaries_bits_free = 8'd16;
                        32'hffff_fffe:   pkt_boundaries_bits_free = 8'd8;
                        32'hffff_ffff:   pkt_boundaries_bits_free = 8'd0;
                        default      :   pkt_boundaries_bits_free = 8'd0;
                endcase
        end

        always @(*) begin
        	last_word_bytes_free = 0;
        	case(cut_offset)
                	32'h8000_0000:   last_word_bytes_free = 5'd31;
                        32'hc000_0000:   last_word_bytes_free = 5'd30;
                        32'he000_0000:   last_word_bytes_free = 5'd29;
                        32'hf000_0000:   last_word_bytes_free = 5'd28;
                        32'hf800_0000:   last_word_bytes_free = 5'd27;
                        32'hfc00_0000:   last_word_bytes_free = 5'd26;
                        32'hfe00_0000:   last_word_bytes_free = 5'd25;
                        32'hff00_0000:   last_word_bytes_free = 5'd24;
                        32'hff80_0000:   last_word_bytes_free = 5'd23;
                        32'hffc0_0000:   last_word_bytes_free = 5'd22;
                        32'hffe0_0000:   last_word_bytes_free = 5'd21;
                        32'hfff0_0000:   last_word_bytes_free = 5'd20;
                        32'hfff8_0000:   last_word_bytes_free = 5'd19;
                        32'hfffc_0000:   last_word_bytes_free = 5'd18;
                        32'hfffe_0000:   last_word_bytes_free = 5'd17;
                        32'hffff_0000:   last_word_bytes_free = 5'd16;
                        32'hffff_8000:   last_word_bytes_free = 5'd15;
                        32'hffff_c000:   last_word_bytes_free = 5'd14;
                        32'hffff_e000:   last_word_bytes_free = 5'd13;
                        32'hffff_f000:   last_word_bytes_free = 5'd12;
                        32'hffff_f800:   last_word_bytes_free = 5'd11;
                        32'hffff_fc00:   last_word_bytes_free = 5'd10;
                        32'hffff_fe00:   last_word_bytes_free = 5'd9;
                        32'hffff_ff00:   last_word_bytes_free = 5'd8;
                        32'hffff_ff80:   last_word_bytes_free = 5'd7;
                        32'hffff_ffc0:   last_word_bytes_free = 5'd6;
                        32'hffff_ffe0:   last_word_bytes_free = 5'd5;
                        32'hffff_fff0:   last_word_bytes_free = 5'd4;
                        32'hffff_fff8:   last_word_bytes_free = 5'd3;
                        32'hffff_fffc:   last_word_bytes_free = 5'd2;
                        32'hffff_fffe:   last_word_bytes_free = 5'd1;
                        32'hffff_ffff:   last_word_bytes_free = 5'd0;
                	default	     :   last_word_bytes_free = 5'd0;
        	endcase
   	end

	always @(*) begin
      		m_axis_tuser = tuser_fifo;
      		m_axis_tstrb = tstrb_fifo;
      		m_axis_tlast = tlast_fifo;
      		m_axis_tdata = tdata_fifo;
      		m_axis_tvalid = 0;
   
      		in_fifo_rd_en = 0;
      
		state_next = state;
      		
		cut_counter_next = cut_counter;
		tstrb_cut_next = tstrb_cut;

		bytes_free_next = bytes_free;
		bits_free_next = bits_free;
		hash_carry_bytes_next = hash_carry_bytes;
                hash_carry_bits_next = hash_carry_bits;

		pkt_short_next = pkt_short;

		hash_next = hash;

		last_word_pkt_temp_next = last_word_pkt_temp;

      	case(state)
        
	WAIT_PKT: begin
                cut_counter_next = counter;
                tstrb_cut_next = cut_offset;
        	if(!in_fifo_empty) begin
                	m_axis_tvalid = 1;
			m_axis_tuser[15:0] = pkt_len;
			if(!pkt_cuttable)
				pkt_short_next = 1;
			else begin
				pkt_short_next = 0;
			end
			bytes_free_next = last_word_bytes_free;
			bits_free_next = (last_word_bytes_free<<3);
			if(m_axis_tready) begin
				in_fifo_rd_en = 1;
				state_next = IN_PACKET;
			end
           	end
        end

        IN_PACKET: begin
        	if(!in_fifo_empty) begin
			if(!cut_counter) begin
				if(tlast_fifo) begin
					if(pkt_short) begin
						m_axis_tvalid = 1;
						if(m_axis_tready) begin
							in_fifo_rd_en = 1;
                                                	state_next = WAIT_PKT;
						end
					end
					else begin
						last_word_pkt_temp_next = tdata_fifo;
						hash_next = one_word_hash;
						state_next = COMPLETE_PKT;
					end
				end
				else begin
					last_word_pkt_temp_next = tdata_fifo;
					hash_next = first_word_hash;
					in_fifo_rd_en = 1;
					state_next = START_HASH;	
				end
			end
			else begin
				m_axis_tvalid = 1;
				if(m_axis_tready) begin
					in_fifo_rd_en = 1;
					if(tlast_fifo)
						state_next = WAIT_PKT;
					else
						cut_counter_next = cut_counter-1;
				end
			end
		end
	end

	
	START_HASH: begin
		if(tlast_fifo) begin 
			hash_next = hash ^ last_word_hash;
			state_next = COMPLETE_PKT;
		end
		else begin
			if(!in_fifo_empty) begin
				in_fifo_rd_en = 1;
				hash_next = hash ^ tdata_fifo;
			end
		end
	end

	COMPLETE_PKT: begin
		m_axis_tvalid = 1;
		if(m_axis_tready) begin
			in_fifo_rd_en = 1;
			if(bytes_free < HASH_BYTES) begin
				m_axis_tstrb = ALL_VALID;
				hash_carry_bytes_next = HASH_BYTES[COUNT_BYTE_WIDTH-1:0] - bytes_free;
                                hash_carry_bits_next = (HASH_BYTES[COUNT_BYTE_WIDTH-1:0] - bytes_free)<<3;
				m_axis_tlast = 0;
				m_axis_tdata = (last_word_pkt_temp_cleaned | (final_hash >> (HASH_WIDTH-bits_free)));
				state_next = SEND_LAST_WORD;
			end
			else begin
				m_axis_tlast = 1;
				m_axis_tdata = (last_word_pkt_temp_cleaned | (final_hash << (bits_free-HASH_WIDTH)));
				m_axis_tstrb = (ALL_VALID<<(bytes_free-HASH_BYTES));
				state_next = WAIT_PKT;
			end
		end
	end
	
	SEND_LAST_WORD: begin
		m_axis_tvalid = 1;
		if(m_axis_tready) begin
			m_axis_tlast = 1;
			m_axis_tdata = (final_hash)<<(C_S_AXIS_DATA_WIDTH-hash_carry_bits);
			m_axis_tstrb = (ALL_VALID<<(BYTES_ONE_WORD[COUNT_BYTE_WIDTH-1:0]-hash_carry_bytes));
			state_next = WAIT_PKT;
		end
	end

	endcase // case(state)
	end // always @ (*)


	always @(posedge axi_aclk) begin
      		if(~axi_resetn) begin
         		state 		<= WAIT_PKT;
         		cut_counter	<= 0;
			tstrb_cut	<= 0;
                        bytes_free 	<= 0;
                        bits_free 	<= 0;
                        hash_carry_bytes<= 0;
                        hash_carry_bits <= 0;
                        hash 		<= 0;
			pkt_short       <= 0;
			last_word_pkt_temp<=0;
      		end
      		else begin
         		state <= state_next;

                	bytes_free <= bytes_free_next;
                	bits_free <= bits_free_next;
                	hash_carry_bytes <= hash_carry_bytes_next;
                	hash_carry_bits <= hash_carry_bits_next;

			pkt_short    <= pkt_short_next;

                	hash <= hash_next;
			
         		cut_counter <= cut_counter_next;
			tstrb_cut <= tstrb_cut_next;

			last_word_pkt_temp <= last_word_pkt_temp_next;
      		end
   	end
	endmodule // output_port_lookup

