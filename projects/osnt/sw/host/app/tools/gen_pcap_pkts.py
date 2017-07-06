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

import os
import sys
import argparse
from scapy.all import wrpcap
from scapy.layers.all import Ether, IP, TCP, UDP

script_dir = os.path.dirname(sys.argv[0])

#Input arguments
parser = argparse.ArgumentParser()
parser.add_argument("--packet_length", help="Length of packet in no of bytes")
parser.add_argument("--packet_no", help="No of packets")
parser.add_argument("--packet_type", type=str, help="TCP, UDP")
parser.add_argument("--file_name", type=str, help="File name for output pcap")
parser.add_argument("--src_mac", type=str, help="Source MAC address")
parser.add_argument("--dst_mac", type=str, help="Destination MAC address")
parser.add_argument("--src_ip", type=str, help="Source IP address")
parser.add_argument("--dst_ip", type=str, help="Destination IP address")
parser.add_argument("--sport_no", help="Source Port Number")
parser.add_argument("--dport_no", help="Destination Port Number")
parser.add_argument("--packet_ts", type=float, help="Packet timestamp")

args = parser.parse_args()

#Length of Packets
if (args.packet_length):
   pkt_length = args.packet_length
else:
   # Default length of packets
   pkt_length = '64'

if (args.packet_ts):
   pkt_timestamp = args.packet_ts
else:
   pkt_timestamp = 0

#No of packets
if (args.packet_no):
   no_pkt = args.packet_no
else:
	#Default number of packets
   no_pkt = 1

if (args.file_name):
   pcap_name = args.file_name
else:
   print "\n\nInput file name for output pcap file\n"
   sys.exit()

if (args.packet_type == 'udp' or args.packet_type == 'UDP'):
   pkt_type = 'udp'
   pkt_length = int(pkt_length) - 28 - 14
elif (args.packet_type == 'tcp' or args.packet_type == 'TCP'):
   pkt_type = 'tcp'
   pkt_length = int(pkt_length) - 40 
else:
   pkt_type = 'udp'
   pkt_length = int(pkt_length) - 28

print '\nPacket type ',str(pkt_type)

#Source and Destination IP address allocation
if (args.src_mac):
   src_mac_addr=args.src_mac
else:
	src_mac_addr='ff:22:33:44:55:66'

if (args.dst_mac):
	dst_mac_addr=args.dst_mac
else:
	dst_mac_addr='77:88:99:aa:bb:cc'

#Source and Destination IP address allocation
if (args.src_ip):
	src_ip_addr=args.src_ip
else:
	src_ip_addr='192.168.1.1'

if (args.dst_ip):
	dst_ip_addr=args.dst_ip
else:
	dst_ip_addr='192.168.1.2'

#Source and Destination port number
if (args.sport_no):
	ip_sport_no=int(args.sport_no)
else:
	ip_sport_no=10

if (args.dport_no):
	ip_dport_no=int(args.dport_no)
else:
	ip_dport_no=15

#Payload appended to packet header
payload_data = ''
for i in range(int(pkt_length)):
	payload_data = payload_data + 'A'# Payload contents are not important.

pkts_tcp=[]
#A simple TCP/IP packet embedded in an Ethernet II frame
for i in range(int(no_pkt)):
   pkt = (Ether(src=src_mac_addr, dst=dst_mac_addr)/
          IP(src=src_ip_addr, dst=dst_ip_addr)/
          TCP(sport=ip_sport_no, dport=ip_dport_no)/payload_data)
   pkts_tcp.append(pkt)

pkts_udp=[]
#A simple UDP/IP packet embedded in an Ethernet frame
for i in range(int(no_pkt)):
   pkt = (Ether(src=src_mac_addr, dst=dst_mac_addr)/
          IP(src=src_ip_addr, dst=dst_ip_addr)/
          UDP(sport=ip_sport_no, dport=ip_dport_no)/payload_data)
   pkt.time = pkt_timestamp
   pkts_udp.append(pkt)

if (args.packet_type == 'tcp' or args.packet_type == 'TCP'):
   pkts=pkts_tcp
else:
   pkts=pkts_udp

#Select packet type for axi stream data generation

wrpcap(os.path.join(script_dir, '%s.cap' % (str(pcap_name))), pkts)

print '\nFinish packet generation!\n'
