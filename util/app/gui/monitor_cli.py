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

import os, sys, math, argparse
from lib.axi import *
from time import gmtime, strftime, sleep
from monitor import *
from monitor_cli_lib import *

input_arg = argparse.ArgumentParser()
input_arg.add_argument("--load_filter", type=str, help="OSNT monitor load a rule of filter. eg. --load_filter <filter file name>")
input_arg.add_argument("--cut_size", type=int, help="OSNT monitor packet cutter size in byte. --cut_size <byte size>")
input_arg.add_argument("--show", action="store_true", help="OSNT monitor show the current stats. --show")
input_arg.add_argument("--run", action="store_true", help="OSNT monitor display the stats. --run")
input_arg.add_argument("--clear", action="store_true", help="OSNT monitor clear stats and time. --clear <any value>")
    
args = input_arg.parse_args()

if (args.clear):
    set_clear()

if (args.show):
    cli_display_stats("show") 

# Setting cut size
if (args.cut_size or args.cut_size == 0):
    initcli.cut_size = args.cut_size
    if (initcli.cut_size != 0):
        initcli.osnt_monitor_cutter.enable_cut(initcli.cut_size)

# Load filter rule
if (args.load_filter):
    load_rule(args.load_filter)

if (args.run):
    run_stats()
