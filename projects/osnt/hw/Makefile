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

project_name = project

project: clean
	vivado -mode tcl -source ./tcl/osnt_sume.tcl

export_to_sdk:
	if test -d project; then\
		echo "export ${project_name} project to SDK"; \
		vivado -mode tcl -source tcl/export_hardware.tcl -tclargs system;\
	else \
		echo "Project ${project_name} does not exist.";\
		echo "Please run \"make project\" to create and build the project first";\
	fi;\

embed_elf:
	@if [ ! -d ../bitfiles ]; then mkdir ../bitfiles; fi;
	if test -d project; then\
		vivado -mode tcl -source tcl/embedded_elf.tcl -tclargs system;\
	else \
		echo "Please run \"make project\" to create and build the project first";\
	fi;\

clean: 
	rm -rf proj* vivado*.* *.*~ .Xil*

