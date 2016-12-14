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
################################################################################

import os, argparse, datetime, commands
from lib.axi import *
from generator import *

class InitCli:
    def __init__(self):
        self.average_pkt_len = {'nf0':1500, 'nf1':1500, 'nf2':1500, 'nf3':1500}
        self.average_word_cnt = {'nf0':47, 'nf1':47, 'nf2':47, 'nf3':47}
        self.pkts_loaded = {'nf0':0, 'nf1':0, 'nf2':0, 'nf3':0}
        self.pcaps = {}
        self.rate_limiters = [None]*4
        self.delays = [None]*4
    
        rx_pos_addr = ["0x79001050", "0x79003050", "0x79005050", "0x79007050"]
        tx_pos_addr = ["0x79001054", "0x79003054", "0x79005054", "0x79007054"]
    
        self.rx_pos_rd = [None]*4 
        self.tx_pos_rd = [None]*4
        self.rx_pos_wr = [None]*4
        self.tx_pos_wr = [None]*4
        for i in range(4):
            self.rx_pos_rd[i] = rdaxi(rx_pos_addr[i]) 
            self.tx_pos_rd[i] = rdaxi(tx_pos_addr[i])
            self.rx_pos_wr[i] = rx_pos_addr[i]
            self.tx_pos_wr[i] = tx_pos_addr[i] 
        
        for i in range(4):
            iface = 'nf' + str(i)
            self.rate_limiters[i] = OSNTRateLimiter(iface)
            self.delays[i] = OSNTDelay(iface)
    
        self.pcap_engine = OSNTGeneratorPcapEngine()
        self.delay_header_extractor = OSNTDelayHeaderExtractor()
    
        self.delay_header_extractor.set_reset(False)
        self.delay_header_extractor.set_enable(False)

initcli = InitCli()

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

input_arg.add_argument("--clear", type=str, help="OSNT stop generator and clear setting.")

args = input_arg.parse_args()

date_setting = commands.getoutput("date")
print " \nOSNT SUME Packet generator setting... at %s" % (date_setting)
print " "

if (args.clear):
    initcli.pcap_engine.clear()
    print "Cleared pcap replay. Stop ..."
    sys.exit(1)

# Load pcap file
if (args.nf0_pcap):
    initcli.pcaps['nf0'] = args.nf0_pcap
    initcli.pcap_engine.load_pcap(initcli.pcaps)

if (args.nf1_pcap):
    initcli.pcaps['nf1'] = args.nf1_pcap
    initcli.pcap_engine.load_pcap(initcli.pcaps)

if (args.nf2_pcap):
    initcli.pcaps['nf2'] = args.nf2_pcap
    initcli.pcap_engine.load_pcap(initcli.pcaps)

if (args.nf3_pcap):
    initcli.pcaps['nf3'] = args.nf3_pcap
    initcli.pcap_engine.load_pcap(initcli.pcaps)

# Setting Tx timestamp position
val_nf_tx_ts_pos = [0, 0, 0, 0]
if (args.nf0_tx_ts_pos):
    val_nf_tx_ts_pos[0] = args.nf0_tx_ts_pos

if (args.nf1_tx_ts_pos):
    val_nf_tx_ts_pos[1] = args.nf1_tx_ts_pos

if (args.nf2_tx_ts_pos):
    val_nf_tx_ts_pos[2] = args.nf2_tx_ts_pos

if (args.nf3_tx_ts_pos):
    val_nf_tx_ts_pos[3] = args.nf3_tx_ts_pos

print "Inter Tx Timestamp position setting..."
print "=> nf0_tx_ts_pos = %6d, nf1_tx_ts_pos = %6d, nf2_tx_ts_pos = %6d, nf3_tx_ts_pos = %6d\n" \
    %(val_nf_tx_ts_pos[0], val_nf_tx_ts_pos[1], val_nf_tx_ts_pos[2], val_nf_tx_ts_pos[3])

for i in range(4):
    wraxi(initcli.tx_pos_wr[i], hex(val_nf_tx_ts_pos[i])) 


# Setting Rx timestamp position
val_nf_rx_ts_pos = [0, 0, 0, 0]
if (args.nf0_rx_ts_pos):
    val_nf_rx_ts_pos[0] = args.nf0_rx_ts_pos

if (args.nf1_rx_ts_pos):
    val_nf_rx_ts_pos[1] = args.nf1_rx_ts_pos

if (args.nf2_rx_ts_pos):
    val_nf_rx_ts_pos[2] = args.nf2_rx_ts_pos

if (args.nf3_rx_ts_pos):
    val_nf_rx_ts_pos[3] = args.nf3_rx_ts_pos

print "Inter Rx Timestamp position setting..."
print "=> nf0_rx_ts_pos = %6d, nf1_rx_ts_pos = %6d, nf2_rx_ts_pos = %6d, nf3_rx_ts_pos = %6d\n" \
    %(val_nf_rx_ts_pos[0], val_nf_rx_ts_pos[1], val_nf_rx_ts_pos[2], val_nf_rx_ts_pos[3])

for i in range(4):
    wraxi(initcli.rx_pos_wr[i], hex(val_nf_rx_ts_pos[i])) 

# Setting IPG
val_nf_ipg = [0, 0, 0, 0]
if (args.nf0_ipg):
    val_nf_ipg[0] = args.nf0_ipg

if (args.nf1_ipg):
    val_nf_ipg[1] = args.nf1_ipg

if (args.nf2_ipg):
    val_nf_ipg[2] = args.nf2_ipg

if (args.nf3_ipg):
    val_nf_ipg[3] = args.nf3_ipg

print "Inter Packet Gap delay setting..."
print "=> nf0_ipg = %6d, nf1_ipg = %6d, nf2_ipg = %6d, nf3_ipg = %6d\n" \
    %(val_nf_ipg[0], val_nf_ipg[1], val_nf_ipg[2], val_nf_ipg[3])

for i in range(4):
    initcli.delays[i].set_delay(val_nf_ipg[i])
    initcli.delays[i].set_enable(True)
    initcli.delays[i].set_use_reg(True)

# Packet number setting to replay
val_nf_replay = [0, 0, 0, 0]
if (args.nf0_replay):
    val_nf_replay[0] = args.nf0_replay

if (args.nf1_replay):
    val_nf_replay[1] = args.nf1_replay

if (args.nf2_replay):
    val_nf_replay[2] = args.nf2_replay

if (args.nf3_replay):
    val_nf_replay[3] = args.nf3_replay

print "Packet Replay counter setting ..."
print "=> nf0_replay = %6d, nf1_replay = %6d, nf2_replay = %6d, nf3_replay = %6d\n" \
    %(val_nf_replay[0], val_nf_replay[1], val_nf_replay[2], val_nf_replay[3])

initcli.pcap_engine.replay_cnt = [val_nf_replay[0], val_nf_replay[1], val_nf_replay[2], val_nf_replay[3]]
initcli.pcap_engine.set_replay_cnt()

initcli.pcap_engine.run()
