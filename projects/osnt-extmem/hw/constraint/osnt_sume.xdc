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


set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]

# PCIe Transceiver clock (100 MHz)
set_property PACKAGE_PIN AB8 [get_ports sys_clkp]
set_property PACKAGE_PIN AB7 [get_ports sys_clkn]

set_property LOC IBUFDS_GTE2_X1Y11 [get_cells -hier -filter name=~*IBUFDS_GTE2*]
create_clock -period 10.000 -name pcie_sys_clk [get_pins -hier -filter name=~*IBUFDS_GTE2*/O]

# PCIe sys reset
set_property PACKAGE_PIN AY35 [get_ports pcie_sys_resetn]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_resetn]
set_property PULLUP true [get_ports pcie_sys_resetn]

set_false_path -from [get_ports pcie_sys_resetn]

# 200MHz System Clock
set_property PACKAGE_PIN G18 [get_ports fpga_sysclk_n]
set_property PACKAGE_PIN H19 [get_ports fpga_sysclk_p]

set_property VCCAUX_IO DONTCARE [get_ports fpga_sysclk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports fpga_sysclk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports fpga_sysclk_n]

create_clock -period 5.000 -name sys_clk_ref [get_pins -hier -filter name=~*sysclk_buf/IBUF_OUT*]

# Main I2C Bus - 100KHz
set_property IOSTANDARD LVCMOS18 [get_ports iic_fpga_scl_io]
set_property SLEW SLOW [get_ports iic_fpga_scl_io]
set_property DRIVE 16 [get_ports iic_fpga_scl_io]
set_property PULLUP true [get_ports iic_fpga_scl_io]
set_property PACKAGE_PIN AK24 [get_ports iic_fpga_scl_io]

set_property IOSTANDARD LVCMOS18 [get_ports iic_fpga_sda_io]
set_property SLEW SLOW [get_ports iic_fpga_sda_io]
set_property DRIVE 16 [get_ports iic_fpga_sda_io]
set_property PULLUP true [get_ports iic_fpga_sda_io]
set_property PACKAGE_PIN AK25 [get_ports iic_fpga_sda_io]

# i2c_reset[0] - iic_mux reset - high active
# i2c_reset[1] - si5324 reset - high active
set_property SLEW SLOW [get_ports {iic_reset[*]}]
set_property DRIVE 16 [get_ports {iic_reset[*]}]
set_property PACKAGE_PIN AM39 [get_ports {iic_reset[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {iic_reset[0]}]
set_property PACKAGE_PIN BA29 [get_ports {iic_reset[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {iic_reset[1]}]

# UART - 115200 8-1 no parity
set_property PACKAGE_PIN AY19 [get_ports uart_rxd]
set_property PACKAGE_PIN BA19 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS15 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS15 [get_ports uart_txd]

# reset - Btn0
set_property PACKAGE_PIN AR13 [get_ports reset]
set_property IOSTANDARD LVCMOS15 [get_ports reset]


# GPIO Connection for signal from outside eg gps.
# PMOD_OE_B pull high pin = C40
set_property PACKAGE_PIN C40 [get_ports pmod_en]
set_property PULLDOWN true [get_ports pmod_en]
set_property IOSTANDARD LVCMOS15 [get_ports pmod_en]

#
# GPI
# JA1_FPGA pin = AW18
set_property PACKAGE_PIN AW18 [get_ports gps_signal]
set_property IOSTANDARD LVCMOS15 [get_ports gps_signal]
# DIR_JA1 = pull down pin = AT16
set_property PACKAGE_PIN AT16 [get_ports gps_signal_dir]
set_property PULLDOWN true [get_ports gps_signal_dir]
set_property IOSTANDARD LVCMOS15 [get_ports gps_signal_dir]

# GPO
# JA7_FPGA ping = AT20
set_property PACKAGE_PIN AT20 [get_ports ts_pulse_0]
set_property IOSTANDARD LVCMOS15 [get_ports ts_pulse_0]
# DIR_JA7 = pull up pin = AW20
set_property PACKAGE_PIN AW20 [get_ports ts_pulse_dir_0]
set_property PULLUP true [get_ports ts_pulse_dir_0]
set_property IOSTANDARD LVCMOS15 [get_ports ts_pulse_dir_0]

# GPO
# JA2_FPGA ping = AW17
set_property PACKAGE_PIN AW17 [get_ports ts_pulse_1]
set_property IOSTANDARD LVCMOS15 [get_ports ts_pulse_1]
# DIR_JA7 = pull up pin = AU16
set_property PACKAGE_PIN AU16 [get_ports ts_pulse_dir_1]
set_property PULLDOWN true [get_ports ts_pulse_dir_1]
set_property IOSTANDARD LVCMOS15 [get_ports ts_pulse_dir_1]

set_property PACKAGE_PIN AD33 [get_ports qdra_clk_n]
set_property PACKAGE_PIN AD32 [get_ports qdra_clk_p]

set_property VCCAUX_IO DONTCARE [get_ports qdra_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports qdra_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports qdra_clk_n]

set_property PACKAGE_PIN AU14 [get_ports qdrc_clk_n]
set_property PACKAGE_PIN AU13 [get_ports qdrc_clk_p]

set_property VCCAUX_IO DONTCARE [get_ports qdrc_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports qdrc_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports qdrc_clk_n]

set_property PACKAGE_PIN E35 [get_ports ddr3_clk_n]
set_property PACKAGE_PIN E34 [get_ports ddr3_clk_p]

set_property VCCAUX_IO DONTCARE [get_ports ddr3_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports ddr3_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports ddr3_clk_n]

# Timing Constraints
create_clock -period 4.375 [get_nets ddr3_clk_p]

set_propagated_clock sys_clk_i
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets -hier -filter name=~*ddr3*mig*/sys_clk_i]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -hierarchical *ddr3*pll*CLKIN1]

### Note: CLK_REF FALSE Constraint
set_property CLOCK_DEDICATED_ROUTE FALSE [get_pins -hierarchical *ddr3A*clk_ref_mmcm_gen.mmcm_i*CLKIN1]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_pins -hierarchical *ddr3B*clk_ref_mmcm_gen.mmcm_i*CLKIN1]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets system_i/sume_osnt_dma/pcie3_7x_1/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/pipe_txoutclk_out]
