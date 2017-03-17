#!/bin/bs
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

# 3) Send <N> packets through multiple ports, with IPG of <Y> and measure latency and bandwidth (not full rate) on port <N>.

# Open new terminals and run below scripts in each terminal before run the script.
#python ../cli/osnt-tool-cmd.py -ifp0 ../../sample_traces/128.cap -txs0 6 -rxs0 7 -rpn0 10 -lty0
#python ../cli/osnt-tool-cmd.py -ifp1 ../../sample_traces/128.cap -txs1 6 -rxs1 7 -rpn1 10 -lty1
#python ../cli/osnt-tool-cmd.py -ifp2 ../../sample_traces/128.cap -txs2 6 -rxs2 7 -rpn2 10 -lty2
#python ../cli/osnt-tool-cmd.py -ifp3 ../../sample_traces/128.cap -txs3 6 -rxs3 7 -rpn3 10 -lty3

#python osnt-tool-cmd.py -txs0 <tx timestamp position> -rxs0 <rx timestamp position> -rpn0 <replay no> -ipg0 <inter packet gap nsec> -txs1 <tx timestamp position> -rxs1 <rx timestamp position> -rpn1 <replay no> -ipg1 <inter packet gap nsec> -txs2 <tx timestamp position> -rxs2 <rx timestamp position> -rpn2 <replay no> -ipg2 <inter packet gap nsec> -txs3 <tx timestamp position> -rxs3 <rx timestamp position> -rpn3 <replay no> -ipg3 <inter packet gap nsec> -flt <filter rule> -run
python osnt-tool-cmd.py -txs0 6 -rxs0 7 -rpn0 10 -ipg0 2000 -txs1 6 -rxs1 7 -rpn1 10 -ipg1 2000 -txs2 6 -rxs2 7 -rpn2 10 -ipg2 2000 -txs3 6 -rxs3 7 -rpn3 10 -ipg3 2000 -flt ../gui/filter.cfg -run


