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
from scapy.all import ETH_P_ALL
from scapy.all import select
from generator import *
from generator_cli_lib import *

s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))

input_arg = argparse.ArgumentParser()
input_arg.add_argument("--tx_ts_pos", help="Tx timestamp position in packet (Number).")
input_arg.add_argument("--rx_ts_pos", help="Rx timestamp position in packet (Number).")
input_arg.add_argument("--sample_no", help="Number of packet for timestamp capturing (Number).")
input_arg.add_argument("--file_name", type=str, help="File name to store the results. Default <test.dat>")
input_arg.add_argument("--if_name", type=str, help="Network interface name, nf0-nf3")
input_arg.add_argument("--verbose", type=str, help="Show rx and tx timestamp values - On (Default: Off).")
input_arg.add_argument("--send", action="store_true", help="Start OSNT packet generator.")
args = input_arg.parse_args()

if (args.if_name):
    if_name = args.if_name
else:
    sys.exit(1)

s.bind((if_name, ETH_P_ALL))
s.setblocking(0)
os.system("ifconfig "+if_name+" up promisc")

if (args.sample_no):
    pkt_no = int(args.sample_no) 
else:
    print 'Default number of packet for timestamp capturing is 10!\n'
    pkt_no = 10 

if (args.tx_ts_pos):
    tx_ts_pkt_pos = int(args.tx_ts_pos)
else:
    print 'Add Tx timestamp position. Try --help\n'
    sys.exit(1)

if (args.rx_ts_pos):
    rx_ts_pkt_pos = int(args.rx_ts_pos)
else:
    print 'Add Rx timestamp position. Try --help\n'
    sys.exit(1)

if (args.tx_ts_pos == args.rx_ts_pos):
    print 'Tx and Rx position must be different.\n'
    sys.exit(1)

if (args.file_name):
    log_file = args.file_name
else:
    log_file = "test.dat"
    print 'Write a file name to store the results. Default <test.dat>\n'

if (args.verbose == 'On' or args.verbose == 'on'):
    verbose_en = True
else:
    verbose_en = False

f = open(log_file, "w")

tx_ts_begin = 16*(tx_ts_pkt_pos-1)
tx_ts_end = 16*tx_ts_pkt_pos

rx_ts_begin = 16*(rx_ts_pkt_pos-1)
rx_ts_end = 16*rx_ts_pkt_pos

pkt_no_count = 0
cal_ts = {}

tx_ts_enum = float(0)
rx_ts_enum = float(0)
tx_ts_1st = float(0)
rx_ts_1st = float(0)

if (args.send):
   initcli.pcap_engine.run()
   print "Start packet generator...!\n"

while True:

    try:
        packet = s.recv(65000)
        pkt_len = len(packet)
        tx_ts_len = 8*tx_ts_pkt_pos
        rx_ts_len = 8*rx_ts_pkt_pos
        if (pkt_len < tx_ts_len or pkt_len < rx_ts_len):
            print '>>ERROR: Timestamp position is out of packet length!'
            break

        pkt_data=''.join('%02x' % ord(b) for b in packet)
        tx_ts_value = pkt_data[tx_ts_begin:tx_ts_end]
        rx_ts_value = pkt_data[rx_ts_begin:rx_ts_end]

        tx_ts_data = hex((int(tx_ts_value[14:16],16)<<56)+\
                         (int(tx_ts_value[12:14],16)<<48)+\
                         (int(tx_ts_value[10:12],16)<<40)+\
                         (int(tx_ts_value[8:10],16)<<32)+\
                         (int(tx_ts_value[6:8],16)<<24)+\
                         (int(tx_ts_value[4:6],16)<<16)+\
                         (int(tx_ts_value[2:4],16)<<8)+\
                         (int(tx_ts_value[0:2],16)))
        rx_ts_data = hex((int(rx_ts_value[14:16],16)<<56)+\
                         (int(rx_ts_value[12:14],16)<<48)+\
                         (int(rx_ts_value[10:12],16)<<40)+\
                         (int(rx_ts_value[8:10],16)<<32)+\
                         (int(rx_ts_value[6:8],16)<<24)+\
                         (int(rx_ts_value[4:6],16)<<16)+\
                         (int(rx_ts_value[2:4],16)<<8)+\
                         (int(rx_ts_value[0:2],16)))

        delta_ts = format(int(rx_ts_data,16) - int(tx_ts_data,16),'016x')
        cal_ts_value = float((int(rx_ts_data,16) - int(tx_ts_data,16))*10**9/2**32)

        tx_value = float(int(tx_ts_data,16)*10**9/2**32)
        rx_value = float(int(rx_ts_data,16)*10**9/2**32)

        if (tx_ts_1st != 0):
            tx_ts_enum = float(tx_value - tx_ts_1st)
        if (rx_ts_1st != 0):
            rx_ts_enum = float(rx_value - rx_ts_1st)

        if (tx_ts_1st == 0):
            tx_ts_1st = float(tx_value)
        if (rx_ts_1st == 0):
            rx_ts_1st = float(rx_value)

        if (int(delta_ts,16) < 0):
            print '>>ERROR: Rx and Tx timestamp positions are wrong! Negative value.'
            break

        if (verbose_en): 
            print 'INFO: Packet no: %03d tx: %fus rx: %fus tx ts:0x%s (%d) rx ts:0x%s (%d) RTT 0x%s (%d) %f nsec \n' % \
                (pkt_no_count, \
                 float(tx_ts_enum/1000), \
                 float(rx_ts_enum/1000), \
                 tx_ts_data, int(tx_ts_data,16), \
                 rx_ts_data, int(rx_ts_data,16), \
                 delta_ts, int(delta_ts, 16), cal_ts_value)
            f.write("INFO: Packet no:"+str(pkt_no_count)+"\n");
        else:
            print 'INFO: Packet no: %03d tx: %fus rx: %fus RTT %f nsec\n' % \
                (pkt_no_count, float(tx_ts_enum/1000), float(rx_ts_enum/1000), cal_ts_value)
            f.write("INFO: Packet no: "+str(pkt_no_count)+" delta: 0x"+str(delta_ts)+" ("+str(int(delta_ts,16))+") "+str(cal_ts_value)+" nsec\n");

        cal_ts[pkt_no_count] = float(cal_ts_value);
        pkt_no_count = pkt_no_count + 1
        if (pkt_no_count == pkt_no):
            break
        
    except:
        pass

avg_ts = 0
for i in range(pkt_no):
    avg_ts = float(avg_ts + cal_ts[i])

avg_ts = float(avg_ts/pkt_no)

print 'Average time : %fusec' % float(avg_ts)
f.write("\nAverage time : " + str(float(avg_ts)) + " nsec\n");
f.close()
sys.exit(1)

    
