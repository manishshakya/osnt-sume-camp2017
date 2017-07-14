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


#Create system input and output ports
create_bd_port -dir I -type clk fpga_sysclk_n
create_bd_port -dir I -type clk fpga_sysclk_p
set_property CONFIG.FREQ_HZ 200000000 [get_bd_ports fpga_sysclk_p]
set_property CONFIG.FREQ_HZ 200000000 [get_bd_ports fpga_sysclk_n]

create_bd_port -dir I -type rst reset
set_property -dict [list CONFIG.POLARITY {ACTIVE_HIGH}] [get_bd_ports reset]
create_bd_port -dir I sfp_refclk_n
create_bd_port -dir I sfp_refclk_p

create_bd_port -dir I gps_signal
create_bd_port -dir O gps_signal_dir
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 gps_signal_dir_0
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells gps_signal_dir_0]
connect_bd_net [get_bd_ports gps_signal_dir] [get_bd_pins gps_signal_dir_0/dout]

create_bd_port -dir O ts_pulse_0
create_bd_port -dir O ts_pulse_dir_0 
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 ts_pulse_dir_0
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells ts_pulse_dir_0]
connect_bd_net [get_bd_ports ts_pulse_dir_0] [get_bd_pins ts_pulse_dir_0/dout]

create_bd_port -dir O ts_pulse_1
create_bd_port -dir O ts_pulse_dir_1 
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 ts_pulse_dir_1
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells ts_pulse_dir_1]
connect_bd_net [get_bd_ports ts_pulse_dir_1] [get_bd_pins ts_pulse_dir_1/dout]

create_bd_port -dir O pmod_en 
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 pmod_en_0
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells pmod_en_0]
connect_bd_net [get_bd_ports pmod_en] [get_bd_pins pmod_en_0/dout]

create_bd_port -dir O eth0_rx_led
create_bd_port -dir O eth0_tx_led
create_bd_port -dir I eth0_rxp
create_bd_port -dir I eth0_rxn
create_bd_port -dir O eth0_txp
create_bd_port -dir O eth0_txn
create_bd_port -dir O eth0_tx_disable
create_bd_port -dir I eth0_abs
create_bd_port -dir I eth0_tx_fault

create_bd_port -dir O eth1_rx_led
create_bd_port -dir O eth1_tx_led
create_bd_port -dir I eth1_rxp
create_bd_port -dir I eth1_rxn
create_bd_port -dir O eth1_txp
create_bd_port -dir O eth1_txn
create_bd_port -dir O eth1_tx_disable
create_bd_port -dir I eth1_abs
create_bd_port -dir I eth1_tx_fault

create_bd_port -dir O eth2_rx_led
create_bd_port -dir O eth2_tx_led
create_bd_port -dir I eth2_rxp
create_bd_port -dir I eth2_rxn
create_bd_port -dir O eth2_txp
create_bd_port -dir O eth2_txn
create_bd_port -dir O eth2_tx_disable
create_bd_port -dir I eth2_abs
create_bd_port -dir I eth2_tx_fault

create_bd_port -dir O eth3_rx_led
create_bd_port -dir O eth3_tx_led
create_bd_port -dir I eth3_rxp
create_bd_port -dir I eth3_rxn
create_bd_port -dir O eth3_txp
create_bd_port -dir O eth3_txn
create_bd_port -dir O eth3_tx_disable
create_bd_port -dir I eth3_abs
create_bd_port -dir I eth3_tx_fault

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_fpga
create_bd_port -dir O -from 1 -to 0 iic_reset

create_bd_port -dir I -from 0 -to 7 pcie_7x_mgt_rxn
create_bd_port -dir I -from 0 -to 7 pcie_7x_mgt_rxp
create_bd_port -dir O -from 0 -to 7 pcie_7x_mgt_txn
create_bd_port -dir O -from 0 -to 7 pcie_7x_mgt_txp

create_bd_port -dir I -type clk sys_clkp
create_bd_port -dir I -type clk sys_clkn
create_bd_port -dir I pcie_sys_resetn


create_bd_port -dir I -type clk qdra_clk_p
create_bd_port -dir I -type clk qdra_clk_n

create_bd_port -dir I qdraiip_cq_p
create_bd_port -dir I qdraiip_cq_n
create_bd_port -dir I -from 0 -to 35 qdraiip_q
create_bd_port -dir IO qdraiip_k_p
create_bd_port -dir IO qdraiip_k_n
create_bd_port -dir O -from 0 -to 35 qdraiip_d
create_bd_port -dir O -from 0 -to 18 qdraiip_sa
create_bd_port -dir O qdraiip_w_n
create_bd_port -dir O qdraiip_r_n
create_bd_port -dir O -from 0 -to 3 qdraiip_bw_n
create_bd_port -dir O qdraiip_dll_off_n

connect_bd_net [get_bd_ports qdraiip_cq_p] [get_bd_pins osnt_sume_qdrA_0/qdriip_cq_p]
connect_bd_net [get_bd_ports qdraiip_cq_n] [get_bd_pins osnt_sume_qdrA_0/qdriip_cq_n]
connect_bd_net [get_bd_ports qdraiip_q] [get_bd_pins osnt_sume_qdrA_0/qdriip_q]
connect_bd_net [get_bd_ports qdraiip_k_p] [get_bd_pins osnt_sume_qdrA_0/qdriip_k_p]
connect_bd_net [get_bd_ports qdraiip_k_n] [get_bd_pins osnt_sume_qdrA_0/qdriip_k_n]
connect_bd_net [get_bd_ports qdraiip_d] [get_bd_pins osnt_sume_qdrA_0/qdriip_d]
connect_bd_net [get_bd_ports qdraiip_sa] [get_bd_pins osnt_sume_qdrA_0/qdriip_sa]
connect_bd_net [get_bd_ports qdraiip_w_n] [get_bd_pins osnt_sume_qdrA_0/qdriip_w_n]
connect_bd_net [get_bd_ports qdraiip_r_n] [get_bd_pins osnt_sume_qdrA_0/qdriip_r_n]
connect_bd_net [get_bd_ports qdraiip_bw_n] [get_bd_pins osnt_sume_qdrA_0/qdriip_bw_n]
connect_bd_net [get_bd_ports qdraiip_dll_off_n] [get_bd_pins osnt_sume_qdrA_0/qdriip_dll_off_n]


create_bd_port -dir I -type clk qdrc_clk_p
create_bd_port -dir I -type clk qdrc_clk_n

create_bd_port -dir I qdrciip_cq_p
create_bd_port -dir I qdrciip_cq_n
create_bd_port -dir I -from 0 -to 35 qdrciip_q
create_bd_port -dir IO qdrciip_k_p
create_bd_port -dir IO qdrciip_k_n
create_bd_port -dir O -from 0 -to 35 qdrciip_d
create_bd_port -dir O -from 0 -to 18 qdrciip_sa
create_bd_port -dir O qdrciip_w_n
create_bd_port -dir O qdrciip_r_n
create_bd_port -dir O -from 0 -to 3 qdrciip_bw_n
create_bd_port -dir O qdrciip_dll_off_n

connect_bd_net [get_bd_ports qdrciip_cq_p] [get_bd_pins osnt_sume_qdrC_0/qdriip_cq_p]
connect_bd_net [get_bd_ports qdrciip_cq_n] [get_bd_pins osnt_sume_qdrC_0/qdriip_cq_n]
connect_bd_net [get_bd_ports qdrciip_q] [get_bd_pins osnt_sume_qdrC_0/qdriip_q]
connect_bd_net [get_bd_ports qdrciip_k_p] [get_bd_pins osnt_sume_qdrC_0/qdriip_k_p]
connect_bd_net [get_bd_ports qdrciip_k_n] [get_bd_pins osnt_sume_qdrC_0/qdriip_k_n]
connect_bd_net [get_bd_ports qdrciip_d] [get_bd_pins osnt_sume_qdrC_0/qdriip_d]
connect_bd_net [get_bd_ports qdrciip_sa] [get_bd_pins osnt_sume_qdrC_0/qdriip_sa]
connect_bd_net [get_bd_ports qdrciip_w_n] [get_bd_pins osnt_sume_qdrC_0/qdriip_w_n]
connect_bd_net [get_bd_ports qdrciip_r_n] [get_bd_pins osnt_sume_qdrC_0/qdriip_r_n]
connect_bd_net [get_bd_ports qdrciip_bw_n] [get_bd_pins osnt_sume_qdrC_0/qdriip_bw_n]
connect_bd_net [get_bd_ports qdrciip_dll_off_n] [get_bd_pins osnt_sume_qdrC_0/qdriip_dll_off_n]

create_bd_port -dir I -type clk ddr3_clk_p
create_bd_port -dir I -type clk ddr3_clk_n

create_bd_port -dir IO -from 63 -to 0 ddr3a_dq
create_bd_port -dir IO -from 7  -to 0 ddr3a_dqs_n
create_bd_port -dir IO -from 7  -to 0 ddr3a_dqs_p
create_bd_port -dir O  -from 15 -to 0 ddr3a_addr
create_bd_port -dir O  -from 3  -to 0 ddr3a_ba
create_bd_port -dir O ddr3a_ras_n
create_bd_port -dir O ddr3a_cas_n
create_bd_port -dir O ddr3a_we_n
create_bd_port -dir O ddr3a_reset_n
create_bd_port -dir O ddr3a_ck_p
create_bd_port -dir O ddr3a_ck_n
create_bd_port -dir O ddr3a_cke
create_bd_port -dir O ddr3a_cs_n
create_bd_port -dir O  -from 7 -to 0 ddr3a_dm
create_bd_port -dir O ddr3a_odt

connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_dq] [get_bd_ports ddr3a_dq]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_dqs_n] [get_bd_ports ddr3a_dqs_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_dqs_p] [get_bd_ports ddr3a_dqs_p]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_addr] [get_bd_ports ddr3a_addr]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_ba] [get_bd_ports ddr3a_ba]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_ras_n] [get_bd_ports ddr3a_ras_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_we_n] [get_bd_ports ddr3a_we_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_cas_n] [get_bd_ports ddr3a_cas_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_reset_n] [get_bd_ports ddr3a_reset_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_ck_p] [get_bd_ports ddr3a_ck_p]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_ck_n] [get_bd_ports ddr3a_ck_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_cke] [get_bd_ports ddr3a_cke]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_cs_n] [get_bd_ports ddr3a_cs_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_dm] [get_bd_ports ddr3a_dm]
connect_bd_net [get_bd_pins osnt_sume_ddr3A_0/ddr3_odt] [get_bd_ports ddr3a_odt]


create_bd_port -dir IO -from 63 -to 0 ddr3b_dq
create_bd_port -dir IO -from 7  -to 0 ddr3b_dqs_n
create_bd_port -dir IO -from 7  -to 0 ddr3b_dqs_p
create_bd_port -dir O  -from 15 -to 0 ddr3b_addr
create_bd_port -dir O  -from 3  -to 0 ddr3b_ba
create_bd_port -dir O ddr3b_ras_n
create_bd_port -dir O ddr3b_cas_n
create_bd_port -dir O ddr3b_we_n
create_bd_port -dir O ddr3b_reset_n
create_bd_port -dir O ddr3b_ck_p
create_bd_port -dir O ddr3b_ck_n
create_bd_port -dir O ddr3b_cke
create_bd_port -dir O ddr3b_cs_n
create_bd_port -dir O  -from 7 -to 0 ddr3b_dm
create_bd_port -dir O ddr3b_odt

connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_dq] [get_bd_ports ddr3b_dq]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_dqs_n] [get_bd_ports ddr3b_dqs_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_dqs_p] [get_bd_ports ddr3b_dqs_p]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_addr] [get_bd_ports ddr3b_addr]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_ba] [get_bd_ports ddr3b_ba]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_ras_n] [get_bd_ports ddr3b_ras_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_we_n] [get_bd_ports ddr3b_we_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_cas_n] [get_bd_ports ddr3b_cas_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_reset_n] [get_bd_ports ddr3b_reset_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_ck_p] [get_bd_ports ddr3b_ck_p]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_ck_n] [get_bd_ports ddr3b_ck_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_cke] [get_bd_ports ddr3b_cke]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_cs_n] [get_bd_ports ddr3b_cs_n]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_dm] [get_bd_ports ddr3b_dm]
connect_bd_net [get_bd_pins osnt_sume_ddr3B_0/ddr3_odt] [get_bd_ports ddr3b_odt]

