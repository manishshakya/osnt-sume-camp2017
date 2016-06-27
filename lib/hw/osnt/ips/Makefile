#
# Copyright (c) 2016 University of Cambridge
# Copyright (c) 2016 Jong Hun Han
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

all:
	$(MAKE) -C ./osnt_sume_10g_axi_if_v1_00
	$(MAKE) -C ./osnt_sume_10g_rx_queue_v1_00
	$(MAKE) -C ./osnt_sume_10g_tx_queue_v1_00
	$(MAKE) -C ./osnt_sume_bram_pcap_replay_uengine_v1_00
	$(MAKE) -C ./osnt_sume_bram_v1_00
	$(MAKE) -C ./osnt_sume_extract_metadata_v1_00
	$(MAKE) -C ./osnt_sume_inter_packet_delay_v1_00
	$(MAKE) -C ./osnt_sume_monitoring_output_port_lookup_v1_00
	$(MAKE) -C ./osnt_sume_packet_cutter_v1_00
	$(MAKE) -C ./osnt_sume_rate_limiter_v1_00
	$(MAKE) -C ./osnt_sume_timestamp_v1_00

clean:
	$(MAKE) -C ./osnt_sume_10g_axi_if_v1_00 clean
	$(MAKE) -C ./osnt_sume_10g_rx_queue_v1_00 clean
	$(MAKE) -C ./osnt_sume_10g_tx_queue_v1_00 clean
	$(MAKE) -C ./osnt_sume_bram_pcap_replay_uengine_v1_00 clean
	$(MAKE) -C ./osnt_sume_bram_v1_00 clean
	$(MAKE) -C ./osnt_sume_extract_metadata_v1_00 clean
	$(MAKE) -C ./osnt_sume_inter_packet_delay_v1_00 clean
	$(MAKE) -C ./osnt_sume_monitoring_output_port_lookup_v1_00 clean
	$(MAKE) -C ./osnt_sume_packet_cutter_v1_00 clean
	$(MAKE) -C ./osnt_sume_rate_limiter_v1_00 clean
	$(MAKE) -C ./osnt_sume_timestamp_v1_00 clean

