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
################################################################################

import socket, struct, os, array, sys, time, argparse
sys.path.insert(0,"../lib")
from scapy.all import ETH_P_ALL
from scapy.all import select
from timestamp_capture_cli_lib import *

input_arg = argparse.ArgumentParser()
input_arg.add_argument("--tx_ts_pos", type=int, help="Tx timestamp position in packet (Number).")
input_arg.add_argument("--rx_ts_pos", type=int, help="Rx timestamp position in packet (Number).")
input_arg.add_argument("--lpn", type=int, help="Number of packet for timestamp capturing (Number).")
input_arg.add_argument("--file_name", type=str, help="File name to store the results. Default <test.dat>")
input_arg.add_argument("--ifn", type=str, help="Network interface name, nf0-nf3")
input_arg.add_argument("--run", action="store_true", help="Start OSNT packet generator.")
input_arg.add_argument("--skt", action="store_true", help="Latency measurement with python socket.")
args = input_arg.parse_args()

if (args.lpn):
    pkt_no = args.lpn 
else:
    print 'Default number of packet for timestamp capturing is 10!\n'
    pkt_no = 10 

if (args.tx_ts_pos):
    tx_ts_pkt_pos = args.tx_ts_pos
else:
    print 'Add Tx timestamp position. Try --help\n'
    sys.exit(1)

if (args.rx_ts_pos):
    rx_ts_pkt_pos = args.rx_ts_pos
else:
    print 'Add Rx timestamp position. Try --help\n'
    sys.exit(1)

if (args.tx_ts_pos == args.rx_ts_pos):
    print 'Tx and Rx position must be different.\n'
    sys.exit(1)

if (args.file_name):
    log_file = args.file_name
else:
    log_file = "latency_data.dat"
    print 'Write a file name to store the results. Default <latency_data.dat>\n'

if (args.ifn):
   interface_name = args.ifn
   print "interface name ", interface_name
   if (args.skt):
      timestamp_capture(interface_name, tx_ts_pkt_pos, rx_ts_pkt_pos, pkt_no, log_file, args.run)
   else:
      timestamp_tcpdump(interface_name, tx_ts_pkt_pos, rx_ts_pkt_pos, pkt_no, log_file, args.run)
else:
   sys.exit(1)

