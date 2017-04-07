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

module osnt_sume_ddr3A
#(
   parameter   C_S_AXI_DATA_WIDTH      = 32,          
   parameter   C_S_AXI_ADDR_WIDTH      = 32,          
   parameter   C_USE_WSTRB             = 0,
   parameter   C_DPHASE_TIMEOUT        = 0,
   parameter   C_BASEADDR              = 32'hFFFFFFFF,
   parameter   C_HIGHADDR              = 32'h00000000,

   parameter   C_M_AXIS_TDATA_WIDTH    = 256,
   parameter   C_M_AXIS_TUSER_WIDTH    = 128,
   parameter   C_S_AXIS_TDATA_WIDTH    = 256,
   parameter   C_S_AXIS_TUSER_WIDTH    = 128
)
(
   input                                                 sys_clk_i,
   input                                                 sys_rst,
   input                                                 clk_ref_i,

   inout          [63:0]                                 ddr3_dq,
   inout          [7:0]                                  ddr3_dqs_n,
   inout          [7:0]                                  ddr3_dqs_p,

   output         [15:0]                                 ddr3_addr,
   output         [2:0]                                  ddr3_ba,
   output                                                ddr3_ras_n,
   output                                                ddr3_cas_n,
   output                                                ddr3_we_n,
   output                                                ddr3_reset_n,
   output                                                ddr3_ck_p,
   output                                                ddr3_ck_n,
   output                                                ddr3_cke,
   output                                                ddr3_cs_n,
   output         [7:0]                                  ddr3_dm,
   output                                                ddr3_odt,

   output                                                clk,
   output                                                resetn,

   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   output         [C_M_AXIS_TDATA_WIDTH-1:0]             m_axis_tdata,
   output         [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         m_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m_axis_tuser,
   output                                                m_axis_tvalid,
   input                                                 m_axis_tready,
   output                                                m_axis_tlast,

   input          [C_S_AXIS_TDATA_WIDTH-1:0]             s_axis_tdata,
   input          [(C_S_AXIS_TDATA_WIDTH/8)-1:0]         s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast,

   input                                                 sw_rst,
   input          [C_S_AXI_ADDR_WIDTH-1 : 0]             replay_count,
   input                                                 start_replay,
   input                                                 wr_done,

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

localparam  MAX_PKT_SIZE      = 4000; //In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_TDATA_WIDTH/8));

reg   [29:0]      app_addr_i;
reg   [2:0]       app_cmd_i; // read;001, write;000
reg               app_en_i;
reg   [511:0]     app_wdf_data_i;
reg               app_wdf_end_i;
reg   [63:0]      app_wdf_mask_i;
reg               app_wdf_wren_i;
wire              app_wdf_rdy_o;
wire  [511:0]     app_rd_data_o;
wire              app_rd_data_end_o;
wire              app_rd_data_valid_o;
wire              app_rdy_o;
wire              init_calib_complete;

wire              rst_clk;

reg   [26:0]   wr_mem_addr, wr_mem_addr_next;
reg   [26:0]   rd_mem_addr, rd_mem_addr_next;
reg   [26:0]   wr_end_addr;

reg   [C_S_AXI_ADDR_WIDTH-1:0]      replay_no, replay_no_next;

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

assign resetn = ~rst_clk;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             m_async_tdata;
wire  [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         m_async_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             m_async_tuser;
wire                                         m_async_tvalid;
reg                                          m_async_tready;
wire                                         m_async_tlast;

reg   [C_M_AXIS_TDATA_WIDTH-1:0]             s_async_tdata;
reg   [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         s_async_tkeep;
reg   [C_M_AXIS_TUSER_WIDTH-1:0]             s_async_tuser;
reg                                          s_async_tvalid;
reg                                          s_async_tlast;
wire                                         s_async_tready;

wire  fifo_empty;
wire  fifo_full;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             fifo_in_tdata;
wire  [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         fifo_in_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_in_tuser;
wire                                         fifo_in_tlast;
wire  [94:0]                                 fifo_in_meta;

wire  [C_M_AXIS_TDATA_WIDTH-1:0]             fifo_out_tdata;
wire  [(C_M_AXIS_TDATA_WIDTH/8)-1:0]         fifo_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser;
wire                                         fifo_out_tlast;
wire  [94:0]                                 fifo_out_meta;

wire  pkt_data_end;
wire  bus2mem_addr_en, bus2mem_wr_en, bus2mem_rd_en;

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

assign bus2mem_addr_en = (Bus2IP_Addr[15:0] == 16'h0000) & Bus2IP_CS;
assign bus2mem_wr_en   = (Bus2IP_Addr[15:0] == 16'h0010) & Bus2IP_CS;
assign bus2mem_rd_en   = (Bus2IP_Addr[15:0] == 16'h0020) & Bus2IP_CS;

reg   [31:0]   bus2mem_addr;
always @(posedge clk)
   if (rst_clk)
      bus2mem_addr   <= 0;
   else if (bus2mem_addr_en & ~Bus2IP_RNW)
      bus2mem_addr   <= Bus2IP_Data;

`define  IDLE           0
`define  BUS_WR         1
`define  BUS_WR_DONE    2
`define  BUS_WR_WAIT    3
`define  BUS_RD         4
`define  BUS_RD_DONE    5
`define  BUS_RD_WAIT    6
`define  AXIS_WR        7
`define  AXIS_WR_WAIT   8
`define  AXIS_WR_VALID  9
`define  AXIS_RD        10
`define  AXIS_RD_WAIT   11

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
   else if ((app_cmd_i == 3'b000) & app_en_i & app_wdf_wren_i)
      wr_end_addr    <= wr_mem_addr;

reg r_clear;
always @(posedge clk)
   if (rst_clk)
      r_clear  <= 0;
   else if (en_sw_rst0)
      r_clear  <= 1;
   else if (st_current == `IDLE)
      r_clear  <= 0;

always @(*) begin
   app_addr_i        = 0;
   app_cmd_i         = 0;
   app_en_i          = 0;
   app_wdf_end_i     = 0;
   app_wdf_wren_i    = 0;
   app_wdf_data_i    = 0;
   app_wdf_mask_i    = {64{1'b1}};
   IP2Bus_WrAck      = 0;
   IP2Bus_RdAck      = 0;
   IP2Bus_Data       = 0;
   m_async_tready    = 0;
   rd_mem_addr_next  = 0;
   wr_mem_addr_next  = 0;
   replay_no_next    = 0;
   st_next           = 0;
   case(st_current)
      `IDLE : begin
         st_next        = (Bus2IP_CS & ~Bus2IP_RNW & app_wdf_rdy_o) ? `BUS_WR  :
                          (Bus2IP_CS &  Bus2IP_RNW & app_rdy_o)     ? `BUS_RD  :
                          (m_async_tvalid)                          ? `AXIS_WR :
                          (en_start_replay && ~sw_rst_ff)           ? `AXIS_RD : `IDLE;
      end
      `BUS_WR : begin
         st_next        = `BUS_WR_DONE;
         if (bus2mem_wr_en) begin
            // 0000 1000
            // 0100 0000
            app_addr_i     = {1'b0, bus2mem_addr[31:6], 3'b0};
            app_cmd_i      = 3'b000;
            app_en_i       = 1;
            app_wdf_end_i  = 1;
            app_wdf_wren_i = 1;
            st_next        = `BUS_WR_DONE;
            case (bus2mem_addr[5:2])
               4'h0 : begin
                  app_wdf_data_i[(0*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(0*4)+:4]   = 4'h0;
               end
               4'h1 : begin
                  app_wdf_data_i[(1*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(1*4)+:4]   = 4'h0;
               end
               4'h2 : begin
                  app_wdf_data_i[(2*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(2*4)+:4]   = 4'h0;
               end
               4'h3 : begin
                  app_wdf_data_i[(3*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(3*4)+:4]   = 4'h0;
               end
               4'h4 : begin
                  app_wdf_data_i[(4*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(4*4)+:4]   = 4'h0;
               end
               4'h5 : begin
                  app_wdf_data_i[(5*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(5*4)+:4]   = 4'h0;
               end
               4'h6 : begin
                  app_wdf_data_i[(6*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(6*4)+:4]   = 4'h0;
               end
               4'h7 : begin
                  app_wdf_data_i[(7*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(7*4)+:4]   = 4'h0;
               end
               4'h8 : begin
                  app_wdf_data_i[(8*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(8*4)+:4]   = 4'h0;
               end
               4'h9 : begin
                  app_wdf_data_i[(9*32)+:32] = Bus2IP_Data;
                  app_wdf_mask_i[(9*4)+:4]   = 4'h0;
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
      end
      `BUS_WR_DONE : begin
         IP2Bus_WrAck   = 1;
         st_next        = `BUS_WR_WAIT;
      end
      `BUS_WR_WAIT : begin
         st_next        = (Bus2IP_CS) ? `BUS_WR_WAIT : `IDLE;
      end
      `BUS_RD : begin
         if (bus2mem_addr_en) begin
            st_next        = `BUS_RD_DONE;
         end
         else if (app_rdy_o) begin
            app_addr_i     = {1'b0, bus2mem_addr[31:6], 3'b0};
            app_cmd_i      = 3'b001;
            app_en_i       = 1;
            st_next        = `BUS_RD_DONE;
         end
         else begin
            st_next        = `BUS_RD;
         end
      end
      `BUS_RD_DONE : begin
         if (bus2mem_addr_en) begin
            IP2Bus_Data    = bus2mem_addr;
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
         end
         else if (~bus2mem_rd_en) begin
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
         end
         else if (app_rd_data_valid_o) begin
            IP2Bus_RdAck   = 1;
            st_next        = `BUS_RD_WAIT;
            case (bus2mem_addr[5:2])
               4'h0 : begin
                  IP2Bus_Data = app_rd_data_o[(0*32)+:32];
               end
               4'h1 : begin
                  IP2Bus_Data = app_rd_data_o[(1*32)+:32];
               end
               4'h2 : begin
                  IP2Bus_Data = app_rd_data_o[(2*32)+:32];
               end
               4'h3 : begin
                  IP2Bus_Data = app_rd_data_o[(3*32)+:32];
               end
               4'h4 : begin
                  IP2Bus_Data = app_rd_data_o[(4*32)+:32];
               end
               4'h5 : begin
                  IP2Bus_Data = app_rd_data_o[(5*32)+:32];
               end
               4'h6 : begin
                  IP2Bus_Data = app_rd_data_o[(6*32)+:32];
               end
               4'h7 : begin
                  IP2Bus_Data = app_rd_data_o[(7*32)+:32];
               end
               4'h8 : begin
                  IP2Bus_Data = app_rd_data_o[(8*32)+:32];
               end
               4'h9 : begin
                  IP2Bus_Data = app_rd_data_o[(9*32)+:32];
               end
               4'ha : begin
                  IP2Bus_Data = app_rd_data_o[(10*32)+:32];
               end
               4'hb : begin
                  IP2Bus_Data = app_rd_data_o[(11*32)+:32];
               end
               4'hc : begin
                  IP2Bus_Data = app_rd_data_o[(12*32)+:32];
               end
               4'hd : begin
                  IP2Bus_Data = app_rd_data_o[(13*32)+:32];
               end
               4'he : begin
                  IP2Bus_Data = app_rd_data_o[(14*32)+:32];
               end
               4'hf : begin
                  IP2Bus_Data = app_rd_data_o[(15*32)+:32];
               end
            endcase
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
      `AXIS_WR : begin
         if (m_async_tvalid & app_wdf_rdy_o) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b000;
            app_en_i          = 1;
            app_wdf_end_i     = 1;
            app_wdf_wren_i    = 1;
            app_wdf_data_i    = {95'h0, m_async_tlast, m_async_tuser, m_async_tkeep, m_async_tdata};
            app_wdf_mask_i    = 64'h0;
            wr_mem_addr_next  = wr_mem_addr;
            st_next           = (r_clear) ? `IDLE : `AXIS_WR_WAIT;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : (en_wr_done) ? 0 : wr_mem_addr;
            st_next           = (r_clear) ? `IDLE : (en_wr_done) ? `IDLE : `AXIS_WR;
         end
      end
      `AXIS_WR_WAIT : begin
         if (app_rdy_o) begin
            app_addr_i        = {wr_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_next           = (r_clear) ? `IDLE : `AXIS_WR_VALID;
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_next           = (r_clear) ? `IDLE : `AXIS_WR_WAIT;
         end
      end
      `AXIS_WR_VALID : begin
         if (app_rd_data_valid_o) begin
            if (app_rd_data_o == {95'h0, m_async_tlast, m_async_tuser, m_async_tkeep, m_async_tdata}) begin
               m_async_tready    = 1;
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr + 1;
               st_next           = (r_clear) ? `IDLE : `AXIS_WR;
            end
            else begin
               wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
               st_next           = (r_clear) ? `IDLE : `AXIS_WR;
            end
         end
         else begin
            wr_mem_addr_next  = (r_clear) ? 0 : wr_mem_addr;
            st_next           = (r_clear) ? `IDLE : `AXIS_WR_VALID;
         end
      end
      `AXIS_RD : begin
         if (s_async_tready & app_rdy_o) begin
            app_addr_i        = {rd_mem_addr, 3'b0};
            app_cmd_i         = 3'b001;
            app_en_i          = 1;
            rd_mem_addr_next  = rd_mem_addr + 1;
            replay_no_next    = (rd_mem_addr == wr_end_addr) ? replay_no + 1 : replay_no;
            st_next           = (r_clear) ? `IDLE : (rd_mem_addr == wr_end_addr) ? `AXIS_RD_WAIT : `AXIS_RD;
         end
         else begin
            rd_mem_addr_next  = rd_mem_addr;
            replay_no_next    = replay_no;
            st_next           = (r_clear) ? `IDLE : `AXIS_RD;
         end
      end
      `AXIS_RD_WAIT : begin
         rd_mem_addr_next  = 0;
         replay_no_next    = replay_no;
         st_next           = (r_clear) ? `IDLE : (replay_no < r_replay_count) ? `AXIS_RD : `IDLE;
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

ddr3A_async_fifo_0
ddr3A_async_fifo_b2m_0
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

ddr3A_async_fifo_0
ddr3A_async_fifo_m2b_1
(
   .s_axis_aclk            (  clk                     ),
   .s_axis_aresetn         (  resetn                  ),

   .s_axis_tvalid          (  ~fifo_empty             ),
   .s_axis_tready          (  s_async_tready          ),
   .s_axis_tdata           (  fifo_out_tdata          ),
   .s_axis_tkeep           (  fifo_out_tkeep          ),
   .s_axis_tlast           (  fifo_out_tlast          ),
   .s_axis_tuser           (  fifo_out_tuser          ),
                                             
   .m_axis_aclk            (  axis_aclk               ),
   .m_axis_aresetn         (  axis_aresetn            ),
   .m_axis_tvalid          (  m_axis_tvalid           ),
   .m_axis_tready          (  m_axis_tready           ),
   .m_axis_tdata           (  m_axis_tdata            ),
   .m_axis_tkeep           (  m_axis_tkeep            ),
   .m_axis_tlast           (  m_axis_tlast            ),
   .m_axis_tuser           (  m_axis_tuser            )
);

assign fifo_in_tdata = app_rd_data_o[0+:256];
assign fifo_in_tkeep = app_rd_data_o[256+:32];
assign fifo_in_tuser = app_rd_data_o[288+:128];
assign fifo_in_tlast = app_rd_data_o[416+:1];

wire st_valid = (st_current != `AXIS_WR) & (st_current != `AXIS_WR_WAIT) & (st_current != `AXIS_WR_VALID);

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_M_AXIS_TDATA_WIDTH/8)+C_M_AXIS_TDATA_WIDTH       ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                          )
)
mem_fifo
(
   //Outputs
   .dout             (  {fifo_out_tlast, fifo_out_tuser, fifo_out_tkeep, fifo_out_tdata}           ),
   .full             (                                                                             ),
   .nearly_full      (  fifo_full                                                                  ),
   .prog_full        (                                                                             ),
   .empty            (  fifo_empty                                                                 ),
   //Inputs
   .din              (  {fifo_in_tlast, fifo_in_tuser, fifo_in_tkeep, fifo_in_tdata}               ),
   .wr_en            (  app_rd_data_valid_o & ~fifo_full & ~Bus2IP_CS & st_valid                   ),
   .rd_en            (  s_async_tready & ~fifo_empty                                               ),
   .reset            (  rst_clk                                                                    ),
   .clk              (  clk                                                                        )
);

mig_ddr3A
mig_ddr3A
(
   // Inouts
   .ddr3_dq                (  ddr3_dq                 ),
   .ddr3_dqs_n             (  ddr3_dqs_n              ),
   .ddr3_dqs_p             (  ddr3_dqs_p              ),
   // Outputs
   .ddr3_addr              (  ddr3_addr               ),
   .ddr3_ba                (  ddr3_ba                 ),
   .ddr3_ras_n             (  ddr3_ras_n              ),
   .ddr3_cas_n             (  ddr3_cas_n              ),
   .ddr3_we_n              (  ddr3_we_n               ),
   .ddr3_reset_n           (  ddr3_reset_n            ),
   .ddr3_ck_p              (  ddr3_ck_p               ),
   .ddr3_ck_n              (  ddr3_ck_n               ),
   .ddr3_cke               (  ddr3_cke                ),
   .ddr3_cs_n              (  ddr3_cs_n               ),
   .ddr3_dm                (  ddr3_dm                 ),
   .ddr3_odt               (  ddr3_odt                ),
   // Inputs
   // Single-ended system clock
   .sys_clk_i              (  sys_clk_i               ),
   .clk_ref_i              (  clk_ref_i               ),
   // user interface signals
   .app_addr               (  app_addr_i              ),
   .app_cmd                (  app_cmd_i               ),
   .app_en                 (  app_en_i                ),
   .app_wdf_data           (  app_wdf_data_i          ),
   .app_wdf_end            (  app_wdf_end_i           ),
   .app_wdf_mask           (  app_wdf_mask_i          ),
   .app_wdf_wren           (  app_wdf_wren_i          ),
   .app_wdf_rdy            (  app_wdf_rdy_o           ),
   .app_rd_data            (  app_rd_data_o           ),
   .app_rd_data_end        (  app_rd_data_end_o       ),
   .app_rd_data_valid      (  app_rd_data_valid_o     ),
   .app_rdy                (  app_rdy_o               ),
   .app_sr_req             (  0), //0
   .app_ref_req            (  0), //for refresh
   .app_zq_req             (  0), //for cal
   .app_sr_active          (  ), 
   .app_ref_ack            (  ),
   .app_zq_ack             (  ),
   .ui_clk                 (  clk                     ),
   .ui_clk_sync_rst        (  rst_clk                 ),
   .init_calib_complete    (  init_calib_complete     ),
   // The 12 MSB bits of the temperature sensor transfer
   // function need to be connected to this port. This port
   // will be synchronized w.r.t. to fabric clock internally.
   .device_temp            (  ),
   .sys_rst                (  sys_rst                 )
  );
  
endmodule
