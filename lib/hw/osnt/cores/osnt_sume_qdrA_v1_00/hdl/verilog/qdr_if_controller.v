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

module qdr_if_controller
#(
   parameter   C_S_AXI_DATA_WIDTH      = 32,          
   parameter   C_S_AXI_ADDR_WIDTH      = 32,          

   parameter   C_M_AXIS_TDATA_WIDTH    = 256,
   parameter   C_M_AXIS_TUSER_WIDTH    = 128,
   parameter   C_S_AXIS_TDATA_WIDTH    = 256,
   parameter   C_S_AXIS_TUSER_WIDTH    = 128 
)
(
   input                                                 clk,
   input                                                 rst_clk,

   output   reg                                          app_wr_cmd_i,
   output   reg   [18:0]                                 app_wr_addr_i,
   output   reg   [143:0]                                app_wr_data_i,
   output   reg   [15:0]                                 app_wr_bw_n_i, // default : 1
   output   reg                                          app_rd_cmd_i,
   output   reg   [18:0]                                 app_rd_addr_i,

   input                                                 app_rd_valid_o,
   output                                                mem_wr_en,
   input          [143:0]                                app_rd_data_o,
   input                                                 init_calib_complete_o,

   input          [C_S_AXI_ADDR_WIDTH-1:0]               Bus2IP_Addr,
   input          [0:0]                                  Bus2IP_CS,
   input                                                 Bus2IP_RNW, // 0: wr, 1: rd
   input          [C_S_AXI_DATA_WIDTH-1:0]               Bus2IP_Data,
   input          [C_S_AXI_DATA_WIDTH/8-1:0]             Bus2IP_BE,
   output   reg   [C_S_AXI_DATA_WIDTH-1:0]               IP2Bus_Data,
   output   reg                                          IP2Bus_RdAck,
   output   reg                                          IP2Bus_WrAck,

   input          [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         m_conv_b2m_tdata,
   input          [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     m_conv_b2m_tkeep,
   input          [C_M_AXIS_TUSER_WIDTH-1:0]             m_conv_b2m_tuser,
   input                                                 m_conv_b2m_tvalid,
   output   reg                                          m_conv_b2m_tready,
   input                                                 m_conv_b2m_tlast,

   input                                                 s_async_tready,
 
   input                                                 mem_data_empty,
   input                                                 mem_data_full,
   output   reg                                          mem_data_rd,
   input          [143:0]                                mem_data_out,

   output   reg                                          fifo_tvalid,

   output   reg   [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         fifo_in_tdata,
   output   reg   [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     fifo_in_tkeep,
   output   reg   [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_in_tuser,
   output   reg                                          fifo_in_tlast,

   input                                                 sw_rst,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             replay_count,
   input                                                 start_replay,
   input                                                 wr_done
);

`define  IDLE              0

`define  BUS_WR            1
`define  BUS_WR_DONE       2
`define  BUS_WR_WAIT       3
`define  BUS_RD            4
`define  BUS_RD_DLY1       5
`define  BUS_RD_DLY2       6
`define  BUS_RD_DONE       7
`define  BUS_RD_WAIT       8

`define  AXIS_BUS_WR       1
`define  AXIS_BUS_WR_WAIT  2
`define  AXIS_BUS_RD       3
`define  AXIS_BUS_RD_WAIT  4
`define  AXIS_WR_TUSER     5
`define  AXIS_WR           6
`define  AXIS_RD           7
`define  AXIS_RD_WAIT      8
`define  AXIS_WR_FLUSH     9

`define  CTRL_STATUS       16'h0000
`define  PKT_CNT_NO        16'h0004
`define  PKT_END_ADDR      16'h0008
`define  BUS_MEM_ADDR      16'h000c
`define  WR_MEM_DATA       16'h0020
`define  RD_MEM_DATA       16'h0040

reg   [18:0]                                 wr_mem_addr, wr_mem_addr_next;
reg   [18:0]                                 rd_mem_addr, rd_mem_addr_next;
reg   [18:0]   wr_end_addr;

wire  bus2mem_addr_en, end_addr_rd_en, calib_rd_en, wr_pkt_rd_en, wr_bus2mem_en, rd_mem2bus_en;

reg   [C_S_AXI_ADDR_WIDTH-1:0]      replay_no, replay_no_next;

reg   [C_S_AXIS_TUSER_WIDTH-1:0]             m2b_tuser, m2b_tuser_next;
reg   [((C_S_AXIS_TDATA_WIDTH/8)/2)-1:0]     m2b_tkeep;

reg   [C_S_AXI_ADDR_WIDTH-1 : 0]             r_replay_count;
reg   [2:0]    r_start_replay, r_wr_done, r_sw_rst;
reg   [4:0]    no_tkeep;
reg   sw_rst_ff;
reg   [3:0]    st_bus_current, st_bus_next;
reg   [3:0]    st_axis_current, st_axis_next;
reg   r_clear;
reg   [31:0]   pkt_cnt;
reg   [18+4:0] bus2mem_addr;

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
wire en_sw_rst0 = r_sw_rst[1] & ~r_sw_rst[2];
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

always @(m_conv_b2m_tkeep or m_conv_b2m_tdata or m_conv_b2m_tuser or m_conv_b2m_tvalid or m_conv_b2m_tlast) begin
   no_tkeep = 0;
   case (m_conv_b2m_tkeep)
      16'h0001 : no_tkeep = 1;
      16'h0003 : no_tkeep = 2;
      16'h0007 : no_tkeep = 3;
      16'h000f : no_tkeep = 4;
      16'h001f : no_tkeep = 5;
      16'h003f : no_tkeep = 6;
      16'h007f : no_tkeep = 7;
      16'h00ff : no_tkeep = 8;
      16'h01ff : no_tkeep = 9;
      16'h03ff : no_tkeep = 10;
      16'h07ff : no_tkeep = 11;
      16'h0fff : no_tkeep = 12;
      16'h1fff : no_tkeep = 13;
      16'h3fff : no_tkeep = 14;
      16'h7fff : no_tkeep = 15;
      16'hffff : no_tkeep = 16;
   endcase
end
   
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

reg   [143:0]  r_app_rd_data;
always @(posedge clk)
   if (rst_clk)
      r_app_rd_data  <= 0;
   else if (app_rd_valid_o)
      r_app_rd_data  <= app_rd_data_o;

always @(posedge clk)
   if (rst_clk)
      wr_end_addr    <= 0;
   else if (app_wr_cmd_i)
      wr_end_addr    <= app_wr_addr_i;

always @(posedge clk)
   if (rst_clk)
      r_clear  <= 0;
   else if (en_sw_rst0)
      r_clear  <= 1;
   else if (st_axis_current == `IDLE)
      r_clear  <= 0;

always @(posedge clk)
   if (rst_clk)
      pkt_cnt  <= 0;
   else if (r_clear)
      pkt_cnt  <= 0;
   else if (app_wr_cmd_i && (app_wr_data_i[143:133] == 11'h004))
      pkt_cnt  <= pkt_cnt + 1;

assign wr_bus2mem_en = (Bus2IP_Addr[15:0] == `WR_MEM_DATA) & Bus2IP_CS;
assign rd_mem2bus_en = (Bus2IP_Addr[15:0] == `RD_MEM_DATA) & Bus2IP_CS;

always @(posedge clk)
   if (rst_clk)
      bus2mem_addr   <= 0;
   else if ((Bus2IP_Addr[15:0] == `BUS_MEM_ADDR) & Bus2IP_CS & ~Bus2IP_RNW)
      bus2mem_addr   <= Bus2IP_Data[18+4:0];

assign mem_wr_en = (st_bus_current != `BUS_RD_DONE) && (st_bus_current != `BUS_RD_DLY1) && (st_bus_current != `BUS_RD_DLY2);

always @(*) begin
   IP2Bus_WrAck      = 0;
   IP2Bus_RdAck      = 0;
   IP2Bus_Data       = 0;
   st_bus_next       = 0;
   case(st_bus_current)
      `IDLE : begin
         st_bus_next    = (Bus2IP_CS & ~Bus2IP_RNW) ? `BUS_WR :
                          (Bus2IP_CS &  Bus2IP_RNW) ? `BUS_RD : `IDLE;
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
         st_bus_next    = (rd_mem2bus_en) ? `BUS_RD_DLY1 : `BUS_RD_DONE;
      end
      `BUS_RD_DLY1 : begin
         st_bus_next    = (app_rd_valid_o) ? `BUS_RD_DLY2 : `BUS_RD_DLY1;
      end
      `BUS_RD_DLY2 : begin
         st_bus_next    = `BUS_RD_DONE;
      end
      `BUS_RD_DONE : begin
         if (rd_mem2bus_en) begin
            IP2Bus_RdAck   = 1;
            st_bus_next    = `BUS_RD_WAIT;
            case (bus2mem_addr[3:2])
               2'b00 : IP2Bus_Data = r_app_rd_data[(0*36)+:32];
               2'b01 : IP2Bus_Data = r_app_rd_data[(1*36)+:32];
               2'b10 : IP2Bus_Data = r_app_rd_data[(2*36)+:32];
               2'b11 : IP2Bus_Data = r_app_rd_data[(3*36)+:32];
            endcase
         end
         else begin
            IP2Bus_RdAck   = 1;
            st_bus_next    = `BUS_RD_WAIT;
            case(Bus2IP_Addr[15:0])
               `CTRL_STATUS  : IP2Bus_Data = {30'b0, m_conv_b2m_tvalid, init_calib_complete_o};
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

always @(*) begin
   app_wr_cmd_i      = 0;
   app_wr_addr_i     = 0;
   app_wr_data_i     = 0;
   app_wr_bw_n_i     = {16{1'b1}};
   app_rd_cmd_i      = 0;
   app_rd_addr_i     = 0;
   wr_mem_addr_next  = 0;
   m_conv_b2m_tready = 0;
   rd_mem_addr_next  = 0;
   replay_no_next    = 0;
   st_axis_next      = 0;
   case(st_axis_current)
      `IDLE : begin
         st_axis_next   = (wr_bus2mem_en & (st_bus_current == `BUS_WR_DONE)) ? `AXIS_BUS_WR   :
                          (rd_mem2bus_en & (st_bus_current == `BUS_RD_DLY1)) ? `AXIS_BUS_RD   :
                          (m_conv_b2m_tvalid)                                ? `AXIS_WR_TUSER :
                          (en_start_replay & ~sw_rst_ff)                     ? `AXIS_RD       : `IDLE;
      end
      `AXIS_BUS_WR : begin
         st_axis_next   = `AXIS_BUS_WR_WAIT;
         app_wr_cmd_i   = 1;
         app_wr_addr_i  = bus2mem_addr[22:4];
         case (bus2mem_addr[3:2])
            2'b00 : begin
               app_wr_data_i[(0*36)+:36] = {4'h0, Bus2IP_Data};
               app_wr_bw_n_i[(0*4)+:4]   = 4'h0;
            end
            2'b01 : begin
               app_wr_data_i[(1*36)+:36] = {4'h0, Bus2IP_Data};
               app_wr_bw_n_i[(1*4)+:4]   = 4'h0;
            end
            2'b10 : begin
               app_wr_data_i[(2*36)+:36] = {4'h0, Bus2IP_Data};
               app_wr_bw_n_i[(2*4)+:4]   = 4'h0;
            end
            2'b11 : begin
               app_wr_data_i[(3*36)+:36] = {4'h0, Bus2IP_Data};
               app_wr_bw_n_i[(3*4)+:4]   = 4'h0;
            end
         endcase
      end
      `AXIS_BUS_WR_WAIT : begin
         st_axis_next   = (st_bus_current == `IDLE) ? `IDLE : `AXIS_BUS_WR_WAIT;
      end
      `AXIS_BUS_RD : begin
         app_rd_cmd_i   = 1;
         app_rd_addr_i  = bus2mem_addr[22:4];
         st_axis_next   = `AXIS_BUS_RD_WAIT;
      end
      `AXIS_BUS_RD_WAIT : begin
         st_axis_next   = (st_bus_current == `IDLE) ? `IDLE : `AXIS_BUS_RD_WAIT;
      end
      `AXIS_WR_TUSER : begin
         if (m_conv_b2m_tvalid) begin
            app_wr_cmd_i      = 1;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = {7'h0, 1'b1, 8'h0, m_conv_b2m_tuser};
            app_wr_bw_n_i     = 16'h0;
            wr_mem_addr_next  = wr_mem_addr + 1;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR;
         end
         else begin
            app_wr_cmd_i      = 0;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = 0;
            app_wr_bw_n_i     = 16'hff;
            wr_mem_addr_next  = wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_TUSER;
         end
      end
      `AXIS_WR_FLUSH : begin
         if (m_conv_b2m_tvalid) begin
            wr_mem_addr_next  = wr_mem_addr;
            m_conv_b2m_tready = 1;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_FLUSH;
         end
         else begin
            wr_mem_addr_next  = wr_mem_addr;
            st_axis_next      = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_FLUSH;
         end
      end
      `AXIS_WR : begin
         if (m_conv_b2m_tvalid) begin
            if (wr_mem_addr >= 19'h3ffff) begin
               app_wr_cmd_i      = 1;
               app_wr_addr_i     = wr_mem_addr;
               app_wr_data_i     = {8'h0, 1'b1, 2'b00, no_tkeep, m_conv_b2m_tdata};
               app_wr_bw_n_i     = 16'h0;
               wr_mem_addr_next  = wr_mem_addr;
               m_conv_b2m_tready = 1;
               st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_FLUSH;
            end
            else begin
               app_wr_cmd_i      = 1;
               app_wr_addr_i     = wr_mem_addr;
               app_wr_data_i     = (m_conv_b2m_tlast) ? {8'h0, 1'b1, 2'b00, no_tkeep, m_conv_b2m_tdata} : {11'h00, no_tkeep, m_conv_b2m_tdata};
               app_wr_bw_n_i     = 16'h0;
               wr_mem_addr_next  = wr_mem_addr + 1;
               m_conv_b2m_tready = 1;
               st_axis_next      = (r_clear) ? `IDLE : (m_conv_b2m_tlast) ? `AXIS_WR_TUSER : `AXIS_WR;
            end
         end
         else begin
            app_wr_cmd_i      = 0;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = 0;
            app_wr_bw_n_i     = 16'hff;
            wr_mem_addr_next  = wr_mem_addr;
            m_conv_b2m_tready = 0;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_WR_TUSER;
         end
      end
      `AXIS_RD : begin
         if (s_async_tready) begin
            app_rd_cmd_i      = 1;
            app_rd_addr_i     = rd_mem_addr;
            rd_mem_addr_next  = rd_mem_addr + 1;
            replay_no_next    = (rd_mem_addr == wr_end_addr) ? replay_no + 1 : replay_no;
            st_axis_next      = (r_clear) ? `IDLE : (rd_mem_addr == wr_end_addr) ? `AXIS_RD_WAIT : `AXIS_RD;
         end
         else begin
            app_rd_cmd_i      = 0;
            app_rd_addr_i     = rd_mem_addr;
            rd_mem_addr_next  = rd_mem_addr;
            replay_no_next    = replay_no;
            st_axis_next      = (r_clear) ? `IDLE : `AXIS_RD;
         end
      end
      `AXIS_RD_WAIT : begin
         app_rd_cmd_i      = 0;
         app_rd_addr_i     = 0;
         rd_mem_addr_next  = 0;
         replay_no_next    = replay_no;
         st_axis_next      = (r_clear) ? `IDLE : (replay_no < r_replay_count) ? `AXIS_RD : `IDLE;
      end
   endcase
end


always @(posedge clk)
   if (rst_clk)
      m2b_tuser   <= 0;
   else
      m2b_tuser   <= m2b_tuser_next;

always @(mem_data_out or mem_data_empty or mem_data_full) begin
   m2b_tkeep = 0;
   case (mem_data_out[128+4:128])
      5'h01 : m2b_tkeep = 16'h0001;
      5'h02 : m2b_tkeep = 16'h0003;
      5'h03 : m2b_tkeep = 16'h0007;
      5'h04 : m2b_tkeep = 16'h000f;
      5'h05 : m2b_tkeep = 16'h001f;
      5'h06 : m2b_tkeep = 16'h003f;
      5'h07 : m2b_tkeep = 16'h007f;
      5'h08 : m2b_tkeep = 16'h00ff;
      5'h09 : m2b_tkeep = 16'h01ff;
      5'h0a : m2b_tkeep = 16'h03ff;
      5'h0b : m2b_tkeep = 16'h07ff;
      5'h0c : m2b_tkeep = 16'h0fff;
      5'h0d : m2b_tkeep = 16'h1fff;
      5'h0e : m2b_tkeep = 16'h3fff;
      5'h0f : m2b_tkeep = 16'h7fff;
      5'h10 : m2b_tkeep = 16'hffff;
   endcase
end

always @(*) begin
   fifo_in_tdata     = 0;
   fifo_in_tuser     = 0;
   fifo_in_tkeep     = 0;
   fifo_in_tlast     = 0;
   fifo_tvalid       = 0;
   mem_data_rd       = 0;
   m2b_tuser_next    = m2b_tuser;
   //    tlast                tuser 
   case({mem_data_out[127+8], mem_data_out[127+9], ~mem_data_empty})
      3'b011 : begin
         fifo_in_tdata     = 0;
         fifo_in_tuser     = 0;
         fifo_in_tkeep     = 0;
         fifo_in_tlast     = 0;
         fifo_tvalid       = 0;
         mem_data_rd       = 1;
         m2b_tuser_next    = mem_data_out[127:0];
      end
      3'b001 : begin
         fifo_in_tdata     = mem_data_out[127:0];
         fifo_in_tuser     = m2b_tuser;
         fifo_in_tkeep     = m2b_tkeep;
         fifo_in_tlast     = 0;
         fifo_tvalid       = 1;
         mem_data_rd       = 1;
         m2b_tuser_next    = 0;
      end
      3'b101 : begin
         fifo_in_tdata     = mem_data_out[127:0];
         fifo_in_tuser     = 0;
         fifo_in_tkeep     = m2b_tkeep;
         fifo_in_tlast     = 1;
         fifo_tvalid       = 1;
         mem_data_rd       = 1;
         m2b_tuser_next    = 0;
      end
   endcase
end

endmodule
