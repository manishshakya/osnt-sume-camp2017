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

`timescale 1ns/1ps

module pre_pcap_mem_store
#(
   parameter   C_M_AXIS_DATA_WIDTH  = 256,
   parameter   C_S_AXIS_DATA_WIDTH  = 256,
   parameter   C_M_AXIS_TUSER_WIDTH = 128,
   parameter   C_S_AXIS_TUSER_WIDTH = 128
)
(
   input                                                 axis_aclk,
   input                                                 axis_aresetn,

   //Master Stream Ports to external memory for pcap storing
   output         [C_M_AXIS_DATA_WIDTH-1:0]              m_axis_tdata,
   output         [((C_M_AXIS_DATA_WIDTH/8))-1:0]        m_axis_tkeep,
   output         [C_M_AXIS_TUSER_WIDTH-1:0]             m_axis_tuser,
   output                                                m_axis_tvalid,
   input                                                 m_axis_tready,
   output                                                m_axis_tlast,

   //Slave Stream Ports from host over DMA 
   input          [C_S_AXIS_DATA_WIDTH-1:0]              s_axis_tdata,
   input          [((C_S_AXIS_DATA_WIDTH/8))-1:0]        s_axis_tkeep,
   input          [C_S_AXIS_TUSER_WIDTH-1:0]             s_axis_tuser,
   input                                                 s_axis_tvalid,
   output                                                s_axis_tready,
   input                                                 s_axis_tlast
);

integer j;

function integer log2;
   input integer number;
   begin
      log2=0;
      while(2**log2<number) begin
         log2=log2+1;
      end
   end
endfunction//log2

assign s_axis_tready = 1;

// ------------ Internal Params --------
localparam  MAX_PKT_SIZE      = 2000; //In bytes
localparam  IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH/8));

wire  fifo_m_empty;
wire  fifo_m_full;
wire  [C_M_AXIS_DATA_WIDTH-1:0]           fifo_m_out_tdata;
wire  [(C_M_AXIS_DATA_WIDTH/8)-1:0]       fifo_m_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]          fifo_m_out_tuser;
wire                                      fifo_m_out_tlast;

wire  fifo_s_empty;
wire  fifo_s_full;
wire  [C_M_AXIS_DATA_WIDTH-1:0]           fifo_s_out_tdata;
wire  [(C_M_AXIS_DATA_WIDTH/8)-1:0]       fifo_s_out_tkeep;
wire  [C_M_AXIS_TUSER_WIDTH-1:0]          fifo_s_out_tuser;
wire                                      fifo_s_out_tlast;

wire  s_conv_256to128_tready;

wire  [(C_M_AXIS_DATA_WIDTH/2)-1:0]       m_conv_256to128_tdata;
wire  [((C_M_AXIS_DATA_WIDTH/2)/8)-1:0]   m_conv_256to128_tkeep;
wire  [(C_M_AXIS_TUSER_WIDTH*2)-1:0]      m_conv_256to128_tuser;
wire                                      m_conv_256to128_tlast;
wire                                      m_conv_256to128_tvalid;
reg                                       m_conv_256to128_tready;

reg   [(C_M_AXIS_DATA_WIDTH/2)-1:0]       s_conv_128to256_tdata;
reg   [((C_M_AXIS_DATA_WIDTH/2)/8)-1:0]   s_conv_128to256_tkeep;
reg   [C_M_AXIS_TUSER_WIDTH-1:0]          s_conv_128to256_tuser, s_conv_128to256_tuser_next, s_conv_128to256_tuser_current;
reg                                       s_conv_128to256_tlast;
reg                                       s_conv_128to256_tvalid;
wire                                      s_conv_128to256_tready;

wire  [C_M_AXIS_DATA_WIDTH-1:0]           m_conv_128to256_tdata;
wire  [(C_M_AXIS_DATA_WIDTH/8)-1:0]       m_conv_128to256_tkeep;
wire  [(C_M_AXIS_TUSER_WIDTH*2)-1:0]      m_conv_128to256_tuser;
wire                                      m_conv_128to256_tlast;
wire                                      m_conv_128to256_tvalid;
wire                                      m_conv_128to256_tready;

wire  ts_signature_en;
wire  [127:0]  tuser_ts;
wire  [31:0]   ts_value;

`define  CONV_IDLE      0
`define  CONV_DROP      1
`define  CONV_PARSE     2
`define  CONV_SEND      3
`define  CONV_PASS      4

reg   [3:0] st_current, st_next;
always @(posedge axis_aclk)
   if (~axis_aresetn) begin
      st_current                    <= 0;
      s_conv_128to256_tuser_current <= 0;
   end
   else begin
      st_current                    <= st_next;
      s_conv_128to256_tuser_current <= s_conv_128to256_tuser_next;
   end

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_M_AXIS_DATA_WIDTH/8)+C_M_AXIS_DATA_WIDTH         ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                          )
)
pcap_s_fifo
(
   //Outputs
   .dout             (  {fifo_s_out_tlast, fifo_s_out_tuser, fifo_s_out_tkeep, fifo_s_out_tdata}   ),
   .full             (),
   .nearly_full      (  fifo_s_full                                                                ),
   .prog_full        (),
   .empty            (  fifo_s_empty                                                               ),
   //Inputs
   .din              (  {s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}                   ),
   .wr_en            (  s_axis_tvalid & ~fifo_s_full                                               ),
   .rd_en            (  ~fifo_s_empty & s_conv_256to128_tready                                     ),
   .reset            (  ~axis_aresetn                                                              ),
   .clk              (  axis_aclk                                                                  )
);

fifo_conv_256to128_0
fifo_conv_256to128_0
(
   .aclk                   (  axis_aclk                     ),
   .aresetn                (  axis_aresetn                  ),

   .s_axis_tvalid          (  ~fifo_s_empty                 ),
   .s_axis_tready          (  s_conv_256to128_tready        ),
   .s_axis_tdata           (  fifo_s_out_tdata              ),
   .s_axis_tkeep           (  fifo_s_out_tkeep              ),
   .s_axis_tlast           (  fifo_s_out_tlast              ),
   .s_axis_tuser           (  {128'b0, fifo_s_out_tuser}    ),
                                             
   .m_axis_tvalid          (  m_conv_256to128_tvalid        ),
   .m_axis_tready          (  m_conv_256to128_tready        ),
   .m_axis_tdata           (  m_conv_256to128_tdata         ),
   .m_axis_tkeep           (  m_conv_256to128_tkeep         ),
   .m_axis_tlast           (  m_conv_256to128_tlast         ),
   .m_axis_tuser           (  m_conv_256to128_tuser         )
);

assign ts_signature_en = (m_conv_256to128_tdata[0+:64] == 64'h00000000_efbeadde);
assign ts_value[0+:8]  = m_conv_256to128_tdata[120+:8];
assign ts_value[8+:8]  = m_conv_256to128_tdata[112+:8];
assign ts_value[16+:8] = m_conv_256to128_tdata[104+:8];
assign ts_value[24+:8] = m_conv_256to128_tdata[96+:8];

assign tuser_ts = {64'b0, ts_value, m_conv_256to128_tuser[0+:32]};

always @(*) begin
   s_conv_128to256_tvalid     = 0;
   s_conv_128to256_tdata      = 0;
   s_conv_128to256_tkeep      = 0;
   s_conv_128to256_tuser      = 0;
   s_conv_128to256_tlast      = 0;
   s_conv_128to256_tuser_next = 0;
   m_conv_256to128_tready     = 0;
   st_next                    = `CONV_IDLE;
   case(st_current)
      `CONV_IDLE : begin
         s_conv_128to256_tvalid     = 0;
         s_conv_128to256_tdata      = 0;
         s_conv_128to256_tkeep      = 0;
         s_conv_128to256_tuser      = 0;
         s_conv_128to256_tlast      = 0;
         s_conv_128to256_tuser_next = 0;
         m_conv_256to128_tready     = 0;
         st_next                    = (m_conv_256to128_tvalid & ts_signature_en) ? `CONV_DROP :
                                      (m_conv_256to128_tvalid                  ) ? `CONV_PASS : `CONV_IDLE;
      end
      `CONV_DROP : begin
         s_conv_128to256_tvalid     = 0;
         s_conv_128to256_tdata      = 0;
         s_conv_128to256_tkeep      = 0;
         s_conv_128to256_tuser      = 0;
         s_conv_128to256_tlast      = 0;
         s_conv_128to256_tuser_next = (m_conv_256to128_tvalid) ? tuser_ts : s_conv_128to256_tuser_current;
         m_conv_256to128_tready     = (m_conv_256to128_tvalid) ? 1 : 0;
         st_next                    = (m_conv_256to128_tvalid) ? `CONV_SEND : `CONV_DROP;
      end
      `CONV_SEND : begin
         s_conv_128to256_tvalid     =  m_conv_256to128_tvalid;
         s_conv_128to256_tdata      =  m_conv_256to128_tdata;
         s_conv_128to256_tkeep      =  m_conv_256to128_tkeep;
         s_conv_128to256_tuser      =  s_conv_128to256_tuser_current;
         s_conv_128to256_tlast      =  m_conv_256to128_tlast;
         s_conv_128to256_tuser_next = (m_conv_256to128_tvalid & s_conv_128to256_tready) ? 0 : s_conv_128to256_tuser_current;
         m_conv_256to128_tready     = (m_conv_256to128_tvalid & s_conv_128to256_tready) ? 1 : 0;
         st_next                    = (m_conv_256to128_tvalid & s_conv_128to256_tready & m_conv_256to128_tlast) ? `CONV_IDLE : `CONV_SEND;
      end
      `CONV_PASS : begin
         s_conv_128to256_tvalid     = (m_conv_256to128_tvalid & s_conv_128to256_tready);
         s_conv_128to256_tdata      =  m_conv_256to128_tdata;
         s_conv_128to256_tkeep      =  m_conv_256to128_tkeep;
         s_conv_128to256_tuser      =  s_conv_128to256_tuser;
         s_conv_128to256_tlast      =  m_conv_256to128_tlast;
         m_conv_256to128_tready     = (m_conv_256to128_tvalid & s_conv_128to256_tready) ? 1 : 0;
         st_next                    = (m_conv_256to128_tvalid & s_conv_128to256_tready & m_conv_256to128_tlast) ? `CONV_IDLE : `CONV_PASS;
      end
   endcase
end

fifo_conv_128to256_0
fifo_conv_128to256_0
(
   .aclk                   (  axis_aclk                     ),
   .aresetn                (  axis_aresetn                  ),

   .s_axis_tvalid          (  s_conv_128to256_tvalid        ),
   .s_axis_tready          (  s_conv_128to256_tready        ),
   .s_axis_tdata           (  s_conv_128to256_tdata         ),
   .s_axis_tkeep           (  s_conv_128to256_tkeep         ),
   .s_axis_tlast           (  s_conv_128to256_tlast         ),
   .s_axis_tuser           (  s_conv_128to256_tuser         ),
                                             
   .m_axis_tvalid          (  m_conv_128to256_tvalid        ),
   .m_axis_tready          (  m_conv_128to256_tready        ),
   .m_axis_tdata           (  m_conv_128to256_tdata         ),
   .m_axis_tkeep           (  m_conv_128to256_tkeep         ),
   .m_axis_tlast           (  m_conv_128to256_tlast         ),
   .m_axis_tuser           (  m_conv_128to256_tuser         )
);

assign m_conv_128to256_tready = ~fifo_m_full;
assign m_axis_tvalid = ~fifo_m_empty;

fallthrough_small_fifo
#(
   .WIDTH            (  1+C_M_AXIS_TUSER_WIDTH+(C_M_AXIS_DATA_WIDTH/8)+C_M_AXIS_DATA_WIDTH                                    ),
   .MAX_DEPTH_BITS   (  IN_FIFO_DEPTH_BIT                                                                                     )
)
pcap_m_fifo
(
   //Outputs
   .dout             (  {m_axis_tlast, m_axis_tuser, m_axis_tkeep, m_axis_tdata}                                              ),
   .full             (),
   .nearly_full      (  fifo_m_full                                                                                           ),
   .prog_full        (                                                                                                        ),
   .empty            (  fifo_m_empty                                                                                          ),
   //Inputs
   .din              (  {m_conv_128to256_tlast, m_conv_128to256_tuser[127:0], m_conv_128to256_tkeep, m_conv_128to256_tdata}   ),
   .wr_en            (  m_conv_128to256_tvalid & ~fifo_m_full                                                                 ),
   .rd_en            (  m_axis_tready & ~fifo_m_empty                                                                         ),
   .reset            (  ~axis_aresetn                                                                                         ),
   .clk              (  axis_aclk                                                                                             )
);

endmodule
