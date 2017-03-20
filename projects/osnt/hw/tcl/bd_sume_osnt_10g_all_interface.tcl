#
# Copyright (c) 2016 University of Cambridge
# Copyright (c) 2016 Jong Hun Han
# All rights reserved.
#
# This software was developed by University of Cambridge Computer Laboratory
# under the ENDEAVOUR project (grant agreement 644960) as part of
# the European Union's Horizon 2020 research and innovation programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA Open Systems C.I.C. (NetFPGA) under one or more
# contributor license agreements. See the NOTICE file distributed with this
# work for additional information regarding copyright ownership. NetFPGA
# licenses this file to you under the NetFPGA Hardware-Software License,
# Version 1.0 (the License); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at:
#
# http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@


proc create_hier_cell_sume_osnt_10g_all_interface { parentCell coreName tdataWidth} {

   # Check argument
   if { $parentCell eq "" || $coreName eq "" || $tdataWidth eq "" } {
      puts "ERROR: Empty argument(s)!"
      return
   }

   # Get object for parentCell
   set parentObj [get_bd_cells $parentCell]
   if { $parentCell == "" } {
      puts "ERROR: Unable to find parent cell <$parentCell>!"
      return
   }

   # parentObj should be hier block
   set parentType [get_property TYPE $parentObj]
   if { $parentType ne "hier"} {
      puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>."
   }

   # Save current instance; Restore later
   set oldCurInst [current_bd_instance .]

   # Set parent object as current
   current_bd_instance $parentObj

   # Create cell and set as current instance
   set hier_obj [create_bd_cell -type hier $coreName]
   current_bd_instance $hier_obj

   # SFP clock and reset
   create_bd_pin -dir I reset
   create_bd_pin -dir I -type clk refclk_p
   create_bd_pin -dir I -type clk refclk_n

   create_bd_pin -dir O -type clk coreclk_out 
   

   create_bd_pin -dir I -from 31 -to 0 rx_ts_pos 
   create_bd_pin -dir I -from 31 -to 0 tx_ts_pos

   create_bd_pin -dir I -from 63 -to 0 timestamp_156

   create_bd_pin -dir O -type clk clk156_out
   create_bd_pin -dir O aresetn_clk156_out
   
   # Clock running for data path fabric (eg 160Mhz)
   create_bd_pin -dir I -type clk core_clk
   create_bd_pin -dir I core_resetn

   create_bd_pin -dir I rxp_0
   create_bd_pin -dir I rxn_0
   create_bd_pin -dir I tx_abs_0
   create_bd_pin -dir I tx_fault_0
   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s0_axis

   create_bd_pin -dir O tx_led_0
   create_bd_pin -dir O rx_led_0
   create_bd_pin -dir O txp_0
   create_bd_pin -dir O txn_0
   create_bd_pin -dir O tx_disable_0
   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m0_axis

   create_bd_pin -dir I rxp_1
   create_bd_pin -dir I rxn_1
   create_bd_pin -dir I tx_abs_1
   create_bd_pin -dir I tx_fault_1
   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s1_axis

   create_bd_pin -dir O tx_led_1
   create_bd_pin -dir O rx_led_1
   create_bd_pin -dir O txp_1
   create_bd_pin -dir O txn_1
   create_bd_pin -dir O tx_disable_1
   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m1_axis

   create_bd_pin -dir I rxp_2
   create_bd_pin -dir I rxn_2
   create_bd_pin -dir I tx_abs_2
   create_bd_pin -dir I tx_fault_2
   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s2_axis

   create_bd_pin -dir O tx_led_2
   create_bd_pin -dir O rx_led_2
   create_bd_pin -dir O txp_2
   create_bd_pin -dir O txn_2
   create_bd_pin -dir O tx_disable_2
   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m2_axis

   create_bd_pin -dir I rxp_3
   create_bd_pin -dir I rxn_3
   create_bd_pin -dir I tx_abs_3
   create_bd_pin -dir I tx_fault_3
   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s3_axis

   create_bd_pin -dir O tx_led_3
   create_bd_pin -dir O rx_led_3
   create_bd_pin -dir O txp_3
   create_bd_pin -dir O txn_3
   create_bd_pin -dir O tx_disable_3
   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m3_axis

   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
   set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.MAX_BURST_LENGTH {1} CONFIG.SUPPORTS_NARROW_BURST {0}] [get_bd_intf_pin S_AXI]

   # Call 10g bd ips

   create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_10g_axi_if:1.00 osnt_sume_10g_axi_if_0
   set_property -dict [list CONFIG.C_BASEADDR 0x79000000] [get_bd_cells osnt_sume_10g_axi_if_0]
   set_property -dict [list CONFIG.C_HIGHADDR 0x7900ffff] [get_bd_cells osnt_sume_10g_axi_if_0]
   connect_bd_intf_net [get_bd_intf_pin S_AXI] [get_bd_intf_pins osnt_sume_10g_axi_if_0/S_AXI]


   source ./tcl/bd_sume_osnt_10g_interface.tcl
   create_hier_cell_sume_osnt_10g_interface [current_bd_instance .] sume_osnt_10g_interface_0 True  0x01 $tdataWidth
   create_hier_cell_sume_osnt_10g_interface [current_bd_instance .] sume_osnt_10g_interface_1 False 0x04 $tdataWidth
   create_hier_cell_sume_osnt_10g_interface [current_bd_instance .] sume_osnt_10g_interface_2 False 0x10 $tdataWidth
   create_hier_cell_sume_osnt_10g_interface [current_bd_instance .] sume_osnt_10g_interface_3 Falee 0x40 $tdataWidth

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_ts_pos_0] [get_bd_pins sume_osnt_10g_interface_0/rx_ts_pos]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_ts_pos_1] [get_bd_pins sume_osnt_10g_interface_1/rx_ts_pos]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_ts_pos_2] [get_bd_pins sume_osnt_10g_interface_2/rx_ts_pos]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_ts_pos_3] [get_bd_pins sume_osnt_10g_interface_3/rx_ts_pos]

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_ts_pos_0] [get_bd_pins sume_osnt_10g_interface_0/tx_ts_pos]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_ts_pos_1] [get_bd_pins sume_osnt_10g_interface_1/tx_ts_pos]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_ts_pos_2] [get_bd_pins sume_osnt_10g_interface_2/tx_ts_pos]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_ts_pos_3] [get_bd_pins sume_osnt_10g_interface_3/tx_ts_pos]

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_drop_0] [get_bd_pins sume_osnt_10g_interface_0/rx_drop]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_drop_1] [get_bd_pins sume_osnt_10g_interface_1/rx_drop]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_drop_2] [get_bd_pins sume_osnt_10g_interface_2/rx_drop]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_drop_3] [get_bd_pins sume_osnt_10g_interface_3/rx_drop]

   connect_bd_net [get_bd_pins timestamp_156] [get_bd_pins sume_osnt_10g_interface_0/timestamp_156]
   connect_bd_net [get_bd_pins timestamp_156] [get_bd_pins sume_osnt_10g_interface_1/timestamp_156]
   connect_bd_net [get_bd_pins timestamp_156] [get_bd_pins sume_osnt_10g_interface_2/timestamp_156]
   connect_bd_net [get_bd_pins timestamp_156] [get_bd_pins sume_osnt_10g_interface_3/timestamp_156]

   # Start bd ports connection 
   connect_bd_net [get_bd_pins reset] [get_bd_pins sume_osnt_10g_interface_0/reset]
   connect_bd_net [get_bd_pins refclk_n] [get_bd_pins sume_osnt_10g_interface_0/refclk_n]
   connect_bd_net [get_bd_pins refclk_p] [get_bd_pins sume_osnt_10g_interface_0/refclk_p]

   connect_bd_net [get_bd_pins core_clk] [get_bd_pins sume_osnt_10g_interface_0/core_clk]
   connect_bd_net [get_bd_pins core_clk] [get_bd_pins sume_osnt_10g_interface_1/core_clk]
   connect_bd_net [get_bd_pins core_clk] [get_bd_pins sume_osnt_10g_interface_2/core_clk]
   connect_bd_net [get_bd_pins core_clk] [get_bd_pins sume_osnt_10g_interface_3/core_clk]

   connect_bd_net [get_bd_pins core_resetn] [get_bd_pins sume_osnt_10g_interface_0/core_resetn]
   connect_bd_net [get_bd_pins core_resetn] [get_bd_pins sume_osnt_10g_interface_1/core_resetn]
   connect_bd_net [get_bd_pins core_resetn] [get_bd_pins sume_osnt_10g_interface_2/core_resetn]
   connect_bd_net [get_bd_pins core_resetn] [get_bd_pins sume_osnt_10g_interface_3/core_resetn]

   connect_bd_net [get_bd_pins rxp_0] [get_bd_pins sume_osnt_10g_interface_0/rxp]
   connect_bd_net [get_bd_pins rxn_0] [get_bd_pins sume_osnt_10g_interface_0/rxn]
   connect_bd_net [get_bd_pins tx_abs_0] [get_bd_pins sume_osnt_10g_interface_0/tx_abs]
   connect_bd_net [get_bd_pins tx_fault_0] [get_bd_pins sume_osnt_10g_interface_0/tx_fault]
   connect_bd_intf_net [get_bd_intf_pins s0_axis] [get_bd_intf_pins sume_osnt_10g_interface_0/s_axis]
   connect_bd_net [get_bd_pins tx_led_0] [get_bd_pins sume_osnt_10g_interface_0/resetdone_out]
   connect_bd_net [get_bd_pins rx_led_0] [get_bd_pins sume_osnt_10g_interface_0/resetdone_out]
   connect_bd_net [get_bd_pins txp_0] [get_bd_pins sume_osnt_10g_interface_0/txp]
   connect_bd_net [get_bd_pins txn_0] [get_bd_pins sume_osnt_10g_interface_0/txn]
   connect_bd_net [get_bd_pins tx_disable_0] [get_bd_pins sume_osnt_10g_interface_0/tx_disable]
   connect_bd_intf_net [get_bd_intf_pins m0_axis] [get_bd_intf_pins sume_osnt_10g_interface_0/m_axis]

   connect_bd_net [get_bd_pins rxp_1] [get_bd_pins sume_osnt_10g_interface_1/rxp]
   connect_bd_net [get_bd_pins rxn_1] [get_bd_pins sume_osnt_10g_interface_1/rxn]
   connect_bd_net [get_bd_pins tx_abs_1] [get_bd_pins sume_osnt_10g_interface_1/tx_abs]
   connect_bd_net [get_bd_pins tx_fault_1] [get_bd_pins sume_osnt_10g_interface_1/tx_fault]
   connect_bd_intf_net [get_bd_intf_pins s1_axis] [get_bd_intf_pins sume_osnt_10g_interface_1/s_axis]
   connect_bd_net [get_bd_pins tx_led_1] [get_bd_pins sume_osnt_10g_interface_1/tx_resetdone]
   connect_bd_net [get_bd_pins rx_led_1] [get_bd_pins sume_osnt_10g_interface_1/rx_resetdone]
   connect_bd_net [get_bd_pins txp_1] [get_bd_pins sume_osnt_10g_interface_1/txp]
   connect_bd_net [get_bd_pins txn_1] [get_bd_pins sume_osnt_10g_interface_1/txn]
   connect_bd_net [get_bd_pins tx_disable_1] [get_bd_pins sume_osnt_10g_interface_1/tx_disable]
   connect_bd_intf_net [get_bd_intf_pins m1_axis] [get_bd_intf_pins sume_osnt_10g_interface_1/m_axis]

   connect_bd_net [get_bd_pins rxp_2] [get_bd_pins sume_osnt_10g_interface_2/rxp]
   connect_bd_net [get_bd_pins rxn_2] [get_bd_pins sume_osnt_10g_interface_2/rxn]
   connect_bd_net [get_bd_pins tx_abs_2] [get_bd_pins sume_osnt_10g_interface_2/tx_abs]
   connect_bd_net [get_bd_pins tx_fault_2] [get_bd_pins sume_osnt_10g_interface_2/tx_fault]
   connect_bd_intf_net [get_bd_intf_pins s2_axis] [get_bd_intf_pins sume_osnt_10g_interface_2/s_axis]
   connect_bd_net [get_bd_pins tx_led_2] [get_bd_pins sume_osnt_10g_interface_2/tx_resetdone]
   connect_bd_net [get_bd_pins rx_led_2] [get_bd_pins sume_osnt_10g_interface_2/rx_resetdone]
   connect_bd_net [get_bd_pins txp_2] [get_bd_pins sume_osnt_10g_interface_2/txp]
   connect_bd_net [get_bd_pins txn_2] [get_bd_pins sume_osnt_10g_interface_2/txn]
   connect_bd_net [get_bd_pins tx_disable_2] [get_bd_pins sume_osnt_10g_interface_2/tx_disable]
   connect_bd_intf_net [get_bd_intf_pins m2_axis] [get_bd_intf_pins sume_osnt_10g_interface_2/m_axis]

   connect_bd_net [get_bd_pins rxp_3] [get_bd_pins sume_osnt_10g_interface_3/rxp]
   connect_bd_net [get_bd_pins rxn_3] [get_bd_pins sume_osnt_10g_interface_3/rxn]
   connect_bd_net [get_bd_pins tx_abs_3] [get_bd_pins sume_osnt_10g_interface_3/tx_abs]
   connect_bd_net [get_bd_pins tx_fault_3] [get_bd_pins sume_osnt_10g_interface_3/tx_fault]
   connect_bd_intf_net [get_bd_intf_pins s3_axis] [get_bd_intf_pins sume_osnt_10g_interface_3/s_axis]
   connect_bd_net [get_bd_pins tx_led_3] [get_bd_pins sume_osnt_10g_interface_3/tx_resetdone]
   connect_bd_net [get_bd_pins rx_led_3] [get_bd_pins sume_osnt_10g_interface_3/rx_resetdone]
   connect_bd_net [get_bd_pins txp_3] [get_bd_pins sume_osnt_10g_interface_3/txp]
   connect_bd_net [get_bd_pins txn_3] [get_bd_pins sume_osnt_10g_interface_3/txn]
   connect_bd_net [get_bd_pins tx_disable_3] [get_bd_pins sume_osnt_10g_interface_3/tx_disable]
   connect_bd_intf_net [get_bd_intf_pins m3_axis] [get_bd_intf_pins sume_osnt_10g_interface_3/m_axis]

   connect_bd_net [get_bd_pins coreclk_out] [get_bd_pins sume_osnt_10g_interface_0/coreclk_out]
   connect_bd_net [get_bd_pins clk156_out] [get_bd_pins sume_osnt_10g_interface_0/coreclk_out]

   create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0
   set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells util_vector_logic_0]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/areset_datapathclk_out] [get_bd_pins util_vector_logic_0/Op1] 
   connect_bd_net [get_bd_pins aresetn_clk156_out] [get_bd_pins util_vector_logic_0/Res]

   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/coreclk_out] [get_bd_pins osnt_sume_10g_axi_if_0/S_AXI_ACLK]
   connect_bd_net [get_bd_pins util_vector_logic_0/Res] [get_bd_pins osnt_sume_10g_axi_if_0/S_AXI_ARESETN]

   # Start bd internal connection
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/coreclk_out] [get_bd_pins sume_osnt_10g_interface_1/coreclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/areset_datapathclk_out] [get_bd_pins sume_osnt_10g_interface_1/areset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txusrclk_out] [get_bd_pins sume_osnt_10g_interface_1/txusrclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txusrclk2_out] [get_bd_pins sume_osnt_10g_interface_1/txusrclk2]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txuserrdy_out] [get_bd_pins sume_osnt_10g_interface_1/txuserrdy]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/gttxreset_out] [get_bd_pins sume_osnt_10g_interface_1/gttxreset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/gtrxreset_out] [get_bd_pins sume_osnt_10g_interface_1/gtrxreset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/reset_counter_done_out] [get_bd_pins sume_osnt_10g_interface_1/reset_counter_done]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplllock_out] [get_bd_pins sume_osnt_10g_interface_1/qplllock]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplloutclk_out] [get_bd_pins sume_osnt_10g_interface_1/qplloutclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplloutrefclk_out] [get_bd_pins sume_osnt_10g_interface_1/qplloutrefclk]
   
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/coreclk_out] [get_bd_pins sume_osnt_10g_interface_2/coreclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/areset_datapathclk_out] [get_bd_pins sume_osnt_10g_interface_2/areset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txusrclk_out] [get_bd_pins sume_osnt_10g_interface_2/txusrclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txusrclk2_out] [get_bd_pins sume_osnt_10g_interface_2/txusrclk2]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txuserrdy_out] [get_bd_pins sume_osnt_10g_interface_2/txuserrdy]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/gttxreset_out] [get_bd_pins sume_osnt_10g_interface_2/gttxreset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/gtrxreset_out] [get_bd_pins sume_osnt_10g_interface_2/gtrxreset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/reset_counter_done_out] [get_bd_pins sume_osnt_10g_interface_2/reset_counter_done]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplllock_out] [get_bd_pins sume_osnt_10g_interface_2/qplllock]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplloutclk_out] [get_bd_pins sume_osnt_10g_interface_2/qplloutclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplloutrefclk_out] [get_bd_pins sume_osnt_10g_interface_2/qplloutrefclk]
   
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/coreclk_out] [get_bd_pins sume_osnt_10g_interface_3/coreclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/areset_datapathclk_out] [get_bd_pins sume_osnt_10g_interface_3/areset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txusrclk_out] [get_bd_pins sume_osnt_10g_interface_3/txusrclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txusrclk2_out] [get_bd_pins sume_osnt_10g_interface_3/txusrclk2]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/txuserrdy_out] [get_bd_pins sume_osnt_10g_interface_3/txuserrdy]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/gttxreset_out] [get_bd_pins sume_osnt_10g_interface_3/gttxreset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/gtrxreset_out] [get_bd_pins sume_osnt_10g_interface_3/gtrxreset]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/reset_counter_done_out] [get_bd_pins sume_osnt_10g_interface_3/reset_counter_done]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplllock_out] [get_bd_pins sume_osnt_10g_interface_3/qplllock]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplloutclk_out] [get_bd_pins sume_osnt_10g_interface_3/qplloutclk]
   connect_bd_net [get_bd_pins sume_osnt_10g_interface_0/qplloutrefclk_out] [get_bd_pins sume_osnt_10g_interface_3/qplloutrefclk]

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_rx_config_0] [get_bd_pins sume_osnt_10g_interface_0/mac_rx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_tx_config_0] [get_bd_pins sume_osnt_10g_interface_0/mac_tx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_config_0] [get_bd_pins sume_osnt_10g_interface_0/pcspma_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_status_0] [get_bd_pins sume_osnt_10g_interface_0/mac_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_status_0] [get_bd_pins sume_osnt_10g_interface_0/pcspma_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/clear] [get_bd_pins sume_osnt_10g_interface_0/clear]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_pkt_count_0] [get_bd_pins sume_osnt_10g_interface_0/rx_pkt_count]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_pkt_count_0] [get_bd_pins sume_osnt_10g_interface_0/tx_pkt_count]

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_rx_config_1] [get_bd_pins sume_osnt_10g_interface_1/mac_rx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_tx_config_1] [get_bd_pins sume_osnt_10g_interface_1/mac_tx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_config_1] [get_bd_pins sume_osnt_10g_interface_1/pcspma_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_status_1] [get_bd_pins sume_osnt_10g_interface_1/mac_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_status_1] [get_bd_pins sume_osnt_10g_interface_1/pcspma_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/clear] [get_bd_pins sume_osnt_10g_interface_1/clear]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_pkt_count_1] [get_bd_pins sume_osnt_10g_interface_1/rx_pkt_count]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_pkt_count_1] [get_bd_pins sume_osnt_10g_interface_1/tx_pkt_count]

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_rx_config_2] [get_bd_pins sume_osnt_10g_interface_2/mac_rx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_tx_config_2] [get_bd_pins sume_osnt_10g_interface_2/mac_tx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_config_2] [get_bd_pins sume_osnt_10g_interface_2/pcspma_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_status_2] [get_bd_pins sume_osnt_10g_interface_2/mac_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_status_2] [get_bd_pins sume_osnt_10g_interface_2/pcspma_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/clear] [get_bd_pins sume_osnt_10g_interface_2/clear]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_pkt_count_2] [get_bd_pins sume_osnt_10g_interface_2/rx_pkt_count]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_pkt_count_2] [get_bd_pins sume_osnt_10g_interface_2/tx_pkt_count]

   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_rx_config_3] [get_bd_pins sume_osnt_10g_interface_3/mac_rx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_tx_config_3] [get_bd_pins sume_osnt_10g_interface_3/mac_tx_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_config_3] [get_bd_pins sume_osnt_10g_interface_3/pcspma_config]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/mac_status_3] [get_bd_pins sume_osnt_10g_interface_3/mac_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/pcspma_status_3] [get_bd_pins sume_osnt_10g_interface_3/pcspma_status]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/clear] [get_bd_pins sume_osnt_10g_interface_3/clear]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/rx_pkt_count_3] [get_bd_pins sume_osnt_10g_interface_3/rx_pkt_count]
   connect_bd_net [get_bd_pins osnt_sume_10g_axi_if_0/tx_pkt_count_3] [get_bd_pins sume_osnt_10g_interface_3/tx_pkt_count]

   # Restore current instance
   current_bd_instance $oldCurInst
}
