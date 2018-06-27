#!/bin/bash
#########################################
# ==Guardian Information Script== Created by RLong, questions or comments to rlong@liquidweb.com with "Guardian Script" as the subject.
#
#########################################
#
# This script will procure useful information on Debian and RedHat Based Operating Systems
#########################################
#Version: 0.5beta
#########################################
#
#########################################
#Debian Information
#########################################

if [ -e /etc/debian_version ]; then
	echo "Backup / CDP Agent Status";
	/etc/init.d/buagent status 2>/dev/null || /etc/init.d/cdp-agent status 2>/dev/null;
	echo ;
	echo "Current 10.x IPs on server"; 
	ifconfig | grep -C2 --color=never "inet addr:10"; 
	echo ;
	echo "Currently set Network Routes"; 
	ip route show|grep --color=never "10.*"; 
	echo; 
	echo "Operating System and Version"; 
	cat /etc/os-release | head -1; 
	echo; 
	echo "Kernel Version"; 
	uname -r; 
	echo; 
	echo "kernel-headers Version"; 
	dpkg -l 2>/dev/null | grep --color=never linux-headers
	echo; 
	echo "Backup / CDP Agent Version"; 
	dpkg -l 2>/dev/null | grep --color=never r1soft 2>/dev/null || dpkg -l 2>/dev/null| grep --color=never serverbackup 2>/dev/null; 
	echo; 
	echo "HCP Module Version"; 
	hcp --version | tail -1;	

#######################################
#RedHat Information
#######################################	
	
elif [ -e /etc/redhat-release ]; then
	echo "Backup / CDP Agent Status";
	/etc/init.d/buagent status 2>/dev/null || /etc/init.d/cdp-agent status 2>/dev/null;
	echo ;
	echo "Current 10.x IPs on server"; 
	ifconfig | grep -C2 --color=never "inet addr:10"; 
	echo; 
	echo "Currently set Network Routes"; 
	cat /etc/sysconfig/network-scripts/route-eth*; 
	echo; 
	echo "Operating System and Version"; 
	cat /etc/redhat-release; 
	echo; 
	echo "Kernel Version"; 
	uname -r; 
	echo; 
	echo "kernel-headers Version"; 
	rpm -qa kernel-headers 2>/dev/null; 
	echo; 
	echo "Backup / CDP Agent Version"; 
	rpm -qa | grep --color=never r1soft 2>/dev/null || rpm -qa | grep --color=never serverbackup; 
	echo; 
	echo "HCP Module Version"; 
	hcp --version | tail -1;

######################################
#If not Debian or Redhat, fail:
######################################

else 
	echo "Unrecognized Operating System, this script only works on Debian and RedHat based Operating Systems";
fi
