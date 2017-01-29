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

import socket, struct, os, array, sys, time, argparse, re, binascii
from scapy.all import ETH_P_ALL
from scapy.all import select
from generator_cli_lib import *
from monitor_cli_lib import *

def set_if(interface):
   s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
   s.bind((interface, ETH_P_ALL))
   s.setblocking(0)
   os.system("ifconfig "+interface+" up promisc")

def timestamp_capture(interface, tx_ts_pkt_pos, rx_ts_pkt_pos, pkt_no, log_file, send):
   s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
   s.bind((interface, ETH_P_ALL))
   s.setblocking(0)
   os.system("ifconfig "+interface+" up promisc")

   f = open(log_file, "w")
   pkt_no_count = 0
   cal_ts = {}
   tx_ts_1st = float(0)
   rx_ts_1st = float(0)
   tx_ts_enum = float(0)
   rx_ts_enum = float(0)
   tx_time = {}
   rx_time = {}
   tx_ts_begin = 16*(tx_ts_pkt_pos-1)
   tx_ts_end = 16*tx_ts_pkt_pos
   rx_ts_begin = 16*(rx_ts_pkt_pos-1)
   rx_ts_end = 16*rx_ts_pkt_pos
   min_latency = 1000000000
   max_latency = 0

   if (send):
      initgcli.pcap_engine.run()
      print "Start packet generator...!\n"

   while True:
       try:
           packet = s.recv(65000)
           pkt_len = len(packet)
           tx_ts_len = 8*tx_ts_pkt_pos
           rx_ts_len = 8*rx_ts_pkt_pos
           if (pkt_len < tx_ts_len or pkt_len < rx_ts_len):
               print '>>ERROR: Timestamp position is out of packet length!'
               break
   
           pkt_data=''.join('%02x' % ord(b) for b in packet)
           tx_ts_value = pkt_data[tx_ts_begin:tx_ts_end]
           rx_ts_value = pkt_data[rx_ts_begin:rx_ts_end]

           tx_ts_data = hex((int(tx_ts_value[14:16],16)<<56)+\
                            (int(tx_ts_value[12:14],16)<<48)+\
                            (int(tx_ts_value[10:12],16)<<40)+\
                            (int(tx_ts_value[8:10],16)<<32)+\
                            (int(tx_ts_value[6:8],16)<<24)+\
                            (int(tx_ts_value[4:6],16)<<16)+\
                            (int(tx_ts_value[2:4],16)<<8)+\
                            (int(tx_ts_value[0:2],16)))
           rx_ts_data = hex((int(rx_ts_value[14:16],16)<<56)+\
                            (int(rx_ts_value[12:14],16)<<48)+\
                            (int(rx_ts_value[10:12],16)<<40)+\
                            (int(rx_ts_value[8:10],16)<<32)+\
                            (int(rx_ts_value[6:8],16)<<24)+\
                            (int(rx_ts_value[4:6],16)<<16)+\
                            (int(rx_ts_value[2:4],16)<<8)+\
                            (int(rx_ts_value[0:2],16)))
           delta_ts = format(int(rx_ts_data,16) - int(tx_ts_data,16),'016x')
           cal_ts_value = float((int(rx_ts_data,16) - int(tx_ts_data,16))*10**9/2**32)
           tx_value = float(int(tx_ts_data,16)*10**9/2**32)
           rx_value = float(int(rx_ts_data,16)*10**9/2**32)
           if (tx_ts_1st != 0):
               tx_ts_enum = float(tx_value - tx_ts_1st)
           if (rx_ts_1st != 0):
               rx_ts_enum = float(rx_value - rx_ts_1st)

           tx_time[pkt_no_count] = tx_ts_enum
           rx_time[pkt_no_count] = rx_ts_enum

           if (pkt_no_count == 0):
               pkt_bw = 0
           else:
               pkt_bw = float((10**9*8*pkt_len)/(tx_time[pkt_no_count] - tx_time[pkt_no_count-1]))

           bw_unit=""
           if (pkt_bw>999999999):
               bw_unit = "G"
               pkt_bw = pkt_bw/1000000000
           elif (pkt_bw>999999):
               bw_unit = "M"
               pkt_bw = pkt_bw/1000000
           elif (pkt_bw>999):
               bw_unit = "K"
               pkt_bw = pkt_bw/1000
   
           if (tx_ts_1st == 0):
               tx_ts_1st = float(tx_value)
           if (rx_ts_1st == 0):
               rx_ts_1st = float(rx_value)

           if (int(delta_ts,16) < 0):
               print '>>ERROR: Rx and Tx timestamp positions are wrong! Negative value.'
               break

           if (cal_ts_value < min_latency):
               min_latency = cal_ts_value

           if (cal_ts_value > max_latency):
               max_latency = cal_ts_value

           print 'INFO: Packet no: %03d tx: %fus rx: %fus RTT %f nsec %f %sbps' % \
              (pkt_no_count, \
              float(tx_ts_enum/1000), \
              float(rx_ts_enum/1000), \
              cal_ts_value,\
              pkt_bw, bw_unit) 
           f.write("INFO: Packet no: "+str(pkt_no_count)+\
              " delta: 0x"+str(delta_ts)+\
              " ("+str(int(delta_ts,16))+") "+\
              str(cal_ts_value)+" nsec"+\
              str(pkt_bw)+str(bw_unit)+"bps\n"
              );
   
           cal_ts[pkt_no_count] = float(cal_ts_value);
           if ((pkt_no_count+1) == pkt_no):
               break

           pkt_no_count = pkt_no_count + 1
           
       except:
           pass

   avg_ts = 0
   for i in range(pkt_no_count+1):
       avg_ts = float(avg_ts + cal_ts[i])

   total_bw = float((10**9*8*((pkt_no-1)*pkt_len))/tx_time[pkt_no_count])
   bw_unit=""
   if (total_bw>999999999):
       bw_unit = "G"
       total_bw = float(total_bw/1000000000)
   elif (total_bw>999999):
       bw_unit = "M"
       total_bw = float(total_bw/1000000)
   elif (total_bw>999):
       bw_unit = "K"
       total_bw = float(total_bw/1000)

   avg_ts = float(avg_ts/(pkt_no_count+1))
   print '\n => Min %f, Max %f,  Average latency : %f nsec     %f %sbps\n' % (float(min_latency), float(max_latency), float(avg_ts), total_bw, bw_unit)
   f.write("\nAverage latency : " + str(float(avg_ts)) + " nsec\n" + str(float(total_bw)) + str(bw_unit) +"bps");
   f.close()
   sys.exit(1)

def timestamp_calc(tx_ts_pkt_pos, rx_ts_pkt_pos, pkt_no, log_file, pkt_raw_data):

   pkt_no_count = 0
   cal_ts = {}
   tx_time = {}
   rx_time = {}
   tx_ts_1st = float(0)
   rx_ts_1st = float(0)
   tx_ts_enum = float(0)
   rx_ts_enum = float(0)
   min_latency = 1000000000
   max_latency = 0
   tx_ts_begin = 16*(tx_ts_pkt_pos-1)
   tx_ts_end = 16*tx_ts_pkt_pos
   rx_ts_begin = 16*(rx_ts_pkt_pos-1)
   rx_ts_end = 16*rx_ts_pkt_pos
   tx_ts_len = 8*tx_ts_pkt_pos
   rx_ts_len = 8*rx_ts_pkt_pos

   f = open("tcpdump_"+log_file, "w")
   print "Packet no. "+str(len(pkt_raw_data))

   for pkt_data in pkt_raw_data:

      pkt_len = len(pkt_data)
      if (pkt_len < tx_ts_len or pkt_len < rx_ts_len):
         print '>>ERROR: Timestamp position is out of packet length!'
         sys.exit(1)
      
      pkt_data=''.join('%02x' % ord(b) for b in pkt_data)
      tx_ts_value = pkt_data[tx_ts_begin:tx_ts_end]
      rx_ts_value = pkt_data[rx_ts_begin:rx_ts_end]

      tx_ts_data = hex((int(tx_ts_value[14:16],16)<<56)+\
                       (int(tx_ts_value[12:14],16)<<48)+\
                       (int(tx_ts_value[10:12],16)<<40)+\
                       (int(tx_ts_value[8:10],16)<<32)+\
                       (int(tx_ts_value[6:8],16)<<24)+\
                       (int(tx_ts_value[4:6],16)<<16)+\
                       (int(tx_ts_value[2:4],16)<<8)+\
                       (int(tx_ts_value[0:2],16)))
      rx_ts_data = hex((int(rx_ts_value[14:16],16)<<56)+\
                       (int(rx_ts_value[12:14],16)<<48)+\
                       (int(rx_ts_value[10:12],16)<<40)+\
                       (int(rx_ts_value[8:10],16)<<32)+\
                       (int(rx_ts_value[6:8],16)<<24)+\
                       (int(rx_ts_value[4:6],16)<<16)+\
                       (int(rx_ts_value[2:4],16)<<8)+\
                       (int(rx_ts_value[0:2],16)))
      delta_ts = format(int(rx_ts_data,16) - int(tx_ts_data,16),'016x')
      cal_ts_value = float((int(rx_ts_data,16) - int(tx_ts_data,16))*10**9/2**32)
      tx_value = float(int(tx_ts_data,16)*10**9/2**32)
      rx_value = float(int(rx_ts_data,16)*10**9/2**32)
      if (tx_ts_1st != 0):
          tx_ts_enum = float(tx_value - tx_ts_1st)
      if (rx_ts_1st != 0):
          rx_ts_enum = float(rx_value - rx_ts_1st)

      tx_time[pkt_no_count] = tx_ts_enum
      rx_time[pkt_no_count] = rx_ts_enum

      if (pkt_no_count == 0):
          pkt_bw = 0
      else:
          pkt_bw = float((10**9*8*pkt_len)/(tx_time[pkt_no_count] - tx_time[pkt_no_count-1]))

      bw_unit=""
      if (pkt_bw>999999999):
          bw_unit = "G"
          pkt_bw = pkt_bw/1000000000
      elif (pkt_bw>999999):
          bw_unit = "M"
          pkt_bw = pkt_bw/1000000
      elif (pkt_bw>999):
          bw_unit = "K"
          pkt_bw = pkt_bw/1000
      
      if (tx_ts_1st == 0):
          tx_ts_1st = float(tx_value)
      if (rx_ts_1st == 0):
          rx_ts_1st = float(rx_value)

      if (cal_ts_value < min_latency):
          min_latency = cal_ts_value

      if (cal_ts_value > max_latency):
          max_latency = cal_ts_value

      print 'INFO: Packet no: %03d tx: %fus rx: %fus RTT %f nsec %f %sbps' % \
         (pkt_no_count, \
         float(tx_ts_enum/1000), \
         float(rx_ts_enum/1000), \
         cal_ts_value,\
         pkt_bw, bw_unit) 
      f.write("INFO: Packet no: "+str(pkt_no_count)+\
         " delta: 0x"+str(delta_ts)+\
         " ("+str(int(delta_ts,16))+") "+\
         str(cal_ts_value)+" nsec"+\
         str(pkt_bw)+str(bw_unit)+"bps\n"
         );
      
      if (int(delta_ts,16) < 0 or tx_ts_enum < 0 or rx_ts_enum < 0):
          print '\n >>ERROR: Rx and Tx timestamp are wrong! Negative value. <<\n'
          if (os.system("ps -e | pgrep tcpdump | awk '{print $0}'") != 0):
              os.system("if [ "+find_pid+" != NULL ]; then kill -9 "+find_pid+"; fi > pid_out.log")
          sys.exit(1)

      cal_ts[pkt_no_count] = float(cal_ts_value);
      pkt_no_count = pkt_no_count + 1
           
   avg_ts = 0
   for i in range(pkt_no_count):
       avg_ts = float(avg_ts + cal_ts[i])

   total_bw = float((10**9*8*((pkt_no-1)*pkt_len))/tx_time[pkt_no_count-1])
   bw_unit=""
   if (total_bw>999999999):
       bw_unit = "G"
       total_bw = float(total_bw/1000000000)
   elif (total_bw>999999):
       bw_unit = "M"
       total_bw = float(total_bw/1000000)
   elif (total_bw>999):
       bw_unit = "K"
       total_bw = float(total_bw/1000)

   avg_ts = float(avg_ts/(pkt_no_count+1))
   print '\n => Min %f, Max %f,  Average latency : %f nsec     %f %sbps\n' % (float(min_latency), float(max_latency), float(avg_ts), total_bw, bw_unit)
   f.write("\nAverage latency : " + str(float(avg_ts)) + " nsec\n" + str(float(total_bw)) + str(bw_unit) +"bps");
   f.close()


def timestamp_tcpdump(interface, tx_ts_pkt_pos, rx_ts_pkt_pos, pkt_no, log_file, send):
   if_no={"nf0": 0, "nf1": 1, "nf2": 2, "nf3": 3}

   find_pid = "$(ps -e | pgrep tcpdump | awk '{print $0}')"
   if (os.system("ps -e | pgrep tcpdump | awk '{print $0}'") != 0):
      os.system("if [ "+find_pid+" != NULL ]; then kill -9 "+find_pid+"; fi > pid_out.log")

   sleep(0.5)
   os.system("tcpdump -i"+interface+" -c "+str(pkt_no)+" -B 8192 -K -w latency_dump.pcap &")
   if (send):
      print "Start packet generator...!\n"
      initgcli.pcap_engine.run()

   initmcli.osnt_monitor_stats.get_stats()
   pkt_count = int(initmcli.osnt_monitor_stats.pkt_cnt[if_no[interface]], 16)
   while (pkt_count < pkt_no):
      initmcli.osnt_monitor_stats.get_stats()
      pkt_count = int(initmcli.osnt_monitor_stats.pkt_cnt[if_no[interface]], 16)
      sleep(0.5)

   sleep(1)
   os.system("echo " " > latency_dump_conv.pcap")
   os.system("tcpdump -r latency_dump.pcap -xx > latency_dump_conv.pcap")

   pcap_file = open("latency_dump_conv.pcap")
   pkt_count = 0
   pkts = [] 

   for line_data in pcap_file.readlines():
      line_array_data=re.findall(r"[\S']+", line_data)
   
      for line_word in line_array_data:
         if (line_word == "0x0000:"):
            if (pkt_count != 0):
               pkt_data = pkt_data.decode("hex")
               pkts.append(pkt_data)
            pkt_data=""
            pkt_count=pkt_count+1
   
         if (bool(re.compile(r'(0x)(\w+)(?=\:$)').match(line_word))):
            pkt_line_data = "".join(line_array_data[1:])
            pkt_data=pkt_data+pkt_line_data

   pkt_data = pkt_data.decode("hex")
   pkts.append(pkt_data)
  
   timestamp_calc(tx_ts_pkt_pos, rx_ts_pkt_pos, pkt_no, log_file, pkts)
   if (os.system("ps -e | pgrep tcpdump | awk '{print $0}'") != 0):
      os.system("if [ "+find_pid+" != NULL ]; then kill -9 "+find_pid+"; fi > pid_out.log")
