##
# Copyright (c) 2017 Noa Zilberman
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer Laboratory 
# under Leverhulme Trust grant ECF-2016-289 
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#
################################################################################
#  File:
#        Makefile
#
#  Project:
#       NetFPGA + OSNT development challenge 2017
#
#  Description:
#         Creates and runs NetFPGA Challenge 2017 tests.
#
SHELL=/bin/bash
PCAP_GEN_PATH=../../projects/osnt/sw/host/app/
TESTS_PATH=../../projects/osnt/sw/host/app/tools/
LIB=../../projects/osnt/sw/host/app/lib/
CLI_PATH=../../projects/osnt/sw/host/app/cli
OSNT_CONST=478
PKT_NUM=1000
MIN_VAL=$$((`cat min` - $(OSNT_CONST) )) 
MAX_VAL=$$(( `cat max` - $(OSNT_CONST) )) 


.PHONY: clean
.PHONY: traces
.PHONY: oneport
.PHONY: twoport
.PHONY: allport

all: clean build traces oneport twoport allport

build: 
	@echo "***********************************************"
	@echo "* Building the challenge folder               *"
	@echo "***********************************************"
	mkdir traces
	mkdir oneport
	mkdir twoport
	mkdir allport
	mkdir cli
	mkdir lib
	mkdir tools
	cp $(PCAP_GEN_PATH)/pcap_gen.py .
	cp $(TESTS_PATH)/* tools/
	cp $(LIB)/* lib/
	cp $(CLI_PATH)/* cli/ 

clean:
	@echo "***********************************************"
	@echo "* Cleaning the challenge folder               *"
	@echo "***********************************************"	
	rm -rf traces/ 
	rm -rf oneport/
	rm -rf twoport/
	rm -rf allport/
	rm -rf *.py *.pyc *.pcap *.dat 
	rm -rf lib/
	rm -rf cli/
	rm -rf tools/

traces:
	@echo "***********************************************"
	@echo "* Generating pcap traces       	             *"
	@echo "***********************************************"	
	for i in 60 61 64 65 96 97 128 129 256 512 1024 1514 ; do \
		python pcap_gen.py -o traces/$$i\B.cap -n 1 -l $$i -s "aa:bb:cc:dd:ee:ff" -d "de:ad:be:ef:f0:01" ; \
	done
	python pcap_gen.py -o traces/60B_cross.cap -n 1 -l 60 -s "de:ad:be:ef:f0:01" -d "aa:bb:cc:dd:ee:ff"
	python pcap_gen.py -o traces/1514B_cross.cap -n 1 -l 1514 -s "de:ad:be:ef:f0:01" -d "aa:bb:cc:dd:ee:ff"
	python pcap_gen.py -o traces/60B_cross2.cap -n 1 -l 60 -s "de:ad:be:ef:f0:02" -d "aa:bb:cc:dd:ee:ff"
	python pcap_gen.py -o traces/1514B_cross2.cap -n 1 -l 1514 -s "de:ad:be:ef:f0:02" -d "aa:bb:cc:dd:ee:ff"
	python pcap_gen.py -o traces/60B_cross3.cap -n 1 -l 60 -s "de:ad:be:ef:f0:03" -d "aa:bb:cc:dd:ee:ff"
	python pcap_gen.py -o traces/1514B_cross3.cap -n 1 -l 1514 -s "de:ad:be:ef:f0:03" -d "aa:bb:cc:dd:ee:ff"

oneport: 
	@echo "**************************************************"
	@echo "* Test 1: 1000 packets latency, no cross traffic *"
	@echo "**************************************************"
	cd cli/	
	for i in 60 61 64 65 96 97 128 129 256 512 1024 1514 ; do \
		python osnt-tool-cmd.py -ifp0 traces/$$i\B.cap -flt filter.cfg -rpn0 $(PKT_NUM) -ipg0 9000 -txs0 6 -rxs1 7 -lty1 -rnm > oneport/$$i\B.out ; \
		grep Min oneport/$$i\B.out >tmp ; \
		cat tmp | cut -d, -f1|cut -d " " -f4|cut -d. -f1 >min ; \
		cat tmp | cut -d, -f2|cut -d " " -f3|cut -d. -f1 >max ; \
		echo $$i\B $(MIN_VAL) >> ../oneport/min.txt; \
		echo $$i\B $(MAX_VAL) >> ../oneport/max.txt; \
		rm tmp max min; \
	done
	@echo "Test done. Minimum latency:"
	cat ../oneport/min.txt
	@echo "Maximum latency:"
	cat ../oneport/max.txt 

twoport:
	@echo "************************************************************"
	@echo "* Test 2 - 1000 packets latency, single port cross traffic *"
	@echo "************************************************************"	
	@echo "This test is not working yet"
	

allport:
	@echo "***************************************************************"
	@echo "* Test 3 - 1000 packets latency, cross traffic from all ports *"
	@echo "***************************************************************"	
	@echo "This test is not working yet"
	


	

