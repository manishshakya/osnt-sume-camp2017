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

WS = SDK_Workspace

.PHONY: clean project compile

project:
	if [ -d ./SDK_Workspace ]; then rm -rf ./SDK_Workspace; mkdir SDK_Workspace; fi
	xsdk -batch -source ./tcl/osnt-extmem_xsdk.tcl

compile:
	cp -rf ./src/*.* ./SDK_Workspace/system/system/src;\
	if [ -d SDK_Workspace ]; then \
		xsdk -wait -eclipseargs -nosplash -application org.eclipse.cdt.managedbuilder.core.headlessbuild -build all -data ./SDK_Workspace/system -vmargs -Dorg.eclipse.cdt.core.console=org.eclipse.cdt.core.systemConsole; \
		xsdk -wait -eclipseargs -nosplash -application org.eclipse.cdt.managedbuilder.core.headlessbuild -build all -data ./SDK_Workspace/system -vmargs -Dorg.eclipse.cdt.core.console=org.eclipse.cdt.core.systemConsole; \
	fi;\

clean:
		rm -rf ${WS};\
