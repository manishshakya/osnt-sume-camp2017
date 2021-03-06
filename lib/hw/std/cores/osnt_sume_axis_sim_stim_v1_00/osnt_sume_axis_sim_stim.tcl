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
set   design               osnt_sume_axis_sim_stim
set   ip_version           1.00
set   ip_version_display   v1_00

source ../lib/osnt_ip_set_common.tcl

# Project setting.
create_project -name ${design} -force -dir "./${project_dir}" -part ${device} -ip

set_property source_mgmt_mode All [current_project]  
set_property top ${design} [current_fileset]

# IP build.
read_vhdl "./hdl/vhdl/osnt_sume_axis_sim_stim.vhd"
read_vhdl "./../osnt_sume_common/hdl/vhdl/axis_sim_pkg.vhd"

update_compile_order -fileset sources_1

ipx::package_project

# Set ip descriptions
source ../lib/osnt_ip_property_common.tcl

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces M_AXIS -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project
exit

