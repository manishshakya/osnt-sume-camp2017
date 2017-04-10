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

# 1) Send a single packet through port <X> and measure the latency of a returning packet.
# 2) Send <N> packets through port <X>, with IPG of <Y> and measure latency and bandwidth (not full rate).

#python osnt-tool-cmd.py -ifp0 <pcap file> -flt <filter rule> -rpn0 <replay no> -ipg0 <inter packet gap nsec> -txs0 <tx timestamp pos> -rxs0 <rx timestamp pos> -lpn <no of packet for capturing> -lty0 (monitoring port) -rnm (run and monitoring)
python ../cli/osnt-tool-cmd.py -ifp0 ../sample_traces/1500.cap -flt ../gui/filter.cfg -ipg0 10000 -rpn0 1000 -txs0 6 -rxs0 7 -lpn 1000 -lty0 -rnm
sleep 1                                                                                            

python ../cli/osnt-tool-cmd.py -ifp1 ../sample_traces/1500.cap -flt ../gui/filter.cfg -ipg1 10000 -rpn1 1000 -txs1 6 -rxs1 7 -lpn 1000 -lty1 -rnm 
sleep 1                                                                                         
                                                                                                
python ../cli/osnt-tool-cmd.py -ifp2 ../sample_traces/1500.cap -flt ../gui/filter.cfg -ipg2 10000 -rpn2 1000 -txs2 6 -rxs2 7 -lpn 1000 -lty2 -rnm 
sleep 1                                                                                         
                                                                                                
python ../cli/osnt-tool-cmd.py -ifp3 ../sample_traces/1500.cap -flt ../gui/filter.cfg -ipg3 10000 -rpn3 1000 -txs3 6 -rxs3 7 -lpn 1000 -lty3 -rnm
