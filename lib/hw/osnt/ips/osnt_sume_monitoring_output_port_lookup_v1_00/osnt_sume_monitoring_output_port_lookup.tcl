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


# Set variables.
set design              osnt_sume_monitoring_output_port_lookup
set ip_version          1.00
set ip_version_display  v1_00

# Call common setting for ips
source ../../../lib/osnt_ip_set_common.tcl

# Project setting.
create_project -name ${design} -force -dir "./${project_dir}" -part ${device} -ip

set_property source_mgmt_mode All [current_project]  
set_property top ${design} [current_fileset]

# IP build.
read_verilog "./hdl/verilog/osnt_sume_monitoring_output_port_lookup.v"
read_verilog "./hdl/verilog/core_monitoring.v"

read_verilog "./hdl/verilog/packet_analyzer/multistage_priority_mux.v"
read_verilog "./hdl/verilog/packet_analyzer/packet_analyzer.v"
read_verilog "./hdl/verilog/packet_analyzer/packet_monitor.v"

read_verilog "./hdl/verilog/packet_analyzer/network_protocol_combinations/ETH_IPv4_TCPnUDP.v"
read_verilog "./hdl/verilog/packet_analyzer/network_protocol_combinations/ETH_VLAN_IPv4_TCPnUDP.v"
read_verilog "./hdl/verilog/packet_analyzer/network_protocol_combinations/WHEN_NO_HIT.v"

read_verilog "./hdl/verilog/packet_filter/process_pkt.v"
read_verilog "./hdl/verilog/packet_filter/tcam_wrapper.v"

read_verilog "./hdl/verilog/stats_handler/stats_handler.v"

read_verilog "./../../../std/ips/osnt_sume_common/hdl/verilog/fallthrough_small_fifo.v"
read_verilog "./../../../std/ips/osnt_sume_common/hdl/verilog/small_fifo.v"

read_verilog "./../../../std/ips/osnt_sume_common/hdl/verilog/axi_lite_regs.v"
read_verilog "./../../../std/ips/osnt_sume_common/hdl/verilog/ipif_regs.v"
read_verilog "./../../../std/ips/osnt_sume_common/hdl/verilog/ipif_table_regs.v"
read_verilog "./../../../std/ips/osnt_sume_common/hdl/verilog/sume_axi_ipif.v"


read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_init_file_pack_xst.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_pkg.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_input_ternary_ternenc.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_input_ternary.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_input.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_control.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_decoder.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_match_enc.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_regouts.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_srl16_ternwrcomp.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_srl16_wrcomp.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_srl16_block_word.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_srl16_block.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_srl16.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_blk_extdepth_prim.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_blk_extdepth.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/dmem.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem_blk.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_mem.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_rtl.vhd"
read_vhdl "./xapp1151_cam_v1_1/src/vhdl/cam_top.vhd"


update_compile_order -fileset sources_1

ipx::package_project

# Call common properties of ips
source ../../../lib/osnt_ip_property_common.tcl

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces M_AXIS -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces S_AXIS -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project
exit

