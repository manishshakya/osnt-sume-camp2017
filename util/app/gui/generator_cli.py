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

import os, argparse, datetime, commands
from lib.axi import *
from generator import *
from generator_cli_lib import *

input_arg = argparse.ArgumentParser()
input_arg.add_argument("--nf0_pcap", type=str, help="OSNT load a pcap file into nf0. eg. --nf0_pcap <pcap file name>")
input_arg.add_argument("--nf1_pcap", type=str, help="OSNT load a pcap file into nf1. eg. --nf1_pcap <pcap file name>")
input_arg.add_argument("--nf2_pcap", type=str, help="OSNT load a pcap file into nf2. eg. --nf2_pcap <pcap file name>")
input_arg.add_argument("--nf3_pcap", type=str, help="OSNT load a pcap file into nf3. eg. --nf3_pcap <pcap file name>")

input_arg.add_argument("--nf0_replay", type=int, help="OSNT nf0 run packet replay. eg. --nf0_replay <replay number>")
input_arg.add_argument("--nf1_replay", type=int, help="OSNT nf1 run packet replay. eg. --nf1_replay <replay number>")
input_arg.add_argument("--nf2_replay", type=int, help="OSNT nf2 run packet replay. eg. --nf2_replay <replay number>")
input_arg.add_argument("--nf3_replay", type=int, help="OSNT nf3 run packet replay. eg. --nf3_replay <replay number>")

input_arg.add_argument("--nf0_ipg", type=int, help="OSNT nf0 IPG setting in nsec. eg. --nf0_ipg <number>")
input_arg.add_argument("--nf1_ipg", type=int, help="OSNT nf1 IPG setting in nsec. eg. --nf1_ipg <number>")
input_arg.add_argument("--nf2_ipg", type=int, help="OSNT nf2 IPG setting in nsec. eg. --nf2_ipg <number>")
input_arg.add_argument("--nf3_ipg", type=int, help="OSNT nf3 IPG setting in nsec. eg. --nf3_ipg <number>>")

input_arg.add_argument("--nf0_tx_ts_pos", type=int, help="OSNT nf0 tx timestamp position( > 0) setting. eg. --nf0_tx_ts_pos <number>")
input_arg.add_argument("--nf1_tx_ts_pos", type=int, help="OSNT nf1 tx timestamp position( > 0) setting. eg. --nf1_tx_ts_pos <number>")
input_arg.add_argument("--nf2_tx_ts_pos", type=int, help="OSNT nf2 tx timestamp position( > 0) setting. eg. --nf2_tx_ts_pos <number>")
input_arg.add_argument("--nf3_tx_ts_pos", type=int, help="OSNT nf3 tx timestamp position( > 0) setting. eg. --nf3_tx_ts_pos <number>")

input_arg.add_argument("--nf0_rx_ts_pos", type=int, help="OSNT nf0 rx timestamp position( > 0) setting. eg. --nf0_rx_ts_pos <number>")
input_arg.add_argument("--nf1_rx_ts_pos", type=int, help="OSNT nf1 rx timestamp position( > 0) setting. eg. --nf1_rx_ts_pos <number>")
input_arg.add_argument("--nf2_rx_ts_pos", type=int, help="OSNT nf2 rx timestamp position( > 0) setting. eg. --nf2_rx_ts_pos <number>")
input_arg.add_argument("--nf3_rx_ts_pos", type=int, help="OSNT nf3 rx timestamp position( > 0) setting. eg. --nf3_rx_ts_pos <number>")

input_arg.add_argument("--run", action="store_true", help="OSNT run packet generator.")
input_arg.add_argument("--clear", action="store_true", help="OSNT stop generator and clear setting.")

args = input_arg.parse_args()

date_setting = commands.getoutput("date")
print " \nOSNT SUME Packet generator setting... at %s\n" % (date_setting)

if (args.clear):
    clear()

# Load pcap file
if (args.nf0_pcap):
    set_load_pcap("nf0", args.nf0_pcap)

if (args.nf1_pcap):
    set_load_pcap("nf1", args.nf1_pcap)

if (args.nf2_pcap):
    set_load_pcap("nf2", args.nf2_pcap)

if (args.nf3_pcap):
    set_load_pcap("nf3", args.nf3_pcap)

# Setting Tx timestamp position
if (args.nf0_tx_ts_pos or args.nf0_tx_ts_pos == 0):
   set_tx_ts(0, args.nf0_tx_ts_pos)

if (args.nf1_tx_ts_pos or args.nf1_tx_ts_pos == 0):
   set_tx_ts(1, args.nf1_tx_ts_pos)

if (args.nf2_tx_ts_pos or args.nf2_tx_ts_pos == 0):
   set_tx_ts(2, args.nf2_tx_ts_pos)

if (args.nf3_tx_ts_pos or args.nf3_tx_ts_pos == 0):
   set_tx_ts(3, args.nf3_tx_ts_pos)


# Setting Rx timestamp position
if (args.nf0_rx_ts_pos or args.nf0_rx_ts_pos == 0):
   set_rx_ts(0, args.nf0_rx_ts_pos)

if (args.nf1_rx_ts_pos or args.nf1_rx_ts_pos == 0):
   set_rx_ts(1, args.nf1_rx_ts_pos)

if (args.nf2_rx_ts_pos or args.nf2_rx_ts_pos == 0):
   set_rx_ts(2, args.nf2_rx_ts_pos)

if (args.nf3_rx_ts_pos or args.nf3_rx_ts_pos == 0):
   set_rx_ts(3, args.nf3_rx_ts_pos)


# Setting IPG
if (args.nf0_ipg or args.nf0_ipg == 0):
   set_ipg(0, args.nf0_ipg)

if (args.nf1_ipg or args.nf1_ipg == 0):
   set_ipg(1, args.nf1_ipg)

if (args.nf2_ipg or args.nf2_ipg == 0):
   set_ipg(2, args.nf2_ipg)

if (args.nf3_ipg or args.nf3_ipg == 0):
   set_ipg(3, args.nf3_ipg)

# Packet number setting to replay
if (args.nf0_replay or args.nf0_replay == 0):
   set_replay_cnt(0, args.nf0_replay)

if (args.nf1_replay or args.nf1_replay == 0):
   set_replay_cnt(1, args.nf1_replay)

if (args.nf2_replay or args.nf2_replay == 0):
   set_replay_cnt(2, args.nf2_replay)

if (args.nf3_replay or args.nf3_replay == 0):
   set_replay_cnt(3, args.nf3_replay)

if (args.run):
   initcli.pcap_engine.run()
   print "Start packet generator...!\n"
