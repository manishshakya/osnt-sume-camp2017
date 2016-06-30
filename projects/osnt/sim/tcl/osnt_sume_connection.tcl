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


# External ports connection
connect_bd_net [get_bd_ports reset] [get_bd_pins sys_clock_0/reset]
connect_bd_net [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]

connect_bd_net [get_bd_ports fpga_sysclk_n] [get_bd_pins sysclk_buf/IBUF_DS_N]
connect_bd_net [get_bd_ports fpga_sysclk_p] [get_bd_pins sysclk_buf/IBUF_DS_P]

connect_bd_net [get_bd_pins sys_clock_0/clk_in1] [get_bd_pins sysclk_buf/IBUF_OUT]
connect_bd_net [get_bd_pins sys_clock_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]

# 100MHz clock scheme - address mapped registers
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins osnt_sume_axi_sim_transactor_0/axi_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/AClk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out1] [get_bd_pins axi_interconnect_0/S00_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M00_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M01_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M02_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M03_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M04_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M05_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M06_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M07_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M08_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M09_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M10_ACLK] 
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_interconnect_0/M11_ACLK] 

# 160Mhz clock scheme - data stream
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_stim_0/ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_stim_1/ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_stim_2/ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_stim_3/ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_stim_4/ACLK]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_record_0/axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_record_1/axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_record_2/axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_record_3/axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axis_sim_record_4/axi_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_nic_output_port_lookup_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_input_arbiter_0/axis_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_inter_packet_delay_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_rate_limiter_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_extract_metadata_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/s_axi_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_inter_packet_delay_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_rate_limiter_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_extract_metadata_0/axis_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/axis_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_packet_cutter_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_timestamp_0/S_AXI_ACLK]
#connect_bd_net [get_bd_pins sume_osnt_10g_interface/clk156_out] [get_bd_pins osnt_sume_timestamp_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_monitoring_output_port_lookup_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_endianess_manager_0/ACLK]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_bram_output_queues_0/axis_aclk]

connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk]
connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins axi_bram_ctrl_3/s_axi_aclk]


connect_bd_net [get_bd_pins sys_clock_0/clk_out2] [get_bd_pins osnt_sume_axi_if_0/S_AXI_ACLK]

#Reset module connection
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M02_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M03_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M04_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M05_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M06_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M07_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M08_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M09_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M10_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M11_ARESETN]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_nic_output_port_lookup_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_input_arbiter_0/axis_aresetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_inter_packet_delay_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_rate_limiter_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_extract_metadata_0/s_axi_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/s_axi_aresetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_inter_packet_delay_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_rate_limiter_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_extract_metadata_0/axis_aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/axis_aresetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_packet_cutter_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_timestamp_0/S_AXI_ARESETN]
#connect_bd_net [get_bd_pins sume_osnt_10g_interface/aresetn_clk156_out] [get_bd_pins osnt_sume_timestamp_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_monitoring_output_port_lookup_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_bram_output_queues_0/axis_resetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_endianess_manager_0/ARESETN]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_3/s_axi_aresetn]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_axi_sim_transactor_0/axi_resetn] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_axis_sim_stim_0/ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_axis_sim_stim_1/ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_axis_sim_stim_2/ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_axis_sim_stim_3/ARESETN] 
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins osnt_sume_axis_sim_stim_4/ARESETN] 

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins  osnt_sume_axi_if_0/S_AXI_ARESETN] 

#Axi-Lite bus interface connection
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins osnt_sume_axi_sim_transactor_0/M_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s_axi] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins osnt_sume_rate_limiter_0/s_axi] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins osnt_sume_extract_metadata_0/s_axi] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins osnt_sume_bram_pcap_replay_uengine_0/s_axi]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins osnt_sume_packet_cutter_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins osnt_sume_timestamp_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins osnt_sume_monitoring_output_port_lookup_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M07_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M08_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M09_AXI] [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M10_AXI] [get_bd_intf_pins axi_bram_ctrl_3/S_AXI] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M11_AXI] [get_bd_intf_pins osnt_sume_axi_if_0/S_AXI] 

#Axi-stream data interface connection
connect_bd_intf_net [get_bd_intf_pins osnt_sume_axis_sim_stim_0/M_AXIS] [get_bd_intf_pins osnt_sume_input_arbiter_0/s0_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_axis_sim_stim_1/M_AXIS] [get_bd_intf_pins osnt_sume_input_arbiter_0/s1_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_axis_sim_stim_2/M_AXIS] [get_bd_intf_pins osnt_sume_input_arbiter_0/s2_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_axis_sim_stim_3/M_AXIS] [get_bd_intf_pins osnt_sume_input_arbiter_0/s3_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_axis_sim_stim_4/M_AXIS] [get_bd_intf_pins osnt_sume_extract_metadata_0/s_axis]

connect_bd_net [get_bd_pins osnt_sume_axi_sim_transactor_0/barrier_req_trans] [get_bd_pins osnt_sume_axi_sim_transactor_0/barrier_proceed]

connect_bd_net [get_bd_pins osnt_sume_axis_sim_stim_0/barrier_req] [get_bd_pins osnt_sume_axis_sim_stim_0/barrier_proceed]
connect_bd_net [get_bd_pins osnt_sume_axis_sim_stim_1/barrier_req] [get_bd_pins osnt_sume_axis_sim_stim_1/barrier_proceed]
connect_bd_net [get_bd_pins osnt_sume_axis_sim_stim_2/barrier_req] [get_bd_pins osnt_sume_axis_sim_stim_2/barrier_proceed]
connect_bd_net [get_bd_pins osnt_sume_axis_sim_stim_3/barrier_req] [get_bd_pins osnt_sume_axis_sim_stim_3/barrier_proceed]
connect_bd_net [get_bd_pins osnt_sume_axis_sim_stim_4/barrier_req] [get_bd_pins osnt_sume_axis_sim_stim_4/barrier_proceed]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_input_arbiter_0/m_axis] [get_bd_intf_pins osnt_sume_endianess_manager_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_packet_cutter_0/M_AXIS] [get_bd_intf_pins osnt_sume_endianess_manager_0/S_AXIS_INT]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_endianess_manager_0/M_AXIS] [get_bd_intf_pins osnt_sume_bram_output_queues_0/s_axis] 
connect_bd_intf_net [get_bd_intf_pins osnt_sume_endianess_manager_0/M_AXIS_INT] [get_bd_intf_pins osnt_sume_monitoring_output_port_lookup_0/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m0_axis] [get_bd_intf_pins osnt_sume_axis_sim_record_0/s_axis] 
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m1_axis] [get_bd_intf_pins osnt_sume_axis_sim_record_1/s_axis] 
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m2_axis] [get_bd_intf_pins osnt_sume_axis_sim_record_2/s_axis] 
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m3_axis] [get_bd_intf_pins osnt_sume_axis_sim_record_3/s_axis] 
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_output_queues_0/m4_axis] [get_bd_intf_pins osnt_sume_axis_sim_record_4/s_axis] 

connect_bd_intf_net [get_bd_intf_pins osnt_sume_monitoring_output_port_lookup_0/M_AXIS] [get_bd_intf_pins osnt_sume_packet_cutter_0/S_AXIS]

connect_bd_net [get_bd_pins osnt_sume_timestamp_0/STAMP_COUNTER] [get_bd_pins osnt_sume_monitoring_output_port_lookup_0/STAMP_COUNTER]

#connect_bd_net [get_bd_pins osnt_sume_timestamp_0/PPS_RX] [get_bd_pins gps_signal]
#connect_bd_net [get_bd_pins osnt_sume_timestamp_0/ts_pulse] [get_bd_pins ts_pulse_0]
#connect_bd_net [get_bd_pins osnt_sume_timestamp_0/ts_pulse] [get_bd_pins ts_pulse_1]

# Need nic to avoid null destination port info
#connect_bd_intf_net [get_bd_intf_pins osnt_sume_input_arbiter_0/m_axis] [get_bd_intf_pins osnt_sume_nic_output_port_lookup_1/s_axis]
#connect_bd_intf_net [get_bd_intf_pins osnt_sume_nic_output_port_lookup_1/m_axis] [get_bd_intf_pins sume_osnt_dma/s_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_extract_metadata_0/m_axis] [get_bd_intf_pins osnt_sume_nic_output_port_lookup_0/s_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_nic_output_port_lookup_0/m_axis] [get_bd_intf_pins osnt_sume_bram_pcap_replay_uengine_0/s_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_pcap_replay_uengine_0/m0_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s0_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_pcap_replay_uengine_0/m1_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s1_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_pcap_replay_uengine_0/m2_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s2_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_bram_pcap_replay_uengine_0/m3_axis] [get_bd_intf_pins osnt_sume_inter_packet_delay_0/s3_axis]

connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m0_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s0_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m1_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s1_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m2_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s2_axis]
connect_bd_intf_net [get_bd_intf_pins osnt_sume_inter_packet_delay_0/m3_axis] [get_bd_intf_pins osnt_sume_rate_limiter_0/s3_axis]

connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_clk_a] [get_bd_pins osnt_sume_bram_0/bram_clk_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_addr_a] [get_bd_pins osnt_sume_bram_0/bram_addr_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_wrdata_a] [get_bd_pins osnt_sume_bram_0/bram_wrdata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_rddata_a] [get_bd_pins osnt_sume_bram_0/bram_rddata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_en_a] [get_bd_pins osnt_sume_bram_0/bram_en_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_we_a] [get_bd_pins osnt_sume_bram_0/bram_we_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_rst_a] [get_bd_pins osnt_sume_bram_0/bram_rst_a]

connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_clk_a] [get_bd_pins osnt_sume_bram_1/bram_clk_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_addr_a] [get_bd_pins osnt_sume_bram_1/bram_addr_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_wrdata_a] [get_bd_pins osnt_sume_bram_1/bram_wrdata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_rddata_a] [get_bd_pins osnt_sume_bram_1/bram_rddata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_en_a] [get_bd_pins osnt_sume_bram_1/bram_en_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_we_a] [get_bd_pins osnt_sume_bram_1/bram_we_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_1/bram_rst_a] [get_bd_pins osnt_sume_bram_1/bram_rst_a]

connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_clk_a] [get_bd_pins osnt_sume_bram_2/bram_clk_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_addr_a] [get_bd_pins osnt_sume_bram_2/bram_addr_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_wrdata_a] [get_bd_pins osnt_sume_bram_2/bram_wrdata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_rddata_a] [get_bd_pins osnt_sume_bram_2/bram_rddata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_en_a] [get_bd_pins osnt_sume_bram_2/bram_en_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_we_a] [get_bd_pins osnt_sume_bram_2/bram_we_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_2/bram_rst_a] [get_bd_pins osnt_sume_bram_2/bram_rst_a]

connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_clk_a] [get_bd_pins osnt_sume_bram_3/bram_clk_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_addr_a] [get_bd_pins osnt_sume_bram_3/bram_addr_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_wrdata_a] [get_bd_pins osnt_sume_bram_3/bram_wrdata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_rddata_a] [get_bd_pins osnt_sume_bram_3/bram_rddata_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_en_a] [get_bd_pins osnt_sume_bram_3/bram_en_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_we_a] [get_bd_pins osnt_sume_bram_3/bram_we_a]
connect_bd_net [get_bd_pins axi_bram_ctrl_3/bram_rst_a] [get_bd_pins osnt_sume_bram_3/bram_rst_a]

connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/clka0] [get_bd_pins osnt_sume_bram_0/bram_clk_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/addra0] [get_bd_pins osnt_sume_bram_0/bram_addr_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/ena0] [get_bd_pins osnt_sume_bram_0/bram_en_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/wea0] [get_bd_pins osnt_sume_bram_0/bram_we_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/douta0] [get_bd_pins osnt_sume_bram_0/bram_wrdata_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/dina0] [get_bd_pins osnt_sume_bram_0/bram_rddata_b]

connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/clka1] [get_bd_pins osnt_sume_bram_1/bram_clk_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/addra1] [get_bd_pins osnt_sume_bram_1/bram_addr_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/ena1] [get_bd_pins osnt_sume_bram_1/bram_en_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/wea1] [get_bd_pins osnt_sume_bram_1/bram_we_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/douta1] [get_bd_pins osnt_sume_bram_1/bram_wrdata_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/dina1] [get_bd_pins osnt_sume_bram_1/bram_rddata_b]

connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/clka2] [get_bd_pins osnt_sume_bram_2/bram_clk_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/addra2] [get_bd_pins osnt_sume_bram_2/bram_addr_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/ena2] [get_bd_pins osnt_sume_bram_2/bram_en_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/wea2] [get_bd_pins osnt_sume_bram_2/bram_we_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/douta2] [get_bd_pins osnt_sume_bram_2/bram_wrdata_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/dina2] [get_bd_pins osnt_sume_bram_2/bram_rddata_b]

connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/clka3] [get_bd_pins osnt_sume_bram_3/bram_clk_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/addra3] [get_bd_pins osnt_sume_bram_3/bram_addr_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/ena3] [get_bd_pins osnt_sume_bram_3/bram_en_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/wea3] [get_bd_pins osnt_sume_bram_3/bram_we_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/douta3] [get_bd_pins osnt_sume_bram_3/bram_wrdata_b]
connect_bd_net [get_bd_pins osnt_sume_bram_pcap_replay_uengine_0/dina3] [get_bd_pins osnt_sume_bram_3/bram_rddata_b]
