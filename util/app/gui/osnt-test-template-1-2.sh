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

python osnt-tool-cmd.py -ifp0 ../../sample_traces/128.cap -flt filter.cfg -rpn0 10 -ipg0 800 -txs0 6 -rxs0 7 -lty0 -rnm
sleep 1

python osnt-tool-cmd.py -ifp1 ../../sample_traces/128.cap -flt filter.cfg -rpn1 10 -ipg1 800 -txs1 6 -rxs1 7 -lty1 -rnm 
sleep 1

python osnt-tool-cmd.py -ifp2 ../../sample_traces/128.cap -flt filter.cfg -rpn2 10 -ipg2 800 -txs2 6 -rxs2 7 -lty2 -rnm 
sleep 1

python osnt-tool-cmd.py -ifp3 ../../sample_traces/128.cap -flt filter.cfg -rpn3 10 -ipg3 800 -txs3 6 -rxs3 7 -lty3 -rnm 
