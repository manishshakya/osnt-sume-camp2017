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

import os, sys, math, argparse
sys.path.insert(0, "./../lib")
from axi import *
from time import gmtime, strftime, sleep
from monitor import *
from monitor_cli_lib import *
from generator import *
from generator_cli_lib import *
from timestamp_capture_cli_lib import *

input_arg = argparse.ArgumentParser()
# Generator flags
input_arg.add_argument("-ifp0", type=str, help="OSNT SUME generator load packet into nf0. eg. -if0 <pcap file>")
input_arg.add_argument("-ifp1", type=str, help="OSNT SUME generator load packet into nf1. eg. -if1 <pcap file>")
input_arg.add_argument("-ifp2", type=str, help="OSNT SUME generator load packet into nf2. eg. -if2 <pcap file>")
input_arg.add_argument("-ifp3", type=str, help="OSNT SUME generator load packet into nf3. eg. -if3 <pcap file>")
input_arg.add_argument("-ifpt0", type=str, help="OSNT SUME generator load packet into nf0 with timestamp. eg. -if0 <pcap file>")
input_arg.add_argument("-ifpt1", type=str, help="OSNT SUME generator load packet into nf1 with timestamp. eg. -if1 <pcap file>")
input_arg.add_argument("-ifpt2", type=str, help="OSNT SUME generator load packet into nf2 with timestamp. eg. -if2 <pcap file>")
input_arg.add_argument("-ifpt3", type=str, help="OSNT SUME generator load packet into nf3 with timestamp. eg. -if3 <pcap file>")
input_arg.add_argument("-rpn0", type=int, help="OSNT SUME generator packet replay no. on nf0. eg. -rpn0 <integer number>")
input_arg.add_argument("-rpn1", type=int, help="OSNT SUME generator packet replay no. on nf1. eg. -rpn1 <integer number>")
input_arg.add_argument("-rpn2", type=int, help="OSNT SUME generator packet replay no. on nf2. eg. -rpn2 <integer number>")
input_arg.add_argument("-rpn3", type=int, help="OSNT SUME generator packet replay no. on nf3. eg. -rpn3 <integer number>")
input_arg.add_argument("-ipg0", type=int, help="OSNT SUME generator inter packet gap on nf0. eg. -ipg0 <integer number>")
input_arg.add_argument("-ipg1", type=int, help="OSNT SUME generator inter packet gap on nf1. eg. -ipg1 <integer number>")
input_arg.add_argument("-ipg2", type=int, help="OSNT SUME generator inter packet gap on nf2. eg. -ipg2 <integer number>")
input_arg.add_argument("-ipg3", type=int, help="OSNT SUME generator inter packet gap on nf3. eg. -ipg3 <integer number>")
input_arg.add_argument("-txs0", type=int, help="OSNT SUME generator tx timestamp position on nf0. eg. -txs0 <integer number>")
input_arg.add_argument("-txs1", type=int, help="OSNT SUME generator tx timestamp position on nf1. eg. -txs1 <integer number>")
input_arg.add_argument("-txs2", type=int, help="OSNT SUME generator tx timestamp position on nf2. eg. -txs2 <integer number>")
input_arg.add_argument("-txs3", type=int, help="OSNT SUME generator tx timestamp position on nf3. eg. -txs3 <integer number>")
input_arg.add_argument("-rxs0", type=int, help="OSNT SUME generator rx timestamp position on nf0. eg. -rxs0 <integer number>")
input_arg.add_argument("-rxs1", type=int, help="OSNT SUME generator rx timestamp position on nf1. eg. -rxs1 <integer number>")
input_arg.add_argument("-rxs2", type=int, help="OSNT SUME generator rx timestamp position on nf2. eg. -rxs2 <integer number>")
input_arg.add_argument("-rxs3", type=int, help="OSNT SUME generator rx timestamp position on nf3. eg. -rxs3 <integer number>")
input_arg.add_argument("-run", action="store_true", help="OSNT SUME generator trigger to run. eg. --run")

# Monitor flags
input_arg.add_argument("-cs", type=int, help="OSNT SUME monitor packet cutter size in byte. -cs <integer number>")
input_arg.add_argument("-ds", action="store_true", help="OSNT SUME monitor run display stats. -ds")
input_arg.add_argument("-st", action="store_true", help="OSNT SUME monitor show stats. -st")
input_arg.add_argument("-flt", type=str, help="OSNT SUME monitor load filter file. -flt <filter file name>")
input_arg.add_argument("-clear", action="store_true", help="OSNT SUME monitor clear stats and time. -clear")

# Latency measurement flags
input_arg.add_argument("-lpn", type=int, help="OSNT SUME latency measurement packet no on one of the nf interfaces. eg. -lpn <integer number>. This number should be the same with the rpn.")
input_arg.add_argument("-lty0", action="store_true", help="OSNT SUME latency measurement on nf0. eg. -lty0")
input_arg.add_argument("-lty1", action="store_true", help="OSNT SUME latency measurement on nf1. eg. -lty1")
input_arg.add_argument("-lty2", action="store_true", help="OSNT SUME latency measurement on nf2. eg. -lty2")
input_arg.add_argument("-lty3", action="store_true", help="OSNT SUME latency measurement on nf3. eg. -lty3")
input_arg.add_argument("-llog", type=str, help="OSNT SUME latency measurement log file. eg. -lf <file name>")
input_arg.add_argument("-skt", action="store_true", help="OSNT SUME generator trigger and latency measurement with python socket. eg. -skt")
input_arg.add_argument("-rnm", action="store_true", help="OSNT SUME generator trigger and latency measurement. eg. -rnm")


args = input_arg.parse_args()

# 1. Generator only
# 2. Monitor only
# 3. Latency only
# 4. Generator and Monitor : Gen set - Monitor live display - Gen run
# 5. Generator and Latency : Gen set - Latency - Gen run

if (args.clear):
    set_clear()
    clear()
    sys.exit(1)

# Set no packet for latency measure ment 
if (args.lpn or args.lpn == 0):
    lty_pkt_no=args.lpn
else:
    lty_pkt_no=0 

# Set and chect latency measurement interface. 
lty_value=[0, 0, 0, 0]
lty_if=""
if (args.lty0):
    lty_value[0]=1
    lty_if="nf0"

if (args.lty1):
    lty_value[1]=1
    lty_if="nf1"

if (args.lty2):
    lty_value[2]=1
    lty_if="nf2"

if (args.lty3):
    lty_value[3]=1
    lty_if="nf3"

if (sum(lty_value) == 1):
    if (lty_pkt_no == 0):
       print "Neet to set the number of packet to be captured."
       sys.exit(1)
    set_clear()

if (sum(lty_value) > 1):
    print lty_value
    print "\n\nError: Cannot measure two ports on the same terminal!\n"

# Load pcap file
if (args.ifp0):
    set_load_pcap("nf0", args.ifp0)

if (args.ifp1):
    set_load_pcap("nf1", args.ifp1)

if (args.ifp2):
    set_load_pcap("nf2", args.ifp2)

if (args.ifp3):
    set_load_pcap("nf3", args.ifp3)

# Load pcap file
if (args.ifpt0):
    set_load_pcap_ts("nf0", args.ifpt0)

if (args.ifpt1):
    set_load_pcap_ts("nf1", args.ifpt1)

if (args.ifpt2):
    set_load_pcap_ts("nf2", args.ifpt2)

if (args.ifpt3):
    set_load_pcap_ts("nf3", args.ifpt3)

# Set packet replay number
if (args.rpn0 or args.rpn0 == 0):
    set_replay_cnt(0, args.rpn0)
else:
    set_replay_cnt(0, 0)

if (args.rpn1 or args.rpn1 == 0):
    set_replay_cnt(1, args.rpn1)
else:
    set_replay_cnt(1, 0)

if (args.rpn2 or args.rpn2 == 0):
    set_replay_cnt(2, args.rpn2)
else:
    set_replay_cnt(2, 0)

if (args.rpn3 or args.rpn3 == 0):
    set_replay_cnt(3, args.rpn3)
else:
    set_replay_cnt(3, 0)

# Set inter packet gap dealy
ipg_value=[0,0,0,0]
if (args.ipg0):
   ipg_value[0] = args.ipg0  

if (args.ipg1):
   ipg_value[1] = args.ipg1  

if (args.ipg2):
   ipg_value[2] = args.ipg2  

if (args.ipg3):
   ipg_value[3] = args.ipg3

if (args.ifpt0 or args.ifpt1 or args.ifpt2 or args.ifpt3):
   for i in range(4):  
      set_ipg_ts(i, ipg_value[i])
else:
   for i in range(4):  
      set_ipg(i, ipg_value[i])

# Set TX timestamp position
if (args.txs0):
    set_tx_ts(0, args.txs0)
    lty_tx_pos = args.txs0

if (args.txs1):
    set_tx_ts(1, args.txs1)
    lty_tx_pos = args.txs1

if (args.txs2):
    set_tx_ts(2, args.txs2)
    lty_tx_pos = args.txs2

if (args.txs3):
    set_tx_ts(3, args.txs3)
    lty_tx_pos = args.txs3

# Set RX timestamp position
if (args.rxs0):
    set_rx_ts(0, args.rxs0)
    lty_rx_pos = args.rxs0

if (args.rxs1):
    set_rx_ts(1, args.rxs1)
    lty_rx_pos = args.rxs1

if (args.rxs2):
    set_rx_ts(2, args.rxs2)
    lty_rx_pos = args.rxs2

if (args.rxs3):
    set_rx_ts(3, args.rxs3)
    lty_rx_pos = args.rxs3

# Load filter for monitor on the host
if (args.flt):
    load_rule(args.flt)

if (args.llog):
    log_file = args.llog
elif (lty_if != ""):
    log_file = "latency_data.dat"
    print 'Write a file name to store the results. Default <latency_data.dat>\n'

if (lty_if != ""):
    print "Set the interface ", lty_if
    if (args.flt):
       load_rule(args.flt)
    else:
       load_rule("./filter.cfg")

    if (args.skt):   
       timestamp_capture(lty_if, lty_tx_pos, lty_rx_pos, lty_pkt_no, log_file, args.rnm)
    else:
       timestamp_tcpdump(lty_if, lty_tx_pos, lty_rx_pos, lty_pkt_no, log_file, args.rnm)

if (args.run):
   initgcli.pcap_engine.run()
   print "Start packet generator...!\n"

# Show the stats in monitor
if (args.st):
    cli_display_stats("show")

if (args.ds):
    run_stats()
