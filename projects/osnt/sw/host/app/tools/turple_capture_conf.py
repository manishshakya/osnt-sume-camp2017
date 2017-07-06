#!/usr/bin/python
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
################################################################################

import os, sys
import socket, struct, array, time, argparse
sys.path.insert(0, "./../lib")
from monitor import *
from axi import *
from scapy.all import ETH_P_ALL
from scapy.all import select


osnt_monitor_filter = OSNTMonitorFilter()
osnt_monitor_cutter = OSNTMonitorCutter()

rx_pos_addr = ["0x79001050", "0x79003050", "0x79005050", "0x79007050"]

input_arg = argparse.ArgumentParser()
input_arg.add_argument("--port_no", help="NetFPGA physical port no. 0~3. eg. --port_no 0")
input_arg.add_argument("--verbose", type=str, help="--Show rx and tx timestamp values - On (Default: Off).")
args = input_arg.parse_args()

if (args.port_no):
    phy_port_no = int(args.port_no)
    if (phy_port_no > 3):
        print '\nOut of ragne: Port No must be 0~3. Try --help\n'
        sys.exit(1)
else:
    print '\nSpecify Port No for monitoring. Try --help\n'
    sys.exit(1)

#TS setting at the first 64 word
if (phy_port_no == 0):
    wraxi(rx_pos_addr[phy_port_no], 1)
elif (phy_port_no == 1):
    wraxi(rx_pos_addr[phy_port_no], 1)
elif (phy_port_no == 2):
    wraxi(rx_pos_addr[phy_port_no], 1)
elif (phy_port_no == 3):
    wraxi(rx_pos_addr[phy_port_no], 1)

wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.src_ip_reg_offset), 0);
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.src_ip_mask_reg_offset), 0)
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.dst_ip_reg_offset), 0)
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.dst_ip_mask_reg_offset), 0)
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.l4ports_reg_offset), 0)
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.l4ports_mask_reg_offset), 0)
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.proto_reg_offset), '0x06')
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.proto_mask_reg_offset), '0xff')
wraxi(osnt_monitor_filter.reg_addr(osnt_monitor_filter.wr_addr_reg_offset), 1)

osnt_monitor_cutter.enable_cut(int(64))

#Disable Hash
wraxi("0x77a00010", "0x1")
#Enable turple monitoring
wraxi("0x75000000", "0x10000")
