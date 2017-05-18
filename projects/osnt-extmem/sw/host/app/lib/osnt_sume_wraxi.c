/*
 * Copyright (c) 2016 University of Cambridge
 * Copyright (c) 2016 Jong Hun Han 
 * All rights reserved.
 *
 * This software was developed by University of Cambridge Computer Laboratory
 * under the ENDEAVOUR project (grant agreement 644960) as part of
 * the European Union's Horizon 2020 research and innovation programme.
 * File:
 *
 * @NETFPGA_LICENSE_HEADER_START@
 *
 * Licensed to NetFPGA Open Systems C.I.C. (NetFPGA) under one or more
 * contributor license agreements.  See the NOTICE file distributed with this
 * work for additional information regarding copyright ownership.  NetFPGA
 * licenses this file to you under the NetFPGA Hardware-Software License,
 * Version 1.0 (the "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at:
 *
 *   http://www.netfpga-cic.org
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @NETFPGA_LICENSE_HEADER_END@
 *
*/

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <net/if.h>
#include <err.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "nf_sume.h"

int main (int argc, const char *argv[])
{
   uint32_t wr_addr;
   uint32_t wr_data;

	char *ifnam;
	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	int fd, rc, req;

   if (argc < 2) {
      printf("\nCheck input arguments...\n");
      printf("===> ./wraxi <address 32bits hex> <data 32bits hex?\n");
      exit(0);
   }

   sscanf(argv[1], "%x", &wr_addr);
   sscanf(argv[2], "%x", &wr_data);

	ifnam = SUME_IFNAM_DEFAULT;
	req = SUME_IOCTL_CMD_READ_REG;

	ifnamlen = strlen(ifnam);

	fd = socket(AF_INET6, SOCK_DGRAM, 0);
	if (fd == -1) {
		fd = socket(AF_INET, SOCK_DGRAM, 0);
		if (fd == -1)
			err(1, "socket failed for AF_INET6 and AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = wr_addr;
	sifr.val = wr_data;
	req = SUME_IOCTL_CMD_WRITE_REG;

	memset(&ifr, 0, sizeof(ifr));
	if (ifnamlen >= sizeof(ifr.ifr_name))
		errx(1, "Interface name too long");
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;
	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	
	close(fd);

   return 0;
}
