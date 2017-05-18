#
# Copyright (c) 2017 University of Cambridge
# Copyright (c) 2017 Jong Hun Han
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


# External ports connection
connect_bd_net [get_bd_ports pcie_7x_mgt_rxn] [get_bd_pins sume_osnt_dma/pcie_7x_mgt_rxn]	
connect_bd_net [get_bd_ports pcie_7x_mgt_rxp] [get_bd_pins sume_osnt_dma/pcie_7x_mgt_rxp]
connect_bd_net [get_bd_ports pcie_7x_mgt_txn] [get_bd_pins sume_osnt_dma/pcie_7x_mgt_txn]
connect_bd_net [get_bd_ports pcie_7x_mgt_txp] [get_bd_pins sume_osnt_dma/pcie_7x_mgt_txp]

connect_bd_net [get_bd_ports sys_clkp] [get_bd_pins sume_osnt_dma/pcie_sys_clkp]
connect_bd_net [get_bd_ports sys_clkn] [get_bd_pins sume_osnt_dma/pcie_sys_clkn]

connect_bd_net [get_bd_ports ddr3_clk_n] [get_bd_pins ddrclk_buf/IBUF_DS_N]
connect_bd_net [get_bd_ports ddr3_clk_p] [get_bd_pins ddrclk_buf/IBUF_DS_P]

connect_bd_net [get_bd_ports pcie_sys_resetn] [get_bd_pins sume_osnt_dma/pcie_sys_reset]

connect_bd_net [get_bd_ports reset] [get_bd_pins sys_clock_0/reset]
connect_bd_net [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_ports reset] [get_bd_pins sume_osnt_10g_interface/reset]
connect_bd_net [get_bd_ports reset] [get_bd_pins osnt_sume_qdrA_0/sys_rst]
connect_bd_net [get_bd_ports reset] [get_bd_pins osnt_sume_qdrC_0/sys_rst]
connect_bd_net [get_bd_ports reset] [get_bd_pins osnt_sume_ddr3A_0/sys_rst]
connect_bd_net [get_bd_ports reset] [get_bd_pins osnt_sume_ddr3B_0/sys_rst]

connect_bd_net [get_bd_ports fpga_sysclk_n] [get_bd_pins sysclk_buf/IBUF_DS_N]
connect_bd_net [get_bd_ports fpga_sysclk_p] [get_bd_pins sysclk_buf/IBUF_DS_P]

connect_bd_net [get_bd_ports sfp_refclk_n] [get_bd_pins sume_osnt_10g_interface/refclk_n]
connect_bd_net [get_bd_ports sfp_refclk_p] [get_bd_pins sume_osnt_10g_interface/refclk_p]

connect_bd_net [get_bd_pins ddrclk_buf/IBUF_OUT] [get_bd_pins osnt_sume_ddr3A_0/sys_clk_i]
connect_bd_net [get_bd_pins ddrclk_buf/IBUF_OUT] [get_bd_pins osnt_sume_ddr3B_0/sys_clk_i]
connect_bd_net [get_bd_pins sysclk_buf/IBUF_OUT] [get_bd_pins osnt_sume_ddr3A_0/clk_ref_i]
connect_bd_net [get_bd_pins sysclk_buf/IBUF_OUT] [get_bd_pins osnt_sume_ddr3B_0/clk_ref_i]

connect_bd_net [get_bd_pins sys_clock_0/clk_in1] [get_bd_pins sysclk_buf/IBUF_OUT]
connect_bd_net [get_bd_pins sys_clock_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]

connect_bd_net [get_bd_ports qdra_clk_p] [get_bd_pins osnt_sume_qdrA_0/sys_clk_p]
connect_bd_net [get_bd_ports qdra_clk_n] [get_bd_pins osnt_sume_qdrA_0/sys_clk_n]

connect_bd_net [get_bd_ports qdrc_clk_p] [get_bd_pins osnt_sume_qdrC_0/sys_clk_p]
connect_bd_net [get_bd_ports qdrc_clk_n] [get_bd_pins osnt_sume_qdrC_0/sys_clk_n]

connect_bd_net [get_bd_ports eth0_tx_disable] [get_bd_pins sume_osnt_10g_interface/tx_disable_0]
connect_bd_net [get_bd_ports eth0_rx_led] [get_bd_pins sume_osnt_10g_interface/rx_led_0]
connect_bd_net [get_bd_ports eth0_tx_led] [get_bd_pins sume_osnt_10g_interface/tx_led_0]
connect_bd_net [get_bd_ports eth0_rxp] [get_bd_pins sume_osnt_10g_interface/rxp_0]
connect_bd_net [get_bd_ports eth0_rxn] [get_bd_pins sume_osnt_10g_interface/rxn_0]
connect_bd_net [get_bd_ports eth0_txp] [get_bd_pins sume_osnt_10g_interface/txp_0]
connect_bd_net [get_bd_ports eth0_txn] [get_bd_pins sume_osnt_10g_interface/txn_0]
connect_bd_net [get_bd_ports eth0_abs] [get_bd_pins sume_osnt_10g_interface/tx_abs_0]
connect_bd_net [get_bd_ports eth0_tx_fault] [get_bd_pins sume_osnt_10g_interface/tx_fault_0]

connect_bd_net [get_bd_ports eth1_tx_disable] [get_bd_pins sume_osnt_10g_interface/tx_disable_1]
connect_bd_net [get_bd_ports eth1_rx_led] [get_bd_pins sume_osnt_10g_interface/rx_led_1]
connect_bd_net [get_bd_ports eth1_tx_led] [get_bd_pins sume_osnt_10g_interface/tx_led_1]
connect_bd_net [get_bd_ports eth1_rxp] [get_bd_pins sume_osnt_10g_interface/rxp_1]
connect_bd_net [get_bd_ports eth1_rxn] [get_bd_pins sume_osnt_10g_interface/rxn_1]
connect_bd_net [get_bd_ports eth1_txp] [get_bd_pins sume_osnt_10g_interface/txp_1]
connect_bd_net [get_bd_ports eth1_txn] [get_bd_pins sume_osnt_10g_interface/txn_1]
connect_bd_net [get_bd_ports eth1_abs] [get_bd_pins sume_osnt_10g_interface/tx_abs_1]
connect_bd_net [get_bd_ports eth1_tx_fault] [get_bd_pins sume_osnt_10g_interface/tx_fault_1]

connect_bd_net [get_bd_ports eth2_tx_disable] [get_bd_pins sume_osnt_10g_interface/tx_disable_2]
connect_bd_net [get_bd_ports eth2_rx_led] [get_bd_pins sume_osnt_10g_interface/rx_led_2]
connect_bd_net [get_bd_ports eth2_tx_led] [get_bd_pins sume_osnt_10g_interface/tx_led_2]
connect_bd_net [get_bd_ports eth2_rxp] [get_bd_pins sume_osnt_10g_interface/rxp_2]
connect_bd_net [get_bd_ports eth2_rxn] [get_bd_pins sume_osnt_10g_interface/rxn_2]
connect_bd_net [get_bd_ports eth2_txp] [get_bd_pins sume_osnt_10g_interface/txp_2]
connect_bd_net [get_bd_ports eth2_txn] [get_bd_pins sume_osnt_10g_interface/txn_2]
connect_bd_net [get_bd_ports eth2_abs] [get_bd_pins sume_osnt_10g_interface/tx_abs_2]
connect_bd_net [get_bd_ports eth2_tx_fault] [get_bd_pins sume_osnt_10g_interface/tx_fault_2]

connect_bd_net [get_bd_ports eth3_tx_disable] [get_bd_pins sume_osnt_10g_interface/tx_disable_3]
connect_bd_net [get_bd_ports eth3_rx_led] [get_bd_pins sume_osnt_10g_interface/rx_led_3]
connect_bd_net [get_bd_ports eth3_tx_led] [get_bd_pins sume_osnt_10g_interface/tx_led_3]
connect_bd_net [get_bd_ports eth3_rxp] [get_bd_pins sume_osnt_10g_interface/rxp_3]
connect_bd_net [get_bd_ports eth3_rxn] [get_bd_pins sume_osnt_10g_interface/rxn_3]
connect_bd_net [get_bd_ports eth3_txp] [get_bd_pins sume_osnt_10g_interface/txp_3]
connect_bd_net [get_bd_ports eth3_txn] [get_bd_pins sume_osnt_10g_interface/txn_3]
connect_bd_net [get_bd_ports eth3_abs] [get_bd_pins sume_osnt_10g_interface/tx_abs_3]
connect_bd_net [get_bd_ports eth3_tx_fault] [get_bd_pins sume_osnt_10g_interface/tx_fault_3]

connect_bd_net [get_bd_ports iic_reset] [get_bd_pins axi_iic_0/gpo]

connect_bd_intf_net [get_bd_intf_ports uart] [get_bd_intf_pins axi_uartlite_0/UART]
connect_bd_intf_net [get_bd_intf_ports iic_fpga] [get_bd_intf_pins axi_iic_0/IIC]

# 100MHz clock scheme - address mapped registers
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins mbsys/Clk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_uartlite_0/s_axi_aclk] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_iic_0/s_axi_aclk] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins sume_osnt_dma/m_axi_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/AClk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/S00_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/S01_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/M00_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/M01_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/M02_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M03_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M04_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M05_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M06_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M07_ACLK] 
connect_bd_net [get_bd_pins sume_osnt_10g_interface/clk156_out] [get_bd_pins axi_interconnect_0/M08_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M09_ACLK] 
connect_bd_net [get_bd_pins sume_osnt_10g_interface/clk156_out] [get_bd_pins axi_interconnect_0/M10_ACLK] 
connect_bd_net [get_bd_pins osnt_sume_qdrA_0/clk] [get_bd_pins axi_interconnect_0/M11_ACLK] 
connect_bd_net [get_bd_pins osnt_sume_qdrC_0/clk] [get_bd_pins axi_interconnect_0/M12_ACLK] 
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/clk] [get_bd_pins axi_interconnect_0/M13_ACLK] 
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/clk] [get_bd_pins axi_interconnect_0/M14_ACLK] 

# 160Mhz clock scheme - data stream
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins sume_osnt_dma/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins sume_osnt_10g_interface/core_clk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_nic_output_port_lookup_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_input_arbiter_0/axis_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_inter_packet_delay_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_rate_limiter_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_extract_metadata_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/s_axi_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_inter_packet_delay_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_rate_limiter_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_extract_metadata_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/axis_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_packet_cutter_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sume_osnt_10g_interface/clk156_out] [get_bd_pins osnt_sume_timestamp_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_monitoring_output_port_lookup_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_endianess_manager_0/ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_bram_output_queues_0/axis_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_qdrA_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_qdrC_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_ddr3A_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_ddr3B_0/axis_aclk]

# Reset module connection
connect_bd_net [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst] [get_bd_pins mbsys/Debug_SYS_Rst]
connect_bd_net [get_bd_pins proc_sys_reset_0/mb_reset] [get_bd_pins mbsys/Reset]
connect_bd_net [get_bd_pins proc_sys_reset_0/bus_struct_reset] [get_bd_pins mbsys/LMB_Rst]

connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S01_ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M02_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M03_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M04_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M05_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M06_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M07_ARESETN]
connect_bd_net [get_bd_pins sume_osnt_10g_interface/aresetn_clk156_out] [get_bd_pins axi_interconnect_0/M08_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M09_ARESETN]
connect_bd_net [get_bd_pins sume_osnt_10g_interface/aresetn_clk156_out] [get_bd_pins axi_interconnect_0/M10_ARESETN]
connect_bd_net [get_bd_pins osnt_sume_qdrA_0/resetn] [get_bd_pins axi_interconnect_0/M11_ARESETN]
connect_bd_net [get_bd_pins osnt_sume_qdrC_0/resetn] [get_bd_pins axi_interconnect_0/M12_ARESETN]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/resetn] [get_bd_pins axi_interconnect_0/M13_ARESETN]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/resetn] [get_bd_pins axi_interconnect_0/M14_ARESETN]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins mbsys/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins sume_osnt_dma/m_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins sume_osnt_dma/axis_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins sume_osnt_10g_interface/core_resetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_nic_output_port_lookup_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_input_arbiter_0/axis_aresetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_inter_packet_delay_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_rate_limiter_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_extract_metadata_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/s_axi_aresetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_inter_packet_delay_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_rate_limiter_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_extract_metadata_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/axis_aresetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_packet_cutter_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins sume_osnt_10g_interface/aresetn_clk156_out] [get_bd_pins osnt_sume_timestamp_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_monitoring_output_port_lookup_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_bram_output_queues_0/axis_resetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_endianess_manager_0/ARESETN]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_qdrA_0/axis_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_qdrC_0/axis_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_ddr3A_0/axis_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_ddr3B_0/axis_aresetn]

# Axi-Lite bus interface connection
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins mbsys/M_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins sume_osnt_dma/m_axi_lite] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins mbsys/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_iic_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s_axi] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins osnt_sume_rate_limiter_0/s_axi] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins osnt_sume_extract_metadata_0/s_axi] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/s_axi]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M07_AXI] [get_bd_intf_pins osnt_sume_packet_cutter_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M08_AXI] [get_bd_intf_pins osnt_sume_timestamp_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M09_AXI] [get_bd_intf_pins osnt_sume_monitoring_output_port_lookup_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M10_AXI] [get_bd_intf_pins sume_osnt_10g_interface/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M11_AXI] [get_bd_intf_pins osnt_sume_qdrA_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M12_AXI] [get_bd_intf_pins osnt_sume_qdrC_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M13_AXI] [get_bd_intf_pins osnt_sume_ddr3A_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M14_AXI] [get_bd_intf_pins osnt_sume_ddr3B_0/S_AXI] 

# Interrupt connection
connect_bd_net [get_bd_pins mbsys/In0] [get_bd_pins axi_iic_0/iic2intc_irpt]
connect_bd_net [get_bd_pins mbsys/In1] [get_bd_pins axi_uartlite_0/interrupt]

# Axi-stream data interface connection
connect_bd_intf_net [get_bd_intf_pins sume_osnt_10g_interface/m0_axis] [get_bd_intf_pins osnt_sume_input_arbiter_0/s0_axis]
connect_bd_intf_net [get_bd_intf_pins sume_osnt_10g_interface/m1_axis] [get_bd_intf_pins osnt_sume_input_arbiter_0/s1_axis]
connect_bd_intf_net [get_bd_intf_pins sume_osnt_10g_interface/m2_axis] [get_bd_intf_pins osnt_sume_input_arbiter_0/s2_axis]
connect_bd_intf_net [get_bd_intf_pins sume_osnt_10g_interface/m3_axis] [get_bd_intf_pins osnt_sume_input_arbiter_0/s3_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_input_arbiter_0/m_axis] [get_bd_intf_pins osnt_sume_endianess_manager_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_packet_cutter_0/M_AXIS] [get_bd_intf_pins osnt_sume_endianess_manager_0/S_AXIS_INT]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_endianess_manager_0/M_AXIS] [get_bd_intf_pins osnt_sume_bram_output_queues_0/s_axis] 
connect_bd_intf_net [get_bd_intf_pins osnt_sume_endianess_manager_0/M_AXIS_INT] [get_bd_intf_pins osnt_sume_monitoring_output_port_lookup_0/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_monitoring_output_port_lookup_0/M_AXIS] [get_bd_intf_pins osnt_sume_packet_cutter_0/S_AXIS]

#connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m0_axis] [get_bd_intf_pins sume_osnt_10g_interface/s0_axis]
#connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m1_axis] [get_bd_intf_pins sume_osnt_10g_interface/s1_axis]
#connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m2_axis] [get_bd_intf_pins sume_osnt_10g_interface/s2_axis]
#connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m3_axis] [get_bd_intf_pins sume_osnt_10g_interface/s3_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m4_axis] [get_bd_intf_pins sume_osnt_dma/s_axis]

connect_bd_net [get_bd_pins osnt_sume_timestamp_0/STAMP_COUNTER] [get_bd_pins osnt_sume_monitoring_output_port_lookup_0/STAMP_COUNTER]
connect_bd_net [get_bd_pins osnt_sume_timestamp_0/STAMP_COUNTER] [get_bd_pins sume_osnt_10g_interface/timestamp_156]

connect_bd_net [get_bd_pins osnt_sume_timestamp_0/PPS_RX] [get_bd_pins gps_signal]
connect_bd_net [get_bd_pins osnt_sume_timestamp_0/ts_pulse_out] [get_bd_pins ts_pulse_0]
connect_bd_net [get_bd_pins osnt_sume_timestamp_0/ts_pulse_in] [get_bd_pins ts_pulse_1]

connect_bd_intf_net [get_bd_intf_pins sume_osnt_dma/m_axis] [get_bd_intf_pins osnt_sume_extract_metadata_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extract_metadata_0/m_axis] [get_bd_intf_pins osnt_sume_nic_output_port_lookup_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_nic_output_port_lookup_0/m_axis] [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/s_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m0_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s0_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m1_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s1_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m2_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s2_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m3_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s3_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m0_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s0_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m1_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s1_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m2_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s2_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m3_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s3_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_rate_limiter_0/m0_axis] [get_bd_intf_pins sume_osnt_10g_interface/s0_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_rate_limiter_0/m1_axis] [get_bd_intf_pins sume_osnt_10g_interface/s1_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_rate_limiter_0/m2_axis] [get_bd_intf_pins sume_osnt_10g_interface/s2_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_rate_limiter_0/m3_axis] [get_bd_intf_pins sume_osnt_10g_interface/s3_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m00_axis] [get_bd_intf_pins osnt_sume_qdrA_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/s00_axis] [get_bd_intf_pins osnt_sume_qdrA_0/m_axis]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/sw_rst] [get_bd_pins osnt_sume_qdrA_0/sw_rst]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q0_start_replay] [get_bd_pins osnt_sume_qdrA_0/start_replay]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q0_replay_count] [get_bd_pins osnt_sume_qdrA_0/replay_count]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q0_wr_done] [get_bd_pins osnt_sume_qdrA_0/wr_done]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m01_axis] [get_bd_intf_pins osnt_sume_qdrC_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/s01_axis] [get_bd_intf_pins osnt_sume_qdrC_0/m_axis]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/sw_rst] [get_bd_pins osnt_sume_qdrC_0/sw_rst]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q1_start_replay] [get_bd_pins osnt_sume_qdrC_0/start_replay]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q1_replay_count] [get_bd_pins osnt_sume_qdrC_0/replay_count]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q1_wr_done] [get_bd_pins osnt_sume_qdrC_0/wr_done]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m02_axis] [get_bd_intf_pins osnt_sume_ddr3A_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/s02_axis] [get_bd_intf_pins osnt_sume_ddr3A_0/m_axis]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/sw_rst] [get_bd_pins osnt_sume_ddr3A_0/sw_rst]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q2_start_replay] [get_bd_pins osnt_sume_ddr3A_0/start_replay]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q2_replay_count] [get_bd_pins osnt_sume_ddr3A_0/replay_count]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q2_wr_done] [get_bd_pins osnt_sume_ddr3A_0/wr_done]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/m03_axis] [get_bd_intf_pins osnt_sume_ddr3B_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_extmem_pcap_replay_engine_0/s03_axis] [get_bd_intf_pins osnt_sume_ddr3B_0/m_axis]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/sw_rst] [get_bd_pins osnt_sume_ddr3B_0/sw_rst]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q3_start_replay] [get_bd_pins osnt_sume_ddr3B_0/start_replay]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q3_replay_count] [get_bd_pins osnt_sume_ddr3B_0/replay_count]
connect_bd_net [get_bd_pins osnt_sume_extmem_pcap_replay_engine_0/q3_wr_done] [get_bd_pins osnt_sume_ddr3B_0/wr_done]

