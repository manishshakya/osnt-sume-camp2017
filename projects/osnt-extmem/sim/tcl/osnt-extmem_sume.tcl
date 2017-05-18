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


# Set variables.
set design        system 
set device        xc7vx690tffg1761-3
set project_dir   project

# Build project
create_project -name ${design} -force -dir ${project_dir} -part ${device}
set_property ip_repo_paths  ../../../lib/hw [current_project]

update_ip_catalog

create_bd_design ${design}

create_bd_port -dir I fpga_sysclk_n
create_bd_port -dir I fpga_sysclk_p
create_bd_port -dir I -type rst reset
set_property -dict [list CONFIG.POLARITY {ACTIVE_HIGH}] [get_bd_ports reset]

# fpga system clock buffer.
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 sysclk_buf

# fpga system clock generator, clock1 for bus registers, clock2 for axi-stream data path.
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.3 sys_clock_0
set_property -dict [list CONFIG.PRIM_IN_FREQ {200.000}] [get_bd_cells sys_clock_0]
set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000}] [get_bd_cells sys_clock_0]
set_property -dict [list CONFIG.CLKOUT2_USED {true} ] [get_bd_cells sys_clock_0]
set_property -dict [list CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {160.000}] [get_bd_cells sys_clock_0]

# fpga system reset generator.
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_input_arbiter:1.00 osnt_sume_input_arbiter_0
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_input_arbiter_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_input_arbiter_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_input_arbiter_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_input_arbiter_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_endianess_manager:1.00 osnt_sume_endianess_manager_0
set_property -dict [list CONFIG.C_M_AXIS_TDATA_WIDTH {256}] [get_bd_cells osnt_sume_endianess_manager_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_endianess_manager_0]
set_property -dict [list CONFIG.C_S_AXIS_TDATA_WIDTH {256}] [get_bd_cells osnt_sume_endianess_manager_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_endianess_manager_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_bram_output_queues:1.00 osnt_sume_bram_output_queues_0
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_bram_output_queues_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_bram_output_queues_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_bram_output_queues_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_bram_output_queues_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_packet_cutter:1.00 osnt_sume_packet_cutter_0
set_property -dict [list CONFIG.C_BASEADDR {0x77a00000}] [get_bd_cells osnt_sume_packet_cutter_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x77a0ffff}] [get_bd_cells osnt_sume_packet_cutter_0]
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_packet_cutter_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_packet_cutter_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_packet_cutter_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_packet_cutter_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_timestamp:1.00 osnt_sume_timestamp_0
set_property -dict [list CONFIG.C_BASEADDR {0x78a00000}] [get_bd_cells osnt_sume_timestamp_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x78a0ffff}] [get_bd_cells osnt_sume_timestamp_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_monitoring_output_port_lookup:1.00 osnt_sume_monitoring_output_port_lookup_0
set_property -dict [list CONFIG.C_BASEADDR {0x75000000}] [get_bd_cells osnt_sume_monitoring_output_port_lookup_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x7500ffff}] [get_bd_cells osnt_sume_monitoring_output_port_lookup_0]
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_monitoring_output_port_lookup_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_monitoring_output_port_lookup_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_monitoring_output_port_lookup_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_monitoring_output_port_lookup_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_nic_output_port_lookup:1.00 osnt_sume_nic_output_port_lookup_0
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_nic_output_port_lookup_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_nic_output_port_lookup_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_nic_output_port_lookup_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_nic_output_port_lookup_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_inter_packet_delay:1.00 osnt_sume_inter_packet_delay_0
set_property -dict [list CONFIG.C_BASEADDR {0x76600000}] [get_bd_cells osnt_sume_inter_packet_delay_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x7660ffff}] [get_bd_cells osnt_sume_inter_packet_delay_0]
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_inter_packet_delay_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_inter_packet_delay_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_inter_packet_delay_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_inter_packet_delay_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_rate_limiter:1.00 osnt_sume_rate_limiter_0
set_property -dict [list CONFIG.C_BASEADDR {0x77e00000}] [get_bd_cells osnt_sume_rate_limiter_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x77e0ffff}] [get_bd_cells osnt_sume_rate_limiter_0]
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_rate_limiter_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_rate_limiter_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_rate_limiter_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_rate_limiter_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_extract_metadata:1.00 osnt_sume_extract_metadata_0
set_property -dict [list CONFIG.C_BASEADDR {0x76e00000}] [get_bd_cells osnt_sume_extract_metadata_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x76e0ffff}] [get_bd_cells osnt_sume_extract_metadata_0]
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_extract_metadata_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_extract_metadata_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_extract_metadata_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_extract_metadata_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_bram_pcap_replay_uengine:1.00 osnt_sume_bram_pcap_replay_uengine_0
set_property -dict [list CONFIG.C_BASEADDR {0x76000000}] [get_bd_cells osnt_sume_bram_pcap_replay_uengine_0]
set_property -dict [list CONFIG.C_HIGHADDR {0x7600ffff}] [get_bd_cells osnt_sume_bram_pcap_replay_uengine_0]
set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_bram_pcap_replay_uengine_0]
set_property -dict [list CONFIG.C_M_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_bram_pcap_replay_uengine_0]
set_property -dict [list CONFIG.C_S_AXIS_DATA_WIDTH {256}] [get_bd_cells osnt_sume_bram_pcap_replay_uengine_0]
set_property -dict [list CONFIG.C_S_AXIS_TUSER_WIDTH {128}] [get_bd_cells osnt_sume_bram_pcap_replay_uengine_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1} CONFIG.DATA_WIDTH {512} CONFIG.PROTOCOL {AXI4}] [get_bd_cells axi_bram_ctrl_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1} CONFIG.DATA_WIDTH {512} CONFIG.PROTOCOL {AXI4}] [get_bd_cells axi_bram_ctrl_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_2
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1} CONFIG.DATA_WIDTH {512} CONFIG.PROTOCOL {AXI4}] [get_bd_cells axi_bram_ctrl_2]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_3
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1} CONFIG.DATA_WIDTH {512} CONFIG.PROTOCOL {AXI4}] [get_bd_cells axi_bram_ctrl_3]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_bram:1.00 osnt_sume_bram_0
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_bram:1.00 osnt_sume_bram_1
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_bram:1.00 osnt_sume_bram_2
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_bram:1.00 osnt_sume_bram_3

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {12}] [get_bd_cells axi_interconnect_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_stim:1.00 osnt_sume_axis_sim_stim_0
set_property -dict [list CONFIG.input_file {../../../../tv/packet_stim_rx_0.axi}] [get_bd_cells osnt_sume_axis_sim_stim_0]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_stim:1.00 osnt_sume_axis_sim_stim_1
set_property -dict [list CONFIG.input_file {../../../../tv/packet_stim_rx_1.axi}] [get_bd_cells osnt_sume_axis_sim_stim_1]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_stim:1.00 osnt_sume_axis_sim_stim_2
set_property -dict [list CONFIG.input_file {../../../../tv/packet_stim_rx_2.axi}] [get_bd_cells osnt_sume_axis_sim_stim_2]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_stim:1.00 osnt_sume_axis_sim_stim_3
set_property -dict [list CONFIG.input_file {../../../../tv/packet_stim_rx_3.axi}] [get_bd_cells osnt_sume_axis_sim_stim_3]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_stim:1.00 osnt_sume_axis_sim_stim_4
set_property -dict [list CONFIG.input_file {../../../../tv/packet_stim_tx.axi}] [get_bd_cells osnt_sume_axis_sim_stim_4]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_record:1.00 osnt_sume_axis_sim_record_0
set_property -dict [list CONFIG.OUTPUT_FILE {./stream_data_out_0.axi}] [get_bd_cells osnt_sume_axis_sim_record_0]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_record:1.00 osnt_sume_axis_sim_record_1
set_property -dict [list CONFIG.OUTPUT_FILE {./stream_data_out_1.axi}] [get_bd_cells osnt_sume_axis_sim_record_1]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_record:1.00 osnt_sume_axis_sim_record_2
set_property -dict [list CONFIG.OUTPUT_FILE {./stream_data_out_2.axi}] [get_bd_cells osnt_sume_axis_sim_record_2]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_record:1.00 osnt_sume_axis_sim_record_3
set_property -dict [list CONFIG.OUTPUT_FILE {./stream_data_out_3.axi}] [get_bd_cells osnt_sume_axis_sim_record_3]
create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axis_sim_record:1.00 osnt_sume_axis_sim_record_4
set_property -dict [list CONFIG.OUTPUT_FILE {./stream_data_out_4.axi}] [get_bd_cells osnt_sume_axis_sim_record_4]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axi_sim_master:1.00 osnt_sume_axi_sim_master_0
set_property -dict [list CONFIG.REG_FILE {../../../../tv/reg_stim.axi}] [get_bd_cells osnt_sume_axi_sim_master_0]

create_bd_cell -type ip -vlnv OSNT-SUME-NetFPGA:OSNT-SUME-NetFPGA:osnt_sume_axi_if:1.00 osnt_sume_axi_if_0

source ./tcl/osnt-extmem_sume_connection.tcl

# Bus register map address configuration
assign_bd_address [get_bd_addr_segs {osnt_sume_bram_pcap_replay_uengine_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_bram_pcap_replay_uengine_0_reg0}]
set_property offset 0x76000000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_bram_pcap_replay_uengine_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_extract_metadata_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_extract_metadata_0_reg0}]
set_property offset 0x76e00000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_extract_metadata_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_rate_limiter_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_rate_limiter_0_reg0}]
set_property offset 0x77e00000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_rate_limiter_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_inter_packet_delay_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_inter_packet_delay_0_reg0}]
set_property offset 0x76600000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_inter_packet_delay_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_packet_cutter_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_packet_cutter_0_reg0}]
set_property offset 0x77a00000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_packet_cutter_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_timestamp_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_timestamp_0_reg0}]
set_property offset 0x78a00000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_timestamp_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_monitoring_output_port_lookup_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_monitoring_output_port_lookup_0_reg0}]
set_property offset 0x75000000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_monitoring_output_port_lookup_0_reg0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_0/S_AXI/Mem0 }]
set_property offset 0x7A000000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_0_Mem0}]
set_property range 128K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_0_Mem0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_1/S_AXI/Mem0 }]
set_property offset 0x7A100000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_1_Mem0}]
set_property range 128K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_1_Mem0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_2/S_AXI/Mem0 }]
set_property offset 0x7A200000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_2_Mem0}]
set_property range 128K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_2_Mem0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_3/S_AXI/Mem0 }]
set_property offset 0x7A300000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_3_Mem0}]
set_property range 128K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_axi_bram_ctrl_3_Mem0}]


assign_bd_address [get_bd_addr_segs {osnt_sume_axi_if_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_axi_if_0_reg0}]
set_property offset 0x90000000 [get_bd_addr_segs {osnt_sume_axi_sim_master_0/M_AXI/SEG_osnt_sume_axi_if_0_reg0}]

# Create system block
generate_target all [get_files ${project_dir}/system.srcs/sources_1/bd/system/system.bd]
make_wrapper -files [get_files ${project_dir}/system.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse ${project_dir}/system.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Update pre-defined testbench.
import_files -fileset sim_1 -norecurse ./lib/system_wrapper_tb.v
set_property top system_wrapper_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

launch_simulation -scripts_only

exit
