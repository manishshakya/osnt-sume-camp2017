#
# Copyright (c) 2016-2017 University of Cambridge
# Copyright (c) 2016-2017 Jong Hun Han
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

set project_dir   project
set design        system 
set device        xc7vx690tffg1761-3

set const0 ./constraint/osnt_sume.xdc
set const1 ./constraint/osnt_sume_10g.xdc
set const2 ./constraint/osnt_sume_timing.xdc

# Build project
create_project -name ${design} -force -dir ./${project_dir} -part ${device}
set_property ip_repo_paths  ./../../../lib/hw [current_project]

update_ip_catalog

create_bd_design ${design}

add_files -fileset constrs_1 -norecurse ${const0} ${const1} ${const2}
import_files -fileset constrs_1 ${const0} ${const1} ${const2}

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

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 axi_iic_0
set_property -dict [list CONFIG.C_GPO_WIDTH {2}] [get_bd_cells axi_iic_0]
set_property -dict [list CONFIG.C_SCL_INERTIAL_DELAY {5}] [get_bd_cells axi_iic_0]
set_property -dict [list CONFIG.C_SDA_INERTIAL_DELAY {5}] [get_bd_cells axi_iic_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells axi_uartlite_0]

# osnt monitor 
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


# Standard ips
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

# Block design modules
source ./tcl/bd_sume_osnt_dma_engine.tcl
create_hier_cell_sume_osnt_dma_engine [current_bd_instance .] sume_osnt_dma 256

source ./tcl/bd_sume_osnt_10g_all_interface.tcl
create_hier_cell_sume_osnt_10g_all_interface [current_bd_instance .] sume_osnt_10g_interface 256 

source ./tcl/bd_sume_osnt_mbsys.tcl
create_hier_cell_mbsys [current_bd_instance .] mbsys

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {15}] [get_bd_cells axi_interconnect_0]

# Create external ports and make connection
source ./tcl/osnt_sume_port.tcl
source ./tcl/osnt_sume_connection.tcl

# Bus register map address configuration
create_bd_addr_seg -range 0x10000 -offset 0x00000000 [get_bd_addr_spaces mbsys/microblaze_0/Data] \
   [get_bd_addr_segs mbsys/microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
create_bd_addr_seg -range 0x10000 -offset 0x00000000 [get_bd_addr_spaces mbsys/microblaze_0/Instruction] \
   [get_bd_addr_segs mbsys/microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
create_bd_addr_seg -range 0x10000 -offset 0x41200000 [get_bd_addr_spaces mbsys/microblaze_0/Data] \
   [get_bd_addr_segs mbsys/microblaze_0_axi_intc/s_axi/Reg] SEG_microblaze_0_axi_intc_Reg

create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mbsys/microblaze_0/Data] \
   [get_bd_addr_segs axi_iic_0/S_AXI/Reg] SEG_axi_iic_0_Reg
create_bd_addr_seg -range 0x10000 -offset 0x40600000 [get_bd_addr_spaces mbsys/microblaze_0/Data] \
   [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg

assign_bd_address [get_bd_addr_segs {osnt_sume_bram_pcap_replay_uengine_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_bram_pcap_replay_uengine_0_reg0}]
set_property offset 0x76000000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_bram_pcap_replay_uengine_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_extract_metadata_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_extract_metadata_0_reg0}]
set_property offset 0x76e00000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_extract_metadata_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_rate_limiter_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_rate_limiter_0_reg0}]
set_property offset 0x77e00000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_rate_limiter_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_inter_packet_delay_0/s_axi/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_inter_packet_delay_0_reg0}]
set_property offset 0x76600000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_inter_packet_delay_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_packet_cutter_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_packet_cutter_0_reg0}]
set_property offset 0x77a00000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_packet_cutter_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_timestamp_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_timestamp_0_reg0}]
set_property offset 0x78a00000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_timestamp_0_reg0}]

assign_bd_address [get_bd_addr_segs {osnt_sume_monitoring_output_port_lookup_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_monitoring_output_port_lookup_0_reg0}]
set_property offset 0x75000000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_monitoring_output_port_lookup_0_reg0}]

assign_bd_address [get_bd_addr_segs {sume_osnt_10g_interface/osnt_sume_10g_axi_if_0/S_AXI/reg0 }]
set_property range 64K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_10g_axi_if_0_reg0}]
set_property offset 0x79000000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_osnt_sume_10g_axi_if_0_reg0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_0/S_AXI/Mem0 }]
set_property offset 0x7A000000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_0_Mem0}]
set_property range 1024K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_0_Mem0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_1/S_AXI/Mem0 }]
set_property offset 0x7A100000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_1_Mem0}]
set_property range 1024K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_1_Mem0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_2/S_AXI/Mem0 }]
set_property offset 0x7A200000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_2_Mem0}]
set_property range 1024K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_2_Mem0}]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_3/S_AXI/Mem0 }]
set_property offset 0x7A300000 [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_3_Mem0}]
set_property range 1024K [get_bd_addr_segs {sume_osnt_dma/osnt_sume_riffa_dma_0/m_axi_lite/SEG_axi_bram_ctrl_3_Mem0}]

delete_bd_objs [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_bram_pcap_replay_uengine_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_extract_metadata_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_rate_limiter_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_inter_packet_delay_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_packet_cutter_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_timestamp_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_monitoring_output_port_lookup_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_osnt_sume_10g_axi_if_0_reg0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_axi_bram_ctrl_0_Mem0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_axi_bram_ctrl_1_Mem0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_axi_bram_ctrl_2_Mem0] [get_bd_addr_segs mbsys/microblaze_0/Data/SEG_axi_bram_ctrl_3_Mem0]

# Create system block
generate_target all [get_files ./${project_dir}/system.srcs/sources_1/bd/system/system.bd]
make_wrapper -files [get_files ./${project_dir}/system.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse ./${project_dir}/system.srcs/sources_1/bd/system/hdl/system_wrapper.v

#set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property synth_checkpoint_mode None [get_files ./${project_dir}/system.srcs/sources_1/bd/system/system.bd]
generate_target all [get_files ./${project_dir}/system.srcs/sources_1/bd/system/system.bd]
export_ip_user_files -of_objects [get_files ./${project_dir}/system.srcs/sources_1/bd/system/system.bd] -no_script -sync -force -quiet

launch_runs synth_1 -jobs 4

#### Start synthesis and implementation
synth_design -rtl -name rtl_1
set_property BITSTREAM.GENERAL.COMPRESS FALSE [get_designs rtl_1]
save_constraints

set_property strategy Performance_Retiming [get_runs impl_1]

launch_runs -jobs 8 impl_1 -to_step write_bitstream
wait_on_run impl_1

exit
