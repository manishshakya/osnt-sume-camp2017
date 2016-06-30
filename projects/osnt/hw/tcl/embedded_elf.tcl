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

set design [lindex $argv 0] 

# open project
open_project project/${design}.xpr

set bd_file [get_files -regexp -nocase {.*system*.bd}]
set elf_file ../sw/embedded/SDK_Workspace/system/system/Release/system.elf

open_bd_design $bd_file

# insert acceptance_test elf if it is not inserted yet
if {[llength [get_files *${design}.elf]]} {
	puts "ELF File [get_files *acceptance_test.elf] is already associated"
   exit
} else {
	add_files -norecurse -force ${elf_file} 
	set_property SCOPED_TO_REF [current_bd_design] [get_files -all -of_objects [get_fileset sources_1] ${elf_file}]
	set_property SCOPED_TO_CELLS mbsys/microblaze_0 [get_files -all -of_objects [get_fileset sources_1] ${elf_file}]
}

# Create bitstream with up-to-date elf files
reset_run impl_1 -prev_step
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1
write_bitstream -force ../bitfiles/osnt.bit

exit
