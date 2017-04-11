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

import struct, os, array, sys, argparse
sys.path.insert(0,"../../../../../osnt/sw/host/app/lib")
from axi import *

input_arg = argparse.ArgumentParser()
input_arg.add_argument("--mem_sel", type=str, help="Select one of the memories, qdrA, qdrC, ddr3A, and ddr3B.")
input_arg.add_argument("--addr", type=str, help="Type the memory address for the data read and write - eg. 0x001")
input_arg.add_argument("--wr_data", type=str, help="Type the data to be written into the memory - eg. 0x1234")
args = input_arg.parse_args()

drA_base_addr   = "0x7a000000"
qdrC_base_addr  = "0x7b000000"
ddr3A_base_addr = "0x7c000000"
ddr3B_base_addr = "0x7d000000"

if (args.mem_sel == "qdrA"):
    base_addr = qdrA_base_addr
elif (args.mem_sel == "qdrC"):
    base_addr = qdrC_base_addr 
elif (args.mem_sel == "ddr3A"):
    base_addr = ddr3A_base_addr 
elif (args.mem_sel == "ddr3B"):
    base_addr = ddr3B_base_addr 
else:
    print '\nNeed to give the type of memory to access. Try --help\n'
    sys.exit(1)

if (args.addr):
    mem_address = args.addr
else:
    print '\nWrite address for data read and write from the memory. Try --help\n'
    sys.exit(1)

if (args.wr_data):
    wraxi(base_addr, mem_address)
    wraxi(add_hex(base_addr, "0x10"), args.wr_data) 
    print '\nWrite done. Address : ', str(mem_address), ' Write Data : ', str(args.wr_data), '\n'
    sys.exit(1)
else:
    wraxi(base_addr, mem_address)
    rd_data = rdaxi(add_hex(base_addr, "0x20"))
    print '\nRead done. Address : ', str(mem_address), ' Read Data : ', rd_data, '\n'
    sys.exit(1)

