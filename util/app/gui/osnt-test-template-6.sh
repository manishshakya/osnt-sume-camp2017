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

# 6) The same as #3 but at full rate without setting the inter packet gap.

# Open a new terminal and run below before run the scripts.
# python osnt-tool-cmd.py -ds

# Two ports tests at full rate.
if [ $1 == "2" ];then
   python osnt-tool-cmd.py -ifp0 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -ifp1 ../../sample_traces/1500.cap
   sleep 1
   #python osnt-tool-cmd.py -rpn0 <replay no> -rpn1 <replay no> -run
   python osnt-tool-cmd.py -rpn0 10000000 -rpn1 10000000 -run
fi

# Three ports tests at full rate.
if [ $1 == "3" ];then
   python osnt-tool-cmd.py -ifp0 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -ifp1 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -ifp2 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -rpn0 10000000 -rpn1 10000000 -rpn2 10000000 -run
fi

# Four ports tests at full rate.
if [ $1 == "4" ];then
   python osnt-tool-cmd.py -ifp0 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -ifp1 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -ifp2 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -ifp3 ../../sample_traces/1500.cap
   sleep 1
   python osnt-tool-cmd.py -rpn0 10000000 -rpn1 10000000 -rpn2 10000000 -rpn3 10000000 -run
fi
