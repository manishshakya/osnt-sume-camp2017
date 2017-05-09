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

module osnt_sume_qdrA
#(
   parameter   C_S_AXI_DATA_WIDTH      = 32,          
   parameter   C_S_AXI_ADDR_WIDTH      = 32,          
   parameter   C_BASEADDR              = 32'hFFFFFFFF,
   parameter   C_HIGHADDR              = 32'h00000000,

   parameter   C_M_AXIS_TDATA_WIDTH    = 256,
   parameter   C_M_AXIS_TUSER_WIDTH    = 128,
   parameter   C_S_AXIS_TDATA_WIDTH    = 256,
   parameter   C_S_AXIS_TUSER_WIDTH    = 128 
)
(
   // Differential system clocks
   input                                                 sys_clk_p,
   input                                                 sys_clk_n,
   input                                                 sys_rst,
   //Memory Interface
   input                                                 qdriip_cq_p,
   input                                                 qdriip_cq_n,
   input          [35:0]                                 qdriip_q,
   inout                                                 qdriip_k_p,
   inout                                                 qdriip_k_n,
   output         [35:0]                                 qdriip_d,
   output         [18:0]                                 qdriip_sa,
   output                                                qdriip_w_n,
   output                                                qdriip_r_n,
   output         [3:0]                                  qdriip_bw_n,
   output                                                qdriip_dll_off_n,

   output                                                clk,
   output                                                resetn,

   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   output         [C_M_AXIS_TDATA_WIDTH-1:0]             m_axis_tdata,
   output         [((C_M_AXIS_TDATA_WIDTH/8))-1:0]       m_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m_axis_tuser,
   output                                                m_axis_tvalid,
   input                                                 m_axis_tready,
   output                                                m_axis_tlast,

   input          [C_S_AXIS_TDATA_WIDTH-1:0]             s_axis_tdata,
   input          [((C_S_AXIS_TDATA_WIDTH/8))-1:0]       s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast,

   input                                                 sw_rst,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             replay_count,
   input                                                 start_replay,
   input                                                 wr_done,

   // Slave AXI Ports
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             S_AXI_AWADDR,
   input                                                 S_AXI_AWVALID,
   input          [C_S_AXI_DATA_WIDTH-1 : 0]             S_AXI_WDATA,
   input          [C_S_AXI_DATA_WIDTH/8-1 : 0]           S_AXI_WSTRB,
   input                                                 S_AXI_WVALID,
   input                                                 S_AXI_BREADY,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             S_AXI_ARADDR,
   input                                                 S_AXI_ARVALID,
   input                                                 S_AXI_RREADY,
   output                                                S_AXI_ARREADY,
   output         [C_S_AXI_DATA_WIDTH-1 : 0]             S_AXI_RDATA,
   output         [1 : 0]                                S_AXI_RRESP,
   output                                                S_AXI_RVALID,
   output                                                S_AXI_WREADY,
   output         [1 :0]                                 S_AXI_BRESP,
   output                                                S_AXI_BVALID,
   output                                                S_AXI_AWREADY
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

localparam  MAX_PKT_SIZE      = 2000; //In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_TDATA_WIDTH/8));


// User Interface signals of Channel-0
reg            app_wr_cmd_i;
reg   [18:0]   app_wr_addr_i;
reg   [18:0]   wr_mem_addr, wr_mem_addr_next;
reg   [18:0]   rd_mem_addr, rd_mem_addr_next;
reg   [18:0]   wr_end_addr;
reg   [143:0]  app_wr_data_i;
reg   [15:0]   app_wr_bw_n_i; // default : 1
reg            app_rd_cmd_i;
reg   [18:0]   app_rd_addr_i;
wire           app_rd_valid_o;
wire  [143:0]  app_rd_data_o;
wire           init_calib_complete_o;

wire  bus2mem_addr_en, end_addr_rd_en, calib_rd_en, bus2mem_wr_en, bus2mem_rd_en;

reg   [C_S_AXI_ADDR_WIDTH-1:0]      replay_no, replay_no_next;

wire  rst_clk;

wire                                         Bus2IP_Clk;
wire                                         Bus2IP_Resetn;
wire  [C_S_AXI_ADDR_WIDTH-1:0]               Bus2IP_Addr;
wire  [0:0]                                  Bus2IP_CS;
wire                                         Bus2IP_RNW; // 0: wr, 1: rd
wire  [C_S_AXI_DATA_WIDTH-1:0]               Bus2IP_Data;
wire  [C_S_AXI_DATA_WIDTH/8-1:0]             Bus2IP_BE;
reg   [C_S_AXI_DATA_WIDTH-1:0]               IP2Bus_Data;
reg                                          IP2Bus_RdAck;
reg                                          IP2Bus_WrAck;
wire                                         IP2Bus_Error = 0;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             m_async_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8))-1:0]       m_async_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             m_async_tuser;
wire                                         m_async_tvalid;
wire                                         m_async_tready;
wire                                         m_async_tlast;

wire  [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         m_conv_b2m_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     m_conv_b2m_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             m_conv_b2m_tuser;
wire                                         m_conv_b2m_tvalid;
reg                                          m_conv_b2m_tready;
wire                                         m_conv_b2m_tlast;


wire  [C_S_AXIS_TDATA_WIDTH-1:0]             s_async_tdata;
wire  [((C_S_AXIS_TDATA_WIDTH/8))-1:0]       s_async_tkeep;
wire  [2*C_S_AXIS_TUSER_WIDTH-1:0]           s_async_tuser;
wire                                         s_async_tvalid;
wire                                         s_async_tready;
wire                                         s_async_tlast;

reg   [C_S_AXIS_TDATA_WIDTH-1:0]             s_conv_m2b_tdata;
reg   [((C_S_AXIS_TDATA_WIDTH/8))-1:0]       s_conv_m2b_tkeep;
reg   [C_S_AXIS_TUSER_WIDTH-1:0]             s_conv_m2b_tuser;
reg                                          s_conv_m2b_tvalid;
wire                                         s_conv_m2b_tready;
reg                                          s_conv_m2b_tlast;
wire                                         conv_m2b_tready;

wire  fifo_empty;
wire  fifo_full;
reg   fifo_tvalid;

reg   [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         fifo_in_tdata;
reg   [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     fifo_in_tkeep;
reg   [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_in_tuser;
reg                                          fifo_in_tlast;

wire  [(C_M_AXIS_TDATA_WIDTH/2)-1:0]         fifo_out_tdata;
wire  [((C_M_AXIS_TDATA_WIDTH/8)/2)-1:0]     fifo_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser;
wire                                         fifo_out_tlast;

wire  mem_data_empty;
wire  mem_data_full;
reg   mem_data_rd;
wire  [143:0]     mem_data_out;

reg   [C_S_AXIS_TUSER_WIDTH-1:0]             m2b_tuser, m2b_tuser_next;
reg   [((C_S_AXIS_TDATA_WIDTH/8)/2)-1:0]     m2b_tkeep;

reg   [C_S_AXI_ADDR_WIDTH-1 : 0]             r_replay_count;
reg   [2:0]    r_start_replay, r_wr_done, r_sw_rst;

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

reg sw_rst_ff;
always @(posedge clk)
   if (rst_clk)
      sw_rst_ff   <= 0;
   else if (en_sw_rst0)
      sw_rst_ff   <= 1;
   else if (en_sw_rst1)
      sw_rst_ff   <= 0;

assign resetn = ~rst_clk;

`define  IDLE           0
`define  BUS_WR         1
`define  BUS_WR_DONE    2
`define  BUS_WR_WAIT    3
`define  BUS_RD         4
`define  BUS_RD_DONE    5
`define  BUS_RD_WAIT    6
`define  AXIS_WR_TUSER  7
`define  AXIS_WR        8
`define  AXIS_RD        9
`define  AXIS_RD_WAIT   10

reg [4:0]   no_tkeep;

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
   
reg   [3:0] st_current, st_next;
always @(posedge clk)
   if (rst_clk) begin
      st_current     <= 0;
      replay_no      <= 0;
      wr_mem_addr    <= 0;
      rd_mem_addr    <= 0;
   end
   else begin
      st_current     <= st_next;
      replay_no      <= replay_no_next;
      wr_mem_addr    <= wr_mem_addr_next;
      rd_mem_addr    <= rd_mem_addr_next;
   end

always @(posedge clk)
   if (rst_clk)
      wr_end_addr    <= 0;
   else if (app_wr_cmd_i)
      wr_end_addr    <= app_wr_addr_i;

reg r_clear;
always @(posedge clk)
   if (rst_clk)
      r_clear  <= 0;
   else if (en_sw_rst0)
      r_clear  <= 1;
   else if (st_current == `IDLE)
      r_clear  <= 0;

assign bus2mem_addr_en = (Bus2IP_Addr[15:0] == 16'h0000) & Bus2IP_CS;
assign end_addr_rd_en  = (Bus2IP_Addr[15:0] == 16'h0004) & Bus2IP_CS;
assign calib_rd_en     = (Bus2IP_Addr[15:0] == 16'h0008) & Bus2IP_CS;
assign bus2mem_wr_en   = (Bus2IP_Addr[15:0] == 16'h0010) & Bus2IP_CS;
assign bus2mem_rd_en   = (Bus2IP_Addr[15:0] == 16'h0020) & Bus2IP_CS;

reg   [18+4:0]   bus2mem_addr;
always @(posedge clk)
   if (rst_clk)
      bus2mem_addr   <= 0;
   else if (bus2mem_addr_en & ~Bus2IP_RNW)
      bus2mem_addr   <= Bus2IP_Data[18+4:0];

always @(*) begin
   app_wr_cmd_i      = 0;
   app_wr_addr_i     = 0;
   app_wr_data_i     = 0;
   app_wr_bw_n_i     = {16{1'b1}};
   app_rd_cmd_i      = 0;
   app_rd_addr_i     = 0;
   IP2Bus_WrAck      = 0;
   IP2Bus_RdAck      = 0;
   IP2Bus_Data       = 0;
   wr_mem_addr_next  = 0;
   m_conv_b2m_tready = 0;
   rd_mem_addr_next  = 0;
   replay_no_next    = 0;
   st_next           = 0;
   case(st_current)
      `IDLE : begin
         st_next           = (Bus2IP_CS & ~Bus2IP_RNW)      ? `BUS_WR        :
                             (Bus2IP_CS &  Bus2IP_RNW)      ? `BUS_RD        :
                             (m_conv_b2m_tvalid)            ? `AXIS_WR_TUSER :
                             (en_start_replay & ~sw_rst_ff) ? `AXIS_RD       : `IDLE;
      end
      `BUS_WR : begin
         st_next           = `BUS_WR_DONE;
         if (bus2mem_wr_en) begin
            app_wr_cmd_i      = 1;
            app_wr_addr_i     = bus2mem_addr[22:4];
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
      end
      `BUS_WR_DONE : begin
         IP2Bus_WrAck   = 1;
         st_next        = `BUS_WR_WAIT;
      end
      `BUS_WR_WAIT : begin
         st_next        = (Bus2IP_CS) ? `BUS_WR_WAIT : `IDLE;
      end
      `BUS_RD : begin
         app_rd_cmd_i   = 1;
         app_rd_addr_i  = bus2mem_addr[22:4];
         st_next        = `BUS_RD_DONE;
      end
      `BUS_RD_DONE : begin
         if (bus2mem_addr_en) begin
            IP2Bus_Data    = bus2mem_addr;
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
         end
         else if (end_addr_rd_en) begin
            IP2Bus_Data    = wr_end_addr;
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
         end
         else if (calib_rd_en) begin
            IP2Bus_Data    = {31'b0, init_calib_complete_o};
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
         end
         else if (app_rd_valid_o & bus2mem_rd_en) begin
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
            case (bus2mem_addr[3:2])
               2'b00 : IP2Bus_Data = app_rd_data_o[(0*36)+:32];
               2'b01 : IP2Bus_Data = app_rd_data_o[(1*36)+:32];
               2'b10 : IP2Bus_Data = app_rd_data_o[(2*36)+:32];
               2'b11 : IP2Bus_Data = app_rd_data_o[(3*36)+:32];
            endcase
         end
         else if (app_rd_valid_o) begin
            IP2Bus_Data    = 0;
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
         end
         else begin
            IP2Bus_Data    = 0;
            IP2Bus_RdAck   = 0;
            st_next        = `BUS_RD_DONE;
         end
      end
      `BUS_RD_WAIT : begin
         st_next        = (Bus2IP_CS) ? `BUS_RD_WAIT : `IDLE;
      end
      `AXIS_WR_TUSER : begin
         if (m_conv_b2m_tvalid) begin
            app_wr_cmd_i      = 1;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = {7'h0, 1'b1, 8'h0, m_conv_b2m_tuser};
            app_wr_bw_n_i     = 16'h0;
            wr_mem_addr_next  = wr_mem_addr + 1;
            st_next           = (r_clear) ? `IDLE : `AXIS_WR;
         end
         else begin
            app_wr_cmd_i      = 0;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = 0;
            app_wr_bw_n_i     = 16'hff;
            wr_mem_addr_next  = wr_mem_addr;
            st_next           = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR_TUSER;
         end
      end
      `AXIS_WR : begin
         if (m_conv_b2m_tvalid) begin
            app_wr_cmd_i      = 1;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = (m_conv_b2m_tlast) ? {8'h0, 1'b1, 2'b00, no_tkeep, m_conv_b2m_tdata} : {11'h00, no_tkeep, m_conv_b2m_tdata};
            app_wr_bw_n_i     = 16'h0;
            wr_mem_addr_next  = wr_mem_addr + 1;
            m_conv_b2m_tready = 1;
            st_next           = (r_clear) ? `IDLE : (m_conv_b2m_tlast) ? `AXIS_WR_TUSER : `AXIS_WR;
         end
         else begin
            app_wr_cmd_i      = 0;
            app_wr_addr_i     = wr_mem_addr;
            app_wr_data_i     = 0;
            app_wr_bw_n_i     = 16'hff;
            wr_mem_addr_next  = wr_mem_addr;
            m_conv_b2m_tready = 0;
            st_next           = (r_clear) ? `IDLE : `AXIS_WR_TUSER;
         end
      end
      `AXIS_RD : begin
         if (s_async_tready) begin
            app_rd_cmd_i      = 1;
            app_rd_addr_i     = rd_mem_addr;
            rd_mem_addr_next  = rd_mem_addr + 1;
            replay_no_next    = (rd_mem_addr == wr_end_addr) ? replay_no + 1 : replay_no;
            st_next           = (r_clear) ? `IDLE : (rd_mem_addr == wr_end_addr) ? `AXIS_RD_WAIT : `AXIS_RD;
         end
         else begin
            app_rd_cmd_i      = 0;
            app_rd_addr_i     = rd_mem_addr;
            rd_mem_addr_next  = rd_mem_addr;
            replay_no_next    = replay_no;
            st_next           = (r_clear) ? `IDLE : `AXIS_RD;
         end
      end
      `AXIS_RD_WAIT : begin
         app_rd_cmd_i      = 0;
         app_rd_addr_i     = 0;
         rd_mem_addr_next  = 0;
         replay_no_next    = replay_no;
         st_next           = (r_clear) ? `IDLE : (replay_no < r_replay_count) ? `AXIS_RD : `IDLE;
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

// -- AXILITE IPIF
sume_axi_ipif #
(
   .C_S_AXI_DATA_WIDTH     (  C_S_AXI_DATA_WIDTH      ),
   .C_S_AXI_ADDR_WIDTH     (  C_S_AXI_ADDR_WIDTH      ),
   .C_BASEADDR             (  C_BASEADDR              ),
   .C_HIGHADDR             (  C_HIGHADDR              )
) sume_axi_ipif
(
   .S_AXI_ACLK             (  clk                     ),
   .S_AXI_ARESETN          (  resetn                  ),
   .S_AXI_AWADDR           (  S_AXI_AWADDR            ),
   .S_AXI_AWVALID          (  S_AXI_AWVALID           ),
   .S_AXI_WDATA            (  S_AXI_WDATA             ),
   .S_AXI_WSTRB            (  S_AXI_WSTRB             ),
   .S_AXI_WVALID           (  S_AXI_WVALID            ),
   .S_AXI_BREADY           (  S_AXI_BREADY            ),
   .S_AXI_ARADDR           (  S_AXI_ARADDR            ),
   .S_AXI_ARVALID          (  S_AXI_ARVALID           ),
   .S_AXI_RREADY           (  S_AXI_RREADY            ),
   .S_AXI_ARREADY          (  S_AXI_ARREADY           ),
   .S_AXI_RDATA            (  S_AXI_RDATA             ),
   .S_AXI_RRESP            (  S_AXI_RRESP             ),
   .S_AXI_RVALID           (  S_AXI_RVALID            ),
   .S_AXI_WREADY           (  S_AXI_WREADY            ),
   .S_AXI_BRESP            (  S_AXI_BRESP             ),
   .S_AXI_BVALID           (  S_AXI_BVALID            ),
   .S_AXI_AWREADY          (  S_AXI_AWREADY           ),
 
   // Controls to the IP/IPIF modules
   .Bus2IP_Clk             (  Bus2IP_Clk              ),
   .Bus2IP_Resetn          (  Bus2IP_Resetn           ),
   .Bus2IP_Addr            (  Bus2IP_Addr             ),
   .Bus2IP_RNW             (  Bus2IP_RNW              ),
   .Bus2IP_BE              (  Bus2IP_BE               ),
   .Bus2IP_CS              (  Bus2IP_CS               ),
   .Bus2IP_Data            (  Bus2IP_Data             ),
   .IP2Bus_Data            (  IP2Bus_Data             ),
   .IP2Bus_WrAck           (  IP2Bus_WrAck            ),
   .IP2Bus_RdAck           (  IP2Bus_RdAck            ),
   .IP2Bus_Error           (  IP2Bus_Error            )
);

qdrA_async_fifo_0
qdrA_async_fifo_b2m_0
(
   .s_axis_aclk            (  axis_aclk               ),
   .s_axis_aresetn         (  axis_aresetn            ),
   .s_axis_tvalid          (  s_axis_tvalid           ),
   .s_axis_tready          (  s_axis_tready           ),
   .s_axis_tdata           (  s_axis_tdata            ),
   .s_axis_tkeep           (  s_axis_tkeep            ),
   .s_axis_tlast           (  s_axis_tlast            ),
   .s_axis_tuser           (  s_axis_tuser            ),
                                             
   .m_axis_aclk            (  clk                     ),
   .m_axis_aresetn         (  resetn                  ),
   .m_axis_tvalid          (  m_async_tvalid          ),
   .m_axis_tready          (  m_async_tready          ),
   .m_axis_tdata           (  m_async_tdata           ),
   .m_axis_tkeep           (  m_async_tkeep           ),
   .m_axis_tlast           (  m_async_tlast           ),
   .m_axis_tuser           (  m_async_tuser           )
);

qdrA_fifo_conv_b2m_0
qdrA_fifo_conv_b2m_0
(
   .aclk                   (  clk                     ),
   .aresetn                (  resetn                  ),

   .s_axis_tvalid          (  m_async_tvalid          ),
   .s_axis_tready          (  m_async_tready          ),
   .s_axis_tdata           (  m_async_tdata           ),
   .s_axis_tkeep           (  m_async_tkeep           ),
   .s_axis_tlast           (  m_async_tlast           ),
   .s_axis_tuser           (  {128'b0, m_async_tuser} ),
                                             
   .m_axis_tvalid          (  m_conv_b2m_tvalid       ),
   .m_axis_tready          (  m_conv_b2m_tready       ),
   .m_axis_tdata           (  m_conv_b2m_tdata        ),
   .m_axis_tkeep           (  m_conv_b2m_tkeep        ),
   .m_axis_tlast           (  m_conv_b2m_tlast        ),
   .m_axis_tuser           (  m_conv_b2m_tuser        )
);

qdrA_async_fifo_0
qdrA_async_fifo_m2b_1
(
   .s_axis_aclk            (  clk                     ),
   .s_axis_aresetn         (  resetn                  ),

   .s_axis_tvalid          (  s_async_tvalid          ),
   .s_axis_tready          (  s_async_tready          ),
   .s_axis_tdata           (  s_async_tdata           ),
   .s_axis_tkeep           (  s_async_tkeep           ),
   .s_axis_tlast           (  s_async_tlast           ),
   .s_axis_tuser           (  s_async_tuser[127:0]    ),
                                             
   .m_axis_aclk            (  axis_aclk               ),
   .m_axis_aresetn         (  axis_aresetn            ),
   .m_axis_tvalid          (  m_axis_tvalid           ),
   .m_axis_tready          (  m_axis_tready           ),
   .m_axis_tdata           (  m_axis_tdata            ),
   .m_axis_tkeep           (  m_axis_tkeep            ),
   .m_axis_tlast           (  m_axis_tlast            ),
   .m_axis_tuser           (  m_axis_tuser            )
);

qdrA_fifo_conv_m2b_0
qdrA_fifo_conv_m2b_0
(
   .aclk                   (  clk                     ),
   .aresetn                (  resetn                  ),

   .s_axis_tvalid          (  ~fifo_empty             ),
   .s_axis_tready          (  conv_m2b_tready         ),
   .s_axis_tdata           (  fifo_out_tdata          ),
   .s_axis_tkeep           (  fifo_out_tkeep          ),
   .s_axis_tlast           (  fifo_out_tlast          ),
   .s_axis_tuser           (  fifo_out_tuser          ),
                                             
   .m_axis_tvalid          (  s_async_tvalid          ),
   .m_axis_tready          (  s_async_tready          ),
   .m_axis_tdata           (  s_async_tdata           ),
   .m_axis_tkeep           (  s_async_tkeep           ),
   .m_axis_tlast           (  s_async_tlast           ),
   .m_axis_tuser           (  s_async_tuser           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+((C_M_AXIS_TDATA_WIDTH/8)/2)+(C_M_AXIS_TDATA_WIDTH/2)  ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                             )
)
mem_fifo
(
   //Outputs
   .dout             (  {fifo_out_tlast, fifo_out_tuser, fifo_out_tkeep, fifo_out_tdata}              ),
   .full             (                                                                                ),
   .nearly_full      (  fifo_full                                                                     ),
   .prog_full        (                                                                                ),
   .empty            (  fifo_empty                                                                    ),
   //Inputs
   .din              (  {fifo_in_tlast, fifo_in_tuser, fifo_in_tkeep, fifo_in_tdata}                  ),
   .wr_en            (  fifo_tvalid & ~fifo_full                                                      ),
   .rd_en            (  conv_m2b_tready & ~fifo_empty                                                 ),
   .reset            (  rst_clk                                                                       ),
   .clk              (  clk                                                                           )
);

fallthrough_small_fifo
#(
   .WIDTH            (  144               ),
   .MAX_DEPTH_BITS   (  10                )
)
mem_store
(
   //Outputs
   .dout             (  mem_data_out      ),
   .full             (                    ),
   .nearly_full      (  mem_data_full     ),
   .prog_full        (                    ),
   .empty            (  mem_data_empty    ),
   //Inputs
   .din              (  app_rd_data_o     ),
   .wr_en            (  app_rd_valid_o    ),
   .rd_en            (  mem_data_rd       ),
   .reset            (  rst_clk           ),
   .clk              (  clk               )
);

mig_qdrA
mig_qdrA
(
   // Differential system clocks
   .sys_clk_p              (  sys_clk_p               ),
   .sys_clk_n              (  sys_clk_n               ),
   //Memory Interface
   .qdriip_cq_p            (  qdriip_cq_p             ),
   .qdriip_cq_n            (  qdriip_cq_n             ),
   .qdriip_q               (  qdriip_q                ),
   .qdriip_k_p             (  qdriip_k_p              ),
   .qdriip_k_n             (  qdriip_k_n              ),
   .qdriip_d               (  qdriip_d                ),
   .qdriip_sa              (  qdriip_sa               ),
   .qdriip_w_n             (  qdriip_w_n              ),
   .qdriip_r_n             (  qdriip_r_n              ),
   .qdriip_bw_n            (  qdriip_bw_n             ),
   .qdriip_dll_off_n       (  qdriip_dll_off_n        ),
   // User Interface signals of Channel-0
   .app_wr_cmd0            (  app_wr_cmd_i            ),
   .app_wr_addr0           (  app_wr_addr_i           ),
   .app_wr_data0           (  app_wr_data_i           ),
   .app_wr_bw_n0           (  app_wr_bw_n_i           ),
   .app_rd_cmd0            (  app_rd_cmd_i            ),
   .app_rd_addr0           (  app_rd_addr_i           ),
   .app_rd_valid0          (  app_rd_valid_o          ),
   .app_rd_data0           (  app_rd_data_o           ),
   // User Interface signals of Channel-1. It is useful only for BL2 designs.
   // All inputs of Channel-1 can be grounded for BL4 designs.
   .app_wr_cmd1            (  0),
   .app_wr_addr1           (  0),
   .app_wr_data1           (  0),
   .app_wr_bw_n1           (  0),
   .app_rd_cmd1            (  0),
   .app_rd_addr1           (  0),
   .app_rd_valid1          (),
   .app_rd_data1           (),
   // source 233MHz => 250MHz
   .clk                    (  clk                     ),
   .rst_clk                (  rst_clk                 ),
   .init_calib_complete    (  init_calib_complete_o   ),
   .sys_rst                (  sys_rst                 )
);
  
endmodule
