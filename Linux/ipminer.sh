#IP Miner
#Looks for IP errors in common logs
#Created By: Mark Benedict
#!/bin/bash

clear
ver=v1.0
echo "IP Miner $ver"
echo "Mark Benedict"
echo ""
echo “Enter IP Address”
read ip
clear
echo ""
echo ""
echo "IP Miner $ver"
echo "Mark Benedict"
echo "*****************************"
echo "Server Name - `hostname`"
echo "Server Time - `date`"
echo "*****************************"
echo ""
echo ""
echo "Mining results for $ip"
echo ""
echo ""
echo "CSF Results - "
echo ""
less /etc/csf/* |grep $ip
echo ""
echo "_______________"
echo ""
echo "APF Results - "
echo ""
less /etc/apf/* |grep $ip
echo ""
echo "_______________"
echo ""
echo "LFD Results - "
echo ""
cat /var/log/lfd.log|grep $ip
echo ""
echo "_______________"
echo ""
echo "Email Logins - "
echo ""
grep $ip /var/log/maillog | grep -i failed |tail -15
echo ""
echo "_______________"
echo ""
echo "SSH Logins - "
echo ""
cat /var/log/secure |grep "$ip"
#tail -15 /var/log/lfd.log |grep "*SSH" |grep "$ip"
#awk -F: '{ print $1, $2, $3}' /var/log/lfd.log |grep $ip |grep "SSH"
echo ""
echo "_______________"
echo ""
echo "WHM/Cpanel Access - "
echo ""
cat /usr/local/cpanel/logs/login_log |grep $ip
echo ""
echo "_______________"
echo ""
echo "MOD Security - "
echo ""
grep -R $ip /usr/local/apache/logs/error_log | grep modsec | tail -10
echo "_______________"
echo ""
echo "Network Connections on `date` - "
echo ""
netstat -alntp | grep $ip
echo ""
echo "End of results for $ip"