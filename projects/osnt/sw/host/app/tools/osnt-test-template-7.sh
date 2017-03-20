#!/bin/sh
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

PKTLENGTH=64 #Packet length in byte
FN=test_pcap_01
PKTTYPE=UDP
SRCMAC=ff:22:33:44:55:66
DSCMAC=77:88:99:aa:bb:cc
SRCIP=192.168.1.1
DSCIP=192.168.1.2
SPORT_NO=100
DPORT_NO=101

./gen_pcap_pkts.py \
--packet_length $PKTLENGTH --packet_type $PKTTYPE --file_name $FN \
--src_mac $SRCMAC --dst_mac $DSCMAC \
--src_ip $SRCIP --dst_ip $DSCIP \
--sport_no $SPORT_NO --dport_no $DPORT_NO

echo "2 $SRCIP 255.255.255.255 0.0.0.0 0.0.0.0 0x0 0x0 0x00 0x0" > packet_filter.cfg

PKTLENGTH=64 #Packet length in byte
FN=test_pcap_02
PKTTYPE=UDP
SRCMAC=ff:22:33:44:55:66
DSCMAC=77:88:99:aa:bb:cc
SRCIP=10.0.1.1
DSCIP=10.0.1.2
SPORT_NO=100
DPORT_NO=101

./gen_pcap_pkts.py \
--packet_length $PKTLENGTH --packet_type $PKTTYPE --file_name $FN \
--src_mac $SRCMAC --dst_mac $DSCMAC \
--src_ip $SRCIP --dst_ip $DSCIP \
--sport_no $SPORT_NO --dport_no $DPORT_NO

python ../cli/osnt-tool-cmd.py -ifp0 ./test_pcap_01.cap 
python ../cli/osnt-tool-cmd.py -ifp1 ./test_pcap_02.cap -ipg0 100000000 -rpn1 100000000 -rpn0 100 -flt packet_filter.cfg -txs0 6 -rxs1 7 -lpn 100 -lty1 -rnm
