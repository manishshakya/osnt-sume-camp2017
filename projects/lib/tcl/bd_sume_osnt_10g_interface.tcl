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


proc create_hier_cell_sume_osnt_10g_interface { parentCell coreName sharedLogic srcPort tdataWidth } {

   # Check argument
   if { $parentCell eq "" || $coreName eq "" || $sharedLogic eq "" || $srcPort eq "" || $tdataWidth eq "" } {
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

   if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true" } {
      set supportLevel 1
   } else {
      set supportLevel 0
   }

   if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true"  } {
      create_bd_pin -dir I reset
      create_bd_pin -dir I -type clk refclk_p
      create_bd_pin -dir I -type clk refclk_n
   }
   
   create_bd_pin -dir I -type clk core_clk
   create_bd_pin -dir I core_resetn

   create_bd_pin -dir I rxp
   create_bd_pin -dir I rxn
   create_bd_pin -dir I tx_abs
   create_bd_pin -dir I tx_fault 
   create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis

   create_bd_pin -dir I -from 31 -to 0 rx_ts_pos 
   create_bd_pin -dir I -from 31 -to 0 tx_ts_pos

   create_bd_pin -dir I -from 63 -to 0 timestamp_156

   create_bd_pin -dir I -from 79 -to 0 mac_rx_config
   create_bd_pin -dir I -from 79 -to 0 mac_tx_config
   create_bd_pin -dir I -from 535 -to 0 pcspma_config

   create_bd_pin -dir O -from 1 -to 0 mac_status
   create_bd_pin -dir O -from 7 -to 0 pcspma_status

   create_bd_pin -dir I clear
   create_bd_pin -dir O -from 31 -to 0 rx_pkt_count
   create_bd_pin -dir O -from 31 -to 0 tx_pkt_count

   if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true"  } {
      create_bd_pin -dir O txusrclk_out
      create_bd_pin -dir O txusrclk2_out
      create_bd_pin -dir O gttxreset_out 
      create_bd_pin -dir O gtrxreset_out
      create_bd_pin -dir O txuserrdy_out
      create_bd_pin -dir O coreclk_out
      create_bd_pin -dir O rxrecclk_out
      create_bd_pin -dir O areset_datapathclk_out 
      create_bd_pin -dir O resetdone_out
      create_bd_pin -dir O reset_counter_done_out 
      create_bd_pin -dir O qplllock_out 
      create_bd_pin -dir O qplloutclk_out 
      create_bd_pin -dir O qplloutrefclk_out 
   } else {
      create_bd_pin -dir I areset
      create_bd_pin -dir I -type clk coreclk
      create_bd_pin -dir I txusrclk
      create_bd_pin -dir I txusrclk2
      create_bd_pin -dir I txuserrdy
      create_bd_pin -dir I gttxreset
      create_bd_pin -dir I gtrxreset
      create_bd_pin -dir I reset_counter_done 
      create_bd_pin -dir I qplllock
      create_bd_pin -dir I qplloutclk
      create_bd_pin -dir I qplloutrefclk

      create_bd_pin -dir O tx_resetdone
      create_bd_pin -dir O rx_resetdone
   }

   create_bd_pin -dir O txp
   create_bd_pin -dir O txn
   create_bd_pin -dir O tx_disable
   create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis


   create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.1 axi_10g_ethernet_0
   set_property -dict [list CONFIG.Management_Interface {false}] [get_bd_cells axi_10g_ethernet_0]
   set_property -dict [list CONFIG.base_kr {BASE-R}] [get_bd_cells axi_10g_ethernet_0]
   set_property -dict [list CONFIG.SupportLevel $supportLevel] [get_bd_cells axi_10g_ethernet_0]
   set_property -dict [list CONFIG.autonegotiation {0}] [get_bd_cells axi_10g_ethernet_0]
   set_property -dict [list CONFIG.fec {0}] [get_bd_cells axi_10g_ethernet_0]
   set_property -dict [list CONFIG.Statistics_Gathering {0}] [get_bd_cells axi_10g_ethernet_0]

   create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0
   set_property -dict [list CONFIG.TDATA_NUM_BYTES {8}] [get_bd_cells axis_data_fifo_0]
   set_property -dict [list CONFIG.TUSER_WIDTH {128}] [get_bd_cells axis_data_fifo_0]
   set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells axis_data_fifo_0]
   set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells axis_data_fifo_0]

   create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_1
   set_property -dict [list CONFIG.TDATA_NUM_BYTES {8}] [get_bd_cells axis_data_fifo_1]
   set_property -dict [list CONFIG.TUSER_WIDTH {128}] [get_bd_cells axis_data_fifo_1]
   set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells axis_data_fifo_1]
   set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells axis_data_fifo_1]

   create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_10g_rx_queue:1.00 osnt_sume_10g_rx_queue_0
   set_property -dict [list CONFIG.SRC_PORT_VAL $srcPort] [get_bd_cells osnt_sume_10g_rx_queue_0]

   create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_10g_tx_queue:1.00 osnt_sume_10g_tx_queue_0

   connect_bd_net [get_bd_pins axi_10g_ethernet_0/pcspma_status] [get_bd_pins pcspma_status]
   connect_bd_net [get_bd_pins axi_10g_ethernet_0/mac_status_vector] [get_bd_pins mac_status]
   connect_bd_net [get_bd_pins pcspma_config] [get_bd_pins axi_10g_ethernet_0/pcs_pma_configuration_vector]
   connect_bd_net [get_bd_pins mac_tx_config] [get_bd_pins axi_10g_ethernet_0/mac_tx_configuration_vector]
   connect_bd_net [get_bd_pins mac_rx_config] [get_bd_pins axi_10g_ethernet_0/mac_rx_configuration_vector]

   connect_bd_net [get_bd_pins osnt_sume_10g_rx_queue_0/clear] [get_bd_pins clear]
   connect_bd_net [get_bd_pins osnt_sume_10g_rx_queue_0/rx_pkt_count] [get_bd_pins rx_pkt_count]

   connect_bd_net [get_bd_pins osnt_sume_10g_tx_queue_0/clear] [get_bd_pins clear]
   connect_bd_net [get_bd_pins osnt_sume_10g_tx_queue_0/tx_pkt_count] [get_bd_pins tx_pkt_count]

   set const_hex_value 5f24006

   proc hex2dec_tcl {largeHex} {
      set result 0
      foreach hexDigit [split $largeHex {}] {
         set value 0x$hexDigit
         set result [expr {16*$result + $value}]
      }
      return $result
   }

   #set vec_value [hex2dec_tcl $const_hex_value]
   set vec_value 2

   #create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 configuration_vector_0
   #set_property -dict [list CONFIG.CONST_WIDTH {80}] [get_bd_cells configuration_vector_0]
   #set_property -dict [list CONFIG.CONST_VAL $vec_value] [get_bd_cells configuration_vector_0]


   create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 tx_abs_inverter_0
   set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells tx_abs_inverter_0]
   set_property -dict [list CONFIG.C_OPERATION {not}] [get_bd_cells tx_abs_inverter_0]

   create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 areset_inverter_0
   set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells areset_inverter_0]
   set_property -dict [list CONFIG.C_OPERATION {not}] [get_bd_cells areset_inverter_0]


   set convWidth [expr $tdataWidth/8]

   if { $tdataWidth ne "64" } {

   create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0
   set_property -dict [list CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER \
      CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER \
      CONFIG.TUSER_BITS_PER_BYTE.VALUE_SRC USER] [get_bd_cells axis_dwidth_converter_0]
   set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {8} CONFIG.M_TDATA_NUM_BYTES $convWidth \
      CONFIG.TUSER_BITS_PER_BYTE {16} CONFIG.HAS_TLAST {1} CONFIG.HAS_TSTRB {0} \
      CONFIG.HAS_TKEEP {1} CONFIG.HAS_MI_TKEEP {1}] [get_bd_cells axis_dwidth_converter_0]

   set preTuser [expr $tdataWidth*2]

   create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_1
   set_property -dict [list CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER \
      CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER \
      CONFIG.TUSER_BITS_PER_BYTE.VALUE_SRC USER] [get_bd_cells axis_dwidth_converter_1]
   set_property -dict [list CONFIG.S_TDATA_NUM_BYTES $convWidth CONFIG.M_TDATA_NUM_BYTES {8} \
      CONFIG.TUSER_BITS_PER_BYTE {16} CONFIG.HAS_TLAST {1} CONFIG.HAS_TSTRB {0} \
      CONFIG.HAS_TKEEP {1} CONFIG.HAS_MI_TKEEP {1}] [get_bd_cells axis_dwidth_converter_1]

   }

   # Connection to bd pins for wrapper
   if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true"  } {
      connect_bd_net [get_bd_pins reset] [get_bd_pins axi_10g_ethernet_0/reset]
      connect_bd_net [get_bd_pins refclk_p] [get_bd_pins axi_10g_ethernet_0/refclk_p]
      connect_bd_net [get_bd_pins refclk_n] [get_bd_pins axi_10g_ethernet_0/refclk_n]
   }

   connect_bd_net [get_bd_pins rxp] [get_bd_pins axi_10g_ethernet_0/rxp]
   connect_bd_net [get_bd_pins rxn] [get_bd_pins axi_10g_ethernet_0/rxn]

   connect_bd_net [get_bd_pins areset_inverter_0/Res] [get_bd_pins axi_10g_ethernet_0/tx_axis_aresetn]
   connect_bd_net [get_bd_pins areset_inverter_0/Res] [get_bd_pins axi_10g_ethernet_0/rx_axis_aresetn]
   connect_bd_net [get_bd_pins tx_abs] [get_bd_pins tx_abs_inverter_0/Op1]
   connect_bd_net [get_bd_pins tx_abs_inverter_0/Res] [get_bd_pins axi_10g_ethernet_0/signal_detect]
   connect_bd_net [get_bd_pins tx_fault] [get_bd_pins axi_10g_ethernet_0/tx_fault]

   if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true"  } {
      connect_bd_net [get_bd_pins txusrclk_out] [get_bd_pins axi_10g_ethernet_0/txusrclk_out]
      connect_bd_net [get_bd_pins txusrclk2_out] [get_bd_pins axi_10g_ethernet_0/txusrclk2_out]
      connect_bd_net [get_bd_pins gttxreset_out] [get_bd_pins axi_10g_ethernet_0/gttxreset_out]
      connect_bd_net [get_bd_pins gtrxreset_out] [get_bd_pins axi_10g_ethernet_0/gtrxreset_out]
      connect_bd_net [get_bd_pins txuserrdy_out] [get_bd_pins axi_10g_ethernet_0/txuserrdy_out]

      connect_bd_net [get_bd_pins coreclk_out] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
      connect_bd_net [get_bd_pins rxrecclk_out] [get_bd_pins axi_10g_ethernet_0/rxrecclk_out]
      connect_bd_net [get_bd_pins areset_datapathclk_out] [get_bd_pins axi_10g_ethernet_0/areset_datapathclk_out]
      connect_bd_net [get_bd_pins areset_datapathclk_out] [get_bd_pins areset_inverter_0/Op1]

      connect_bd_net [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins osnt_sume_10g_rx_queue_0/axis_aclk]
      connect_bd_net [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins osnt_sume_10g_tx_queue_0/axis_aclk]

      connect_bd_net [get_bd_pins resetdone_out] [get_bd_pins axi_10g_ethernet_0/resetdone_out]
      connect_bd_net [get_bd_pins reset_counter_done_out] [get_bd_pins axi_10g_ethernet_0/reset_counter_done_out]
      connect_bd_net [get_bd_pins qplllock_out] [get_bd_pins axi_10g_ethernet_0/qplllock_out]
      connect_bd_net [get_bd_pins qplloutclk_out] [get_bd_pins axi_10g_ethernet_0/qplloutclk_out]
      connect_bd_net [get_bd_pins qplloutrefclk_out] [get_bd_pins axi_10g_ethernet_0/qplloutrefclk_out]

      connect_bd_net [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins axi_10g_ethernet_0/dclk]
      connect_bd_net [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
      connect_bd_net [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins axis_data_fifo_1/m_axis_aclk]


   } else {
      connect_bd_net [get_bd_pins areset] [get_bd_pins axi_10g_ethernet_0/areset_coreclk]
      connect_bd_net [get_bd_pins areset] [get_bd_pins axi_10g_ethernet_0/areset]
      
      connect_bd_net [get_bd_pins coreclk] [get_bd_pins axi_10g_ethernet_0/dclk]
      connect_bd_net [get_bd_pins coreclk] [get_bd_pins axi_10g_ethernet_0/coreclk]
      connect_bd_net [get_bd_pins areset] [get_bd_pins areset_inverter_0/Op1]

      connect_bd_net [get_bd_pins coreclk] [get_bd_pins osnt_sume_10g_rx_queue_0/axis_aclk]
      connect_bd_net [get_bd_pins coreclk] [get_bd_pins osnt_sume_10g_tx_queue_0/axis_aclk]

      connect_bd_net [get_bd_pins txusrclk] [get_bd_pins axi_10g_ethernet_0/txusrclk]
      connect_bd_net [get_bd_pins txusrclk2] [get_bd_pins axi_10g_ethernet_0/txusrclk2]
      connect_bd_net [get_bd_pins txuserrdy] [get_bd_pins axi_10g_ethernet_0/txuserrdy]
      connect_bd_net [get_bd_pins gttxreset] [get_bd_pins axi_10g_ethernet_0/gttxreset]
      connect_bd_net [get_bd_pins gtrxreset] [get_bd_pins axi_10g_ethernet_0/gtrxreset]
      connect_bd_net [get_bd_pins reset_counter_done] [get_bd_pins axi_10g_ethernet_0/reset_counter_done]
      connect_bd_net [get_bd_pins qplllock] [get_bd_pins axi_10g_ethernet_0/qplllock]
      connect_bd_net [get_bd_pins qplloutclk] [get_bd_pins axi_10g_ethernet_0/qplloutclk]
      connect_bd_net [get_bd_pins qplloutrefclk] [get_bd_pins axi_10g_ethernet_0/qplloutrefclk]

      connect_bd_net [get_bd_pins tx_resetdone] [get_bd_pins axi_10g_ethernet_0/tx_resetdone]
      connect_bd_net [get_bd_pins rx_resetdone] [get_bd_pins axi_10g_ethernet_0/rx_resetdone]

      connect_bd_net [get_bd_pins coreclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
      connect_bd_net [get_bd_pins coreclk] [get_bd_pins axis_data_fifo_1/m_axis_aclk]
  }


   connect_bd_net [get_bd_pins core_clk] [get_bd_pins axis_data_fifo_0/m_axis_aclk]
   connect_bd_net [get_bd_pins core_clk] [get_bd_pins axis_data_fifo_1/s_axis_aclk]

   if { $tdataWidth ne "64" } {
      connect_bd_net [get_bd_pins core_clk] [get_bd_pins axis_dwidth_converter_0/aclk]
      connect_bd_net [get_bd_pins core_clk] [get_bd_pins axis_dwidth_converter_1/aclk]
   }

   connect_bd_net [get_bd_pins core_resetn] [get_bd_pins axis_data_fifo_0/m_axis_aresetn]
   connect_bd_net [get_bd_pins core_resetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn]
   connect_bd_net [get_bd_pins areset_inverter_0/Res] [get_bd_pins osnt_sume_10g_rx_queue_0/axis_resetn]
   connect_bd_net [get_bd_pins areset_inverter_0/Res] [get_bd_pins osnt_sume_10g_tx_queue_0/axis_resetn]

   connect_bd_net [get_bd_pins areset_inverter_0/Res] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]
   connect_bd_net [get_bd_pins areset_inverter_0/Res] [get_bd_pins axis_data_fifo_1/m_axis_aresetn]

   if { $tdataWidth ne "64" } {
      connect_bd_net [get_bd_pins core_resetn] [get_bd_pins axis_dwidth_converter_0/aresetn]
      connect_bd_net [get_bd_pins core_resetn] [get_bd_pins axis_dwidth_converter_1/aresetn]
   } 

   connect_bd_net [get_bd_pins txp] [get_bd_pins axi_10g_ethernet_0/txp]
   connect_bd_net [get_bd_pins txn] [get_bd_pins axi_10g_ethernet_0/txn]
   connect_bd_net [get_bd_pins tx_disable] [get_bd_pins axi_10g_ethernet_0/tx_disable]

   # rx data path
   connect_bd_intf_net [get_bd_intf_pins axi_10g_ethernet_0/m_axis_rx] [get_bd_intf_pins osnt_sume_10g_rx_queue_0/s_axis]
   connect_bd_intf_net [get_bd_intf_pins osnt_sume_10g_rx_queue_0/m_axis] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
   if { $tdataWidth ne "64" } {
      connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
      connect_bd_intf_net [get_bd_intf_pins m_axis] [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]
   } else {
      connect_bd_intf_net [get_bd_intf_pins m_axis] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
   }

   connect_bd_net [get_bd_pins axi_10g_ethernet_0/rx_statistics_valid] [get_bd_pins osnt_sume_10g_rx_queue_0/rx_stat_valid]
   connect_bd_net [get_bd_pins axi_10g_ethernet_0/rx_statistics_vector] [get_bd_pins osnt_sume_10g_rx_queue_0/rx_stat_vector]
   connect_bd_net [get_bd_pins rx_ts_pos] [get_bd_pins osnt_sume_10g_rx_queue_0/rx_ts_pos]
   connect_bd_net [get_bd_pins timestamp_156] [get_bd_pins osnt_sume_10g_rx_queue_0/timestamp_156]
   
   # tx data path 
   if { $tdataWidth ne "64" } {
      connect_bd_intf_net [get_bd_intf_pins s_axis] [get_bd_intf_pins axis_dwidth_converter_1/S_AXIS]
      connect_bd_intf_net [get_bd_intf_pins axis_dwidth_converter_1/M_AXIS] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
   } else {
      connect_bd_intf_net [get_bd_intf_pins s_axis] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
   }

   connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_1/M_AXIS] [get_bd_intf_pins osnt_sume_10g_tx_queue_0/s_axis]
   connect_bd_intf_net [get_bd_intf_pins osnt_sume_10g_tx_queue_0/m_axis] [get_bd_intf_pins axi_10g_ethernet_0/s_axis_tx]

   connect_bd_net [get_bd_pins tx_ts_pos] [get_bd_pins osnt_sume_10g_tx_queue_0/tx_ts_pos]
   connect_bd_net [get_bd_pins timestamp_156] [get_bd_pins osnt_sume_10g_tx_queue_0/timestamp_156]

   # Restore current instance
   current_bd_instance $oldCurInst
}
