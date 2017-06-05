//
// Copyright (c) 2017 University of Cambridge
// Copyright (c) 2017 Jong Hun Han
// All rights reserved
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

`timescale 1ps/1ps

module ddr_if_controller
#(
   parameter   C_S_AXI_DATA_WIDTH      = 32,
   parameter   C_S_AXI_ADDR_WIDTH      = 32,

   parameter   C_M_AXIS_TDATA_WIDTH    = 512,
   parameter   C_M_AXIS_TUSER_WIDTH    = 128
)
(
   input                                                 clk,
   input                                                 rst_clk,

   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   input          [C_M_AXIS_TDATA_WIDTH-1:0]             b2m_fifo_out_data,
   input                                                 b2m_fifo_empty,
   output   reg                                          b2m_fifo_rd_en,

   input                                                 s_conv_m2b_tready,

   input                                                 sw_rst,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             replay_count,
   input                                                 start_replay,
   input                                                 wr_done,

   output   reg   [29:0]                                 app_addr_i,
   output   reg   [2:0]                                  app_cmd_i, // read;001, write;000
   output   reg                                          app_en_i,
   output   reg   [511:0]                                app_wdf_data_i,
   output   reg                                          app_wdf_end_i,
   output   reg   [63:0]                                 app_wdf_mask_i,
   output   reg                                          app_wdf_wren_i,

   input                                                 app_wdf_rdy_o,
   input          [511:0]                                app_rd_data_o,
   input                                                 app_rd_data_end_o,
   input                                                 app_rd_data_valid_o,
   input                                                 app_rdy_o,
   input                                                 init_calib_complete_o,
   
   output                                                app_ref_req_i,
   input                                                 app_ref_ack_o,

   input          [C_S_AXI_ADDR_WIDTH-1:0]               Bus2IP_Addr,
   input          [0:0]                                  Bus2IP_CS,
   input                                                 Bus2IP_RNW, // 0: wr, 1: rd
   input          [C_S_AXI_DATA_WIDTH-1:0]               Bus2IP_Data,
   input          [C_S_AXI_DATA_WIDTH/8-1:0]             Bus2IP_BE,

   output   reg   [C_S_AXI_DATA_WIDTH-1:0]               IP2Bus_Data,
   output   reg                                          IP2Bus_RdAck,
   output   reg                                          IP2Bus_WrAck,

   output                                                st_valid
);

`define  IDLE              0

`define  BUS_WR            1
`define  BUS_WR_DONE       2
`define  BUS_WR_WAIT       3
`define  BUS_RD            4
`define  BUS_RD_DONE       5
`define  BUS_RD_WAIT       6

`define  AXIS_BUS_WR       1
`define  AXIS_BUS_WR_WAIT  2
`define  AXIS_BUS_RD       3
`define  AXIS_BUS_RD_WAIT  4
`define  AXIS_WR_0         5
`define  AXIS_WR_CHECK_0   6
`define  AXIS_WR_VALID_0   7
`define  AXIS_WR_1         8
`define  AXIS_WR_CHECK_1   9
`define  AXIS_WR_VALID_1   10
`define  AXIS_WR_2         11
`define  AXIS_WR_CHECK_2   12
`define  AXIS_WR_VALID_2   13
`define  AXIS_WR_3         14
`define  AXIS_WR_CHECK_3   15
`define  AXIS_WR_VALID_3   16
`define  AXIS_RD           17
`define  AXIS_RD_WAIT      18

`define  CTRL_STATUS       16'h0000
`define  PKT_CNT_NO        16'h0004
`define  PKT_END_ADDR      16'h0008
`define  BUS_MEM_ADDR      16'h000c
`define  WR_MEM_DATA       16'h0020
`define  RD_MEM_DATA       16'h0040

wire   resetn = ~rst_clk;

reg   [26:0]   wr_mem_addr, wr_mem_addr_next;
reg   [26:0]   rd_mem_addr, rd_mem_addr_next;
reg   [26:0]   wr_end_addr;

reg   [C_S_AXI_ADDR_WIDTH-1:0]   replay_no, replay_no_next;

wire  wr_bus2mem_en, rd_mem2bus_en;
wire  [511:0]  wdf_data;

reg   [C_S_AXI_ADDR_WIDTH-1:0]   r_replay_count;
reg   [2:0] r_start_replay, r_wr_done, r_sw_rst;

wire  w_m_conv_b2m_tlast;
reg   sw_rst_ff;
reg   [31:0]   bus2mem_addr;
reg   [3:0]    st_bus_current, st_bus_next;
reg   [4:0]    st_axis_current, st_axis_next;
reg   r_clear;
reg   r_m_conv_b2m_tlast;
reg   [31:0]   pkt_cnt;

assign st_valid = (st_bus_current != `BUS_RD_DONE) &
                  (st_axis_current != `AXIS_WR_0) &
                  (st_axis_current != `AXIS_WR_1) &
                  (st_axis_current != `AXIS_WR_2) &
                  (st_axis_current != `AXIS_WR_3) &
                  (st_axis_current != `AXIS_WR_CHECK_0) & (st_axis_current != `AXIS_WR_VALID_0) &
                  (st_axis_current != `AXIS_WR_CHECK_1) & (st_axis_current != `AXIS_WR_VALID_1) &
                  (st_axis_current != `AXIS_WR_CHECK_2) & (st_axis_current != `AXIS_WR_VALID_2) &
                  (st_axis_current != `AXIS_WR_CHECK_3) & (st_axis_current != `AXIS_WR_VALID_3);

reg   r_app_rd_valid_1, r_app_rd_valid_2;
reg   [511:0]  r_app_rd_data;
always @(posedge clk)
   if (rst_clk) begin
      r_app_rd_valid_1  <= 0;
      r_app_rd_valid_2  <= 0;
   end
   else begin
      r_app_rd_valid_1  <= app_rd_data_valid_o;
      r_app_rd_valid_2  <= r_app_rd_valid_1;
   end

always @(posedge clk)
   if (rst_clk)
      r_app_rd_data  <= 0;
   else if (app_rd_data_valid_o)
      r_app_rd_data  <= app_rd_data_o;


always @(posedge clk)
   if (rst_clk) begin
      r_start_replay    <= 0;
      r_wr_done         <= 0;
      r_sw_rst          <= 0;
   end
   else begin
      r_start_replay    <= {r_start_replay[1:0], start_replay};
      r_wr_done         <= {r_wr_done[1:0], wr_done};
      r_sw_rst          <= {r_sw_rst[1:0], sw_rst};
   end

wire en_start_replay = r_start_replay[1] & ~r_start_replay[2];
wire en_wr_done = r_wr_done[1] & ~r_wr_done[2];
wire en_sw_rst0 = r_sw_rst[1]  & ~r_sw_rst[2];
wire en_sw_rst1 = ~r_sw_rst[1] & r_sw_rst[2];

always @(posedge clk)
   if (rst_clk)
      r_replay_count <= 0;
   else if (en_sw_rst0)
      r_replay_count <= 0;
   else if (en_start_replay)
      r_replay_count <= replay_count;

always @(posedge clk)
   if (rst_clk)
      sw_rst_ff   <= 0;
   else if (en_sw_rst0)
      sw_rst_ff   <= 1;
   else if (en_sw_rst1)
      sw_rst_ff   <= 0;

always @(posedge clk)
   if (rst_clk)
      bus2mem_addr   <= 0;
   else if ((Bus2IP_Addr[15:0] == `BUS_MEM_ADDR) & Bus2IP_CS & ~Bus2IP_RNW)
      bus2mem_addr   <= Bus2IP_Data;

always @(posedge clk)
   if (rst_clk)
      wr_end_addr    <= 0;
   else if ((app_cmd_i == 3'b000) & app_en_i & app_wdf_wren_i)
      wr_end_addr    <= wr_mem_addr;

always @(posedge clk)
   if (rst_clk)
      r_clear  <= 0;
   else if (en_sw_rst0)
      r_clear  <= 1;
   else if (st_bus_current == `IDLE || st_axis_current == `IDLE)
      r_clear  <= 0;

always @(posedge clk)
   if (rst_clk)
      r_m_conv_b2m_tlast   <= 0;
   else
      r_m_conv_b2m_tlast   <= b2m_fifo_out_data[511] & ~b2m_fifo_empty;

assign w_m_conv_b2m_tlast = (b2m_fifo_out_data[511] & ~b2m_fifo_empty) & ~r_m_conv_b2m_tlast;

always @(posedge clk)
   if (rst_clk)
      pkt_cnt     <= 0;
   else if (r_clear || (~b2m_fifo_empty && (st_axis_next == `AXIS_WR_0) && (st_axis_current == `IDLE)))
      pkt_cnt     <= 0;
   else if (w_m_conv_b2m_tlast)
      pkt_cnt     <= pkt_cnt + 1;

always @(posedge clk)
   if (rst_clk) begin
      st_bus_current    <= 0;
      st_axis_current   <= 0;
      replay_no         <= 0;
      wr_mem_addr       <= 0;
      rd_mem_addr       <= 0;
   end
   else begin
      st_bus_current    <= st_bus_next;
      st_axis_current   <= st_axis_next;
      replay_no         <= replay_no_next;
      wr_mem_addr       <= wr_mem_addr_next;
      rd_mem_addr       <= rd_mem_addr_next;
   end

//FSM for bus write and read acces
always @(*) begin
   IP2Bus_WrAck      = 0;
   IP2Bus_RdAck      = 0;
   IP2Bus_Data       = 0;
   st_bus_next       = 0;
   case(st_bus_current)
      `IDLE : begin
         st_bus_next    = (Bus2IP_CS & ~Bus2IP_RNW) ? `BUS_WR  :
                          (Bus2IP_CS &  Bus2IP_RNW) ? `BUS_RD  : `IDLE;
      end
      `BUS_WR : begin
         st_bus_next    = `BUS_WR_DONE;
      end
      `BUS_WR_DONE : begin
         if (wr_bus2mem_en) begin
            IP2Bus_WrAck   = (st_axis_current == `AXIS_BUS_WR_WAIT) ? 1 : 0;
            st_bus_next    = (st_axis_current == `AXIS_BUS_WR_WAIT) ? `BUS_WR_WAIT : `BUS_WR_DONE;
         end
         else begin
            IP2Bus_WrAck   = 1;
            st_bus_next    = `BUS_WR_WAIT;
         end
      end
      `BUS_WR_WAIT : begin
         st_bus_next    = (Bus2IP_CS) ? `BUS_WR_WAIT : `IDLE;
      end
      `BUS_RD : begin
         st_bus_next    = `BUS_RD_DONE;
      end
      `BUS_RD_DONE : begin
         if (rd_mem2bus_en) begin
            IP2Bus_RdAck   = (r_app_rd_valid_2) ? 1 : 0;
            st_bus_next    = (r_app_rd_valid_2) ? `BUS_RD_WAIT : `BUS_RD_DONE;
            case (bus2mem_addr[5:2])
               4'h0 : begin
                  IP2Bus_Data = r_app_rd_data[( 0*32)+:32];
               end
               4'h1 : begin
                  IP2Bus_Data = r_app_rd_data[( 1*32)+:32];
               end
               4'h2 : begin
                  IP2Bus_Data = r_app_rd_data[( 2*32)+:32];
               end
               4'h3 : begin
                  IP2Bus_Data = r_app_rd_data[( 3*32)+:32];
               end
               4'h4 : begin
                  IP2Bus_Data = r_app_rd_data[( 4*32)+:32];
               end
               4'h5 : begin
                  IP2Bus_Data = r_app_rd_data[( 5*32)+:32];
               end
               4'h6 : begin
                  IP2Bus_Data = r_app_rd_data[( 6*32)+:32];
               end
               4'h7 : begin
                  IP2Bus_Data = r_app_rd_data[( 7*32)+:32];
               end
               4'h8 : begin
                  IP2Bus_Data = r_app_rd_data[( 8*32)+:32];
               end
               4'h9 : begin
                  IP2Bus_Data = r_app_rd_data[( 9*32)+:32];
               end
               4'ha : begin
                  IP2Bus_Data = r_app_rd_data[(10*32)+:32];
               end
               4'hb : begin
                  IP2Bus_Data = r_app_rd_data[(11*32)+:32];
               end
               4'hc : begin
                  IP2Bus_Data = r_app_rd_data[(12*32)+:32];
               end
               4'hd : begin
                  IP2Bus_Data = r_app_rd_data[(13*32)+:32];
               end
               4'he : begin
                  IP2Bus_Data = r_app_rd_data[(14*32)+:32];
               end
               4'hf : begin
                  IP2Bus_Data = r_app_rd_data[(15*32)+:32];
               end
            endcase
         end
         else begin
            IP2Bus_RdAck   = 1;
            st_bus_next    = `BUS_RD_WAIT;
            case(Bus2IP_Addr[15:0])
               `CTRL_STATUS  : IP2Bus_Data = {28'b0, app_wdf_rdy_o, app_rdy_o, b2m_fifo_empty, init_calib_complete_o};
               `PKT_CNT_NO   : IP2Bus_Data = pkt_cnt;
               `PKT_END_ADDR : IP2Bus_Data = wr_end_addr;
               `BUS_MEM_ADDR : IP2Bus_Data = bus2mem_addr;
            endcase
         end
      end
      `BUS_RD_WAIT : begin
         st_bus_next    = (Bus2IP_CS) ? `BUS_RD_WAIT : `IDLE;
      end
   endcase
end


assign wdf_data = b2m_fifo_out_data;

wire  [511:0]  pattern_0 = {384'h0, {128{1'b1}}};
wire  [511:0]  pattern_1 = {256'h0, {128{1'b1}}, 128'h0};
wire  [511:0]  pattern_2 = {128'h0, {128{1'b1}}, 256'h0};
wire  [511:0]  pattern_3 = {{128{1'b1}}, 384'h0};

assign wr_bus2mem_en = (Bus2IP_Addr[15:0] == `WR_MEM_DATA) & Bus2IP_CS;
assign rd_mem2bus_en = (Bus2IP_Addr[15:0] == `RD_MEM_DATA) & Bus2IP_CS;

// FSM for the stream data control
always @(*) begin
   app_addr_i        = 0;
   app_cmd_i         = 0;
   app_en_i          = 0;
   app_wdf_end_i     = 0;
   app_wdf_wren_i    = 0;
   app_wdf_data_i    = 0;
   app_wdf_mask_i    = {64{1'b1}};
   b2m_fifo_rd_en    = 0;
   rd_mem_addr_next  = 0;
   wr_mem_addr_next  = 0;
   replay_no_next    = 0;
   st_axis_next      = 0;
   case(st_axis_current)
      `IDLE : begin
         st_axis_next      = (wr_bus2mem_en & (st_bus_current == `BUS_WR_DONE)) ? `AXIS_BUS_WR  :
                             (rd_mem2bus_en & (st_bus_current == `BUS_RD_DONE)) ? `AXIS_BUS_RD  :
                             (~b2m_fifo_empty)                                  ? `AXIS_WR_0    :
                             (en_start_replay && ~sw_rst_ff)                    ? `AXIS_RD      : `IDLE;
      end
      `AXIS_BUS_WR : begin
         st_axis_next      = (app_wdf_rdy_o) ? `AXIS_BUS_WR_WAIT : `AXIS_BUS_WR;
         // 0000 1000
         // 0100 0000
         app_addr_i        = {1'b0, bus2mem_addr[31:6], 3'b0};
         app_cmd_i         = 3'b000;
         app_en_i          = 1;
         app_wdf_end_i     = 1;
         app_wdf_wren_i    = 1;
         case (bus2mem_addr[5:2])
            4'h0 : begin
               app_wdf_data_i[( 0*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 0*4)+:4]   = 4'h0;
            end
            4'h1 : begin
               app_wdf_data_i[( 1*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 1*4)+:4]   = 4'h0;
            end
            4'h2 : begin
               app_wdf_data_i[( 2*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 2*4)+:4]   = 4'h0;
            end
            4'h3 : begin
               app_wdf_data_i[( 3*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 3*4)+:4]   = 4'h0;
            end
            4'h4 : begin
               app_wdf_data_i[( 4*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 4*4)+:4]   = 4'h0;
            end
            4'h5 : begin
               app_wdf_data_i[( 5*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 5*4)+:4]   = 4'h0;
            end
            4'h6 : begin
               app_wdf_data_i[( 6*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 6*4)+:4]   = 4'h0;
            end
            4'h7 : begin
               app_wdf_data_i[( 7*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 7*4)+:4]   = 4'h0;
            end
            4'h8 : begin
               app_wdf_data_i[( 8*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 8*4)+:4]   = 4'h0;
            end
            4'h9 : begin
               app_wdf_data_i[( 9*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[( 9*4)+:4]   = 4'h0;
            end
            4'ha : begin
               app_wdf_data_i[(10*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[(10*4)+:4]   = 4'h0;
            end
            4'hb : begin
               app_wdf_data_i[(11*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[(11*4)+:4]   = 4'h0;
            end
            4'hc : begin
               app_wdf_data_i[(12*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[(12*4)+:4]   = 4'h0;
            end
            4'hd : begin
               app_wdf_data_i[(13*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[(13*4)+:4]   = 4'h0;
            end
            4'he : begin
               app_wdf_data_i[(14*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[(14*4)+:4]   = 4'h0;
            end
            4'hf : begin
               app_wdf_data_i[(15*32)+:32] = Bus2IP_Data;
               app_wdf_mask_i[(15*4)+:4]   = 4'h0;
            end
         endcase
      end
      `AXIS_BUS_WR_WAIT : begin
         st_axis_next      = (st_bus_current == `IDLE) ? `IDLE : `AXIS_BUS_WR_WAIT;
      end
      `AXIS_BUS_RD : begin
         app_addr_i        = {1'b0, bus2mem_addr[31:6], 3'b0};
         app_cmd_i         = 3'b001;
         app_en_i          = 1;
         st_axis_next      = (app_rdy_o) ? `AXIS_BUS_RD_WAIT : `AXIS_BUS_RD;
      end
      `AXIS_BUS_RD_WAIT : begin
         st_axis_next      = (st_bus_current == `IDLE) ? `IDLE : `AXIS_BUS_RD_WAIT;
      end
      `AXIS_WR_0 : begin
         if (~b2m_fifo_empty) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b000;
            app_en_i          = 1;
            app_wdf_end_i     = 1;
            app_wdf_wren_i    = 1;
            app_wdf_data_i    = wdf_data;
            app_wdf_mask_i    = {{48{1'b1}}, 16'h0};
            wr_mem_addr_next  = wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (app_wdf_rdy_o) ? `AXIS_WR_CHECK_0 : `AXIS_WR_0;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0     : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_0;
         end
      end
      `AXIS_WR_CHECK_0 : begin
         if (app_rdy_o) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_0;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_CHECK_0;
         end
      end
      `AXIS_WR_VALID_0 : begin
         if (app_rd_data_valid_o) begin
            if ((app_rd_data_o & pattern_0) == (wdf_data & pattern_0)) begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_1;
            end
            else begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_0;
            end
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_0;
         end
      end
      `AXIS_WR_1 : begin
         if (~b2m_fifo_empty) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b000;
            app_en_i          = 1;
            app_wdf_end_i     = 1;
            app_wdf_wren_i    = 1;
            app_wdf_data_i    = wdf_data;
            app_wdf_mask_i    = {{32{1'b1}}, 16'h0, {16{1'b1}}};
            wr_mem_addr_next  = wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (app_wdf_rdy_o) ? `AXIS_WR_CHECK_1 : `AXIS_WR_1;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0     : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_1;
         end
      end
      `AXIS_WR_CHECK_1 : begin
         if (app_rdy_o) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_1;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_CHECK_1;
         end
      end
      `AXIS_WR_VALID_1 : begin
         if (app_rd_data_valid_o) begin
            if ((app_rd_data_o & pattern_1) == (wdf_data & pattern_1)) begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_2;
            end
            else begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_1;
            end
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_1;
         end
      end
      `AXIS_WR_2 : begin
         if (~b2m_fifo_empty) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b000;
            app_en_i          = 1;
            app_wdf_end_i     = 1;
            app_wdf_wren_i    = 1;
            app_wdf_data_i    = wdf_data;
            app_wdf_mask_i    = {{16{1'b1}}, 16'h0, {32{1'b1}}};
            wr_mem_addr_next  = wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (app_wdf_rdy_o) ? `AXIS_WR_CHECK_2 : `AXIS_WR_2;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0     : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_2;
         end
      end
      `AXIS_WR_CHECK_2 : begin
         if (app_rdy_o) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_2;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_CHECK_2;
         end
      end
      `AXIS_WR_VALID_2 : begin
         if (app_rd_data_valid_o) begin
            if ((app_rd_data_o & pattern_2) == (wdf_data & pattern_2)) begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_3;
            end
            else begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_2;
            end
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_2;
         end
      end
      `AXIS_WR_3 : begin
         if (~b2m_fifo_empty) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b000;
            app_en_i          = 1;
            app_wdf_end_i     = 1;
            app_wdf_wren_i    = 1;
            app_wdf_data_i    = wdf_data;
            app_wdf_mask_i    = {16'h0, {48{1'b1}}};
            wr_mem_addr_next  = wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (app_wdf_rdy_o) ? `AXIS_WR_CHECK_3 : `AXIS_WR_3;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0     : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_3;
         end
      end
      `AXIS_WR_CHECK_3 : begin
         if (app_rdy_o) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_3;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_CHECK_3;
         end
      end
      `AXIS_WR_VALID_3 : begin
         if (app_rd_data_valid_o) begin
            if ((app_rd_data_o & pattern_3) == (wdf_data & pattern_3)) begin
               b2m_fifo_rd_en    = 1;
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr+1;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_0;
            end
            else begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_3;
            end
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_VALID_3;
         end
      end
      `AXIS_RD : begin
         if (s_conv_m2b_tready & app_rdy_o) begin
            app_addr_i        = {rd_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            rd_mem_addr_next  = rd_mem_addr + 1;
            replay_no_next    = (rd_mem_addr == wr_end_addr) ? replay_no + 1 : replay_no;
            st_axis_next      = (r_clear) ? `IDLE : (rd_mem_addr == wr_end_addr) ? `AXIS_RD_WAIT : `AXIS_RD;
         end
         else begin
            rd_mem_addr_next  = rd_mem_addr;
            replay_no_next    = replay_no;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_RD;
         end
      end
      `AXIS_RD_WAIT : begin
         rd_mem_addr_next  = 0;
         replay_no_next    = replay_no;
         st_axis_next      = (r_clear) ? `IDLE : (replay_no < r_replay_count) ? `AXIS_RD : `IDLE;
      end
   endcase
end

endmodule
