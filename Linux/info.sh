#!/bin/bash
# COLLECT INFO
SYSINFO=`cat /etc/issue | sort | uniq | awk '/[a-zA-Z]/{printf $1" "$2" "$3" "$4" "$5" 
IFS=$'\n'
UPTIME=`uptime`
D_UP=${UPTIME:1}
MYGROUPS=`groups`
DATE=`date`
KERNEL=`uname -a`
#SYSINFO=`head -n 1 /etc/issue`
CPWD=`pwd`
ME=`whoami`
 
# OUTPUT DATA
#printf "  user:\t\t"$USER" (uid:"$UID")\n"

printf "<=== SYSTEM ===>\n"
echo "------------------------------------------"
echo "  Linux Distro Details info:  - "$SYSINFO""
echo "OS Version:  `cat /etc/*release |head -1`"
echo "Kernel Version: `uname -r`"
printf "  Kernel:\t"$KERNEL"\n"
echo ""

printf "  Uptime:\t"$D_UP"\n"
echo "------------------------------------------"
echo "Server Name - `hostname`"
echo "Server Time - `date`"
echo "------------------------------------------"
free -mot | awk '
/Mem/{print "  Memory:\tTotal: " $2 "Mb\tUsed: " $3 "Mb\tFree: " $4 "Mb"}
/Swap/{print "  Swap:\t\tTotal: " $2 "Mb\tUsed: " $3 "Mb\tFree: " $4 "Mb"}'
echo "RAM  Availible: `free -m |sed -n '2p' |awk '{ print $2 }'`MB"
echo "Harddrive: `df -h |sed -n '1p'| awk '{ print $2,$3,$4,$5 }'` "
echo "             `df -h |sed -n '2p'| awk '{ print $2, $3,$4,$5 }'` "
echo ""
echo "------------------------------------------"
echo "Basic Hardware -"
echo "CPUs Availible: `lscpu |grep "CPU(s):" |awk '{ print $2 }' |head -1`@ `cat /proc/cpui
printf "  Architecture:\t"$CPU"\n"
cat /proc/cpuinfo | grep "model name\|processor" | awk ' /processor/{printf "  Processor:\t" $3 " : " } /model\ name/
{i=4
while(i<=NF){
 printf $i
  if(i<NF){
    printf " "
  }
  i++
}
printf "\n"
}'

awk '/model name/  {ORS=""; count++; if ( count == 1 ) print  $0; }  END {  print " : " count "\n" }' /proc/cpuinfo

echo "------------------------------------------"
printf "  Date:\t\t"$DATE"\n"
printf "\n<=== USER ===>\n"
printf "  User:\t\t"$ME" (uid:"$UID")\n"
printf "  Groups:\t"$MYGROUPS"\n"
printf "  Working dir:\t"$CPWD"\n"
printf "  Home dir:\t"$HOME"\n"
echo "------------------------------------------"
printf "\n<=== NETWORK ===>\n"
printf "  Hostname:\t"$HOSTNAME"\n"
ip -o addr | awk '/inet /{print "  IP (" $2 "):\t" $4}'
/sbin/route -n | awk '/^0.0.0.0/{ printf "  Gateway:\t"$2"\n" }'
cat /etc/resolv.conf | awk '/^nameserver/{ printf "  Name Server:\t" $2 "\n"}'
echo "------------------------------------------"
echo "Cpanel Details -"
echo "Cpanel Version: `/usr/local/cpanel/cpanel -V`"
echo "Domains/Subdomains: `cat /etc/userdomains | awk '{print $1}' | wc -l`"
echo ""
echo "------------------------------------------"
echo "Apache Details -"
echo "Apache Version: `httpd -v |awk '{ print $3 }' |head -1`"
echo ""
echo "------------------------------------------"
echo "Mysql Details -"
echo "Mysql Version: `mysql -V |awk '{ print $5 }'`"
echo ""
echo "------------------------------------------"
echo "PHP Details -"
echo "PHP Version: `php -v |grep "(built:" |awk '{ print $2 }'`"
echo "PHP Handler: `/usr/local/cpanel/bin/rebuild_phpconf --current |grep "PHP5 SAPI:" |awk
echo "memory_limit: `php -i |grep memory_limit |awk '{ print $5 }'`"
echo "upload_max_filesize: `php -i |grep upload_max_filesize |awk '{ print $5 }'`"
echo ""
echo "------------------------------------------"
echo "Perl Details -"
echo "Perl Version: `perl -v |grep "This is perl," |awk '{ print $4 }'`"
echo ""
echo "------------------------------------------"
echo "Python Details -"
echo "`python -V`"


