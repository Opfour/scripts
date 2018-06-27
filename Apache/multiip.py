#!/usr/bin/env python

# Set LIMIT 1 higher than the last IP you want to use.
LIMIT=188
# Set this to the box's main IP.
MAINIP="72.52.159.128"
# Set this to the correct gateway IP.
gateway="72.52.158.1"

OCTETS = MAINIP.split(".")

max = LIMIT - int(OCTETS[-1])
firstip = int(OCTETS[-1])

for x in range(1, max):
	last = firstip + x
	f = open("/etc/sysconfig/network-scripts/ifcfg-eth0:%s" %x, 'w')
	f.write("DEVICE=eth0:%s\n" %x)
	f.write("ONBOOT=yes\n")
	f.write("BOOTPROTO=static\n")
	f.write("IPADDR=%s.%s.%s.%s\n" %(OCTETS[0], OCTETS[1], OCTETS[2], last))
	f.write("NETMASK=255.255.254.0\n")
	f.write("GATEWAY=%s\n" %gateway)

