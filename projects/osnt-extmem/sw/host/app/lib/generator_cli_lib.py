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
from axi import *
from generator import *

class InitGCli:
    def __init__(self):
        self.average_pkt_len = {'nf0':1500, 'nf1':1500, 'nf2':1500, 'nf3':1500}
        self.average_word_cnt = {'nf0':47, 'nf1':47, 'nf2':47, 'nf3':47}
        self.pkts_loaded = {'nf0':0, 'nf1':0, 'nf2':0, 'nf3':0}
        self.pcaps = {}
        self.rate_limiters = [None]*4
        self.delays = [None]*4
    
        rx_pos_addr = ["0x79001050", "0x79003050", "0x79005050", "0x79007050"]
        tx_pos_addr = ["0x79001054", "0x79003054", "0x79005054", "0x79007054"]
    
        self.rx_pos_wr = [None]*4
        self.tx_pos_wr = [None]*4
        for i in range(4):
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

def clear():
    initgcli.pcap_engine.clear()
    print "Cleared pcap replay. Stop ..."

def set_load_pcap(interface, pcap_file):
    initgcli.pcaps[interface] = pcap_file
    result = initgcli.pcap_engine.load_pcap(initgcli.pcaps)

def set_load_pcap_ts(interface, pcap_file):
    initgcli.pcaps[interface] = pcap_file
    result = initgcli.pcap_engine.load_pcap_ts(initgcli.pcaps)

def set_load_pcap_only(pcap_file):
    result = initgcli.pcap_engine.load_pcap_only(initgcli.pcaps)

def set_tx_ts(interface, value):
   wraxi(initgcli.tx_pos_wr[interface], hex(value))
   print "Inter Tx Timestamp position setting..."
   print "=> nf%d_tx_ts_pos = %6d\n" %(interface, value)
   
def set_rx_ts(interface, value):
   wraxi(initgcli.rx_pos_wr[interface], hex(value))
   print "Inter Rx Timestamp position setting..."
   print "=> nf%d_rx_ts_pos = %6d\n" %(interface, value)

def set_ipg(interface, value):
   initgcli.delays[interface].set_delay(value)
   initgcli.delays[interface].set_enable(True)
   initgcli.delays[interface].set_use_reg(True)
   print "Inter Packet Gap delay setting..."
   print "=> nf%d_ipg = %6d\n" %(interface, value)

def set_ipg_ts(interface, value):
   initgcli.delays[interface].set_delay(value)
   initgcli.delays[interface].set_enable(True)
   initgcli.delays[interface].set_use_reg(False)
   print "Inter Packet Gap delay setting with Timestamp..."
   print "=> nf%d_ipg = %6d\n" %(interface, value)

def set_replay_cnt(interface, value):
   initgcli.pcap_engine.replay_cnt[interface] = value
   initgcli.pcap_engine.set_replay_cnt()
   print "Packet Replay counter setting ..."
   print "=> nf%d_replay = %6d\n" %(interface, value)

initgcli = InitGCli()
