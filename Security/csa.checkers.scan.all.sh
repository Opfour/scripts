#!/bin/bash
# or you could just use 'checkers scan --users' Scan all the things!
# set global variables and make sure that tmp files don't already exist
read -p "LW Username: " _lwuser

_MASTERLOG=/root/checkers_log.$_lwuser

if [ -f docroots.txt ]; then
   >./docroots.txt
else
   touch ./docroots.txt
fi

if [ -f $_MASTERLOG ]; then
   >$_MASTERLOG
else
   touch $_MASTERLOG
fi

# check OS version so we can install latest version of checkers
if [ $(cat /etc/redhat-release|egrep -o "[5,6,7]\."|cut -d. -f1|head -n1) == 5 ]; then
   _OS=old_install
else
   _OS=new_install
fi

# now get fresh copy of checkers
if [ $_OS == "old_install" ]; then
   rm -f /root/bin/checkers
   mkdir -p /root/bin
   wget -q -O /root/bin/checkers http://cmsv.liquidweb.com/checkers
   chmod +x /root/bin/checkers
elif [ $_OS == "new_install" ]; then
   yum -y -q install checkers
else
   echo "Could not determine OS version, exiting."
   exit
fi

# now find document root for all domains (including subdomains) on server and write to tmp file
for i in cat /etc/localdomains; do
   grep -C3 w.$i /usr/local/apache/conf/httpd.conf|awk '/DocumentRoot/ {print $2}'|uniq >>docroots.txt
done

_SCAN=$(for i in cat docroots.txt; do pushd $i;checkers do -M . &>> tmplog.$_lwuser;popd;done)

# now in "checkers_scanall" screen run "checkers do" on each docroot and log results to tmp log
screen -dmS checkers_scanall $_SCAN

_SCAN_RUNNING=1

function SCAN_CHECK {
   screen -ls|grep checkers_scanall|wc -l
}

while [ $_SCAN_RUNNING == 1 ]; do
   if [ SCAN_CHECK == 1 ]; then
       sleep 5
       SCAN_CHECK
   else
       let _SCAN_RUNNING=0
   fi
done

# wait for all scans to complete then write results to final log file
for i in cat docroots.txt; do 
   pushd $i
   echo -e "--------------------\nScan Results for document root: $i\n" >> $_MASTERLOG
   grep -B4 "hits saved in " tmplog.$_lwuser >> $_MASTERLOG
   if [ checkers issues list|wc -l -eq 0 ]; then
       echo -e "\nNo Malicious files found!\n" >> $_MASTERLOG
   else
       echo -e "\n$(checkers issues list -i)\n" >> $_MASTERLOG
   fi
   if [ -f tmplog.$_lwuser ]; then
       rm -f tmplog.$_lwuser
   fi
   popd
done

# clean up tmp files
rm -f ./docroots.txt

# show how to view final log file
clear
echo -e "\nScan Complete! To view results run:\nless $_MASTERLOG\n\n"
