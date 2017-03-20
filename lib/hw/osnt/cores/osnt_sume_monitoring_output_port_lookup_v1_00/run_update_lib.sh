#!/bin/sh
#
# Copyright (c) 2016 University of Cambridge 
# Copyright (c) 2016 Jong Hun Han
# All rights reserved
#
# This software was developed by University of Cambridge Computer Laboratory
# under the ENDEAVOUR project (grant agreement 644960) as part of
# the European Union's Horizon 2020 research and innovation programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor license
# agreements.  See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.  NetFPGA licenses this file to you
# under the NetFPGA Hardware-Software License, Version 1.0 (the "License"); you
# may not use this file except in compliance with the License.  You may obtain
# a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@

cam_dir=./xapp1151_cam_v1_1/src
file_list=`find $cam_dir -name *.vhd`

check_virtex7=`grep -r virtex7 $cam_dir `
check_VIRTEX7=`grep -r VIRTEX7 $cam_dir `

if [ ! -d ./xapp1151_cam_v1_1 ]
   then
      echo ""
      echo "Download and uncompress the Xilinx CAM (xapp1151) here."
      echo "The CAM can be downloaded from Xilinx web site."
      echo ""
      exit
fi 

for in_file in $file_list; do

   sed -i -e 's/LIBRARY cam/LIBRARY xil_defaultlib/' $in_file
   sed -i -e 's/ENTITY cam\./ENTITY xil_defaultlib\./' $in_file
   sed -i -e 's/USE cam\./USE xil_defaultlib\./' $in_file
done

if [[ $check_virtex7 != "" && $check_VIRTEX7 != "" ]]
   then
      echo " "
      echo "It's already updated."
      echo " "
      exit
fi

sed -i '/virtex6l/a CONSTANT VIRTEX7               : STRING := "virtex7";' $cam_dir/vhdl/cam_pkg.vhd
sed -i -e 's/spartan6)/spartan6) OR (C_FAMILY = virtex7)/' $cam_dir/vhdl/cam_rtl.vhd
sed -i -e 's/or spartan6/spartan6, or virtex7/' $cam_dir/vhdl/cam_rtl.vhd
