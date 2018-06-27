#!/bin/bash
#Infoad
#Authors: Frankie Sanzica & Nick DiLernia
#Version 0.1.0
###Colors
black='\e[0;30m'
dgray='\e[1;30m'
lgray='\e[0;37m'
blue='\e[0;34m'
lblue='\e[1;34m'
green='\e[0;32m'
lgreen='\e[1;32m'
cyan='\e[0;36m'
lcyan='\e[1;36m'
red='\e[0;31m'
lred='\e[1;31m'
purple='\e[0;35m'
lpurple='\e[1;35m'
brown='\e[0;33m'
yellow='\e[1;33m'
white='\e[1;37m'
nocolor='\e[0m'
###Variables
HOST=`hostname`;
HTTPD='/usr/local/apache/conf/httpd.conf'
PHP=`php -i|grep php.ini|grep "Configuration"|cut -d ">" -f2|cut -c 2-|tail -n 1`
MYSQL='/etc/my.cnf'
POST=`grep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/*|grep POST|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n1 | awk '{print $2}'| cut -d '/' -f4`
GET=`grep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/*|grep GET|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n1 | awk '{print $2}'| cut -d '/' -f4`
TTY=$(ps ax | grep $$ | awk '{ print $2 }'|head -1)
IP=`who|grep "$TTY"|awk '{print $NF}'|tr -d '(|)'`
PWD=`pwd`
DATE=`date +%F.%H.%M`

###Redirect stdout to logfile
if (whiptail --title "Infoad" --yesno "Save Infoad log to a file?" 8 78) then
exec > >(tee infoad.`date +%F.%H.%M`)
echo -e $yellow"\nYour log file will be saved here:$nocolor"
echo -e "$blue$PWD/infoad.$DATE$nocolor"
else
echo ""
fi
###About
echo -e "\n$lblue===$nocolor$green Infoad (CentOS/cPanel)$nocolor by "$yellow"fsanzica & ndilernia $nocolor$lblue===$nolcolor\n"
###Dubya
echo -e "\n$lblue===$nocolor$green Dubya$nocolor $lblue===$nocolor\n"
w
###Versions
echo -e "\n$lblue===$nocolor$green Version Info$nocolor $lblue===$nocolor\n"
###OS
echo -e $blue"OS Version: $nocolor"
cat /etc/redhat-release
###Kernel
echo -e $blue"Kernel Version: $nocolor"
uname -r
###cPanel
echo -e $blue"cPanel Version: $nocolor"
/usr/local/cpanel/cpanel -V
###Apache
echo -e $blue"Apache Version: $nocolor"
/usr/local/apache/bin/httpd -v|grep nix|awk '{print $3,$4}'
###PHP
echo -e $blue"PHP Version: $nocolor"
/usr/local/bin/php -v|grep cli
###MySQL
echo -e $blue"MySQL Version: $nocolor"
/usr/bin/mysql -V|cut -d "," -f1|awk '{print $2,$3,$4,$5}'
###Processors
echo -e "\n$lblue===$nocolor$green Number of Processors$nocolor $lblue===$nocolor\n"
grep -c proc /proc/cpuinfo
###Hourly CPU/IO Wait
echo -e "\n$lblue===$nocolor$green Hourly CPU Usage / IO Wait$nocolor $lblue===$nocolor\n"
sar|grep ':00'|grep -v "Linux"|grep -v 'Average'|awk '{print $1,$2,$4,$7}'
###Current Mem
echo -e "\n$lblue===$nocolor$green Current Memory Usage$nocolor $lblue===$nocolor\n"
free -m
###Hourly Swap
echo -e "\n$lblue===$nocolor$green Hourly Swap Usage$nocolor $lblue===$nocolor\n"
sar -S 2> /dev/null|grep ':00'|grep -v "Linux"|grep -v 'Average'|awk '{print $1,$2,$5}'
###Mem by User
#echo -e "\n$lblue===$nocolor$green Most Memory by Users$nocolor $lblue===$nocolor\n"
#lwtmpvar=;for each in `ps aux | grep -v COMMAND | awk '{print $1}' | sort | uniq`; do lwtmpvar="$lwtmpvar\n`ps aux | egrep ^$each | awk 'BEGIN{total=0};{total += $4};END{print total, $1}'`"; done; echo -e $lwtmpvar | grep -v ^$ | sort -rn | head
###Disk Usage
echo -e "\n$lblue===$nocolor$green Disk Space Usage$nocolor $lblue===$nocolor\n"
df -h
###Inode Usage
echo -e "\n$lblue===$nocolor$green Inode Usage$nocolor $lblue===$nocolor\n"
df -hi
###Mail Queue
echo -e "\n$lblue===$nocolor$green Current Mail in Queue$nocolor $lblue===$nocolor\n"
exim -bpc
###Queue Summary
#echo -e "\n$lblue===$nocolor$green Mail Queue Summary$nocolor $lblue===$nocolor\n"
#exim -bp|exiqsumm|sort -n -k 1|grep -v '-'|tail|awk 'NR > 3 { print }'
###HTTP Config
echo -e "\n$lblue===$nocolor$green Apache Configuation$nocolor $lblue===$nocolor\n"
/etc/init.d/httpd -V | grep --color=never MPM; grep --color=never "KeepAlive " $HTTPD; egrep 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $HTTPD; INCLUDES=$(egrep 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' /usr/local/apache/conf/includes/pre_virtualhost_global.conf); if [[ $? == 0  ]] ; then echo -e "\n/usr/local/apache/conf/includes/pre_virtualhost_global.conf:\n\n$INCLUDES\n"; fi
###Recommended Max Clients
echo ""
exec 3<&1 && bash <&3 <(curl -sq https://raw.githubusercontent.com/Frankie-Sanzica/Sug-max-cli/master/sugg-max-cli.sh)
###HTTP Uptime
echo -e "\n$lblue===$nocolor$green Apache Uptime$nocolor $lblue===$nocolor\n"
service httpd status|egrep 'Restart|uptime'
###Number of HTTP Procs
echo -e "\n$lblue===$nocolor$green Number of Apache Processes$nocolor $lblue===$nocolor\n"
ps faux|grep httpd -c|grep -v grep
###Number of IPS
echo -e "\n$lblue===$nocolor$green Number of IPs Connected$nocolor $lblue===$nocolor\n"
netstat -tn 2>/dev/null|grep :80|awk '{print $5}'|cut -f1 -d:| sort|uniq -c|sort -rn|wc -l
###Port 80 Connects
echo -e "\n$lblue===$nocolor$green Port 80 Connections$nocolor $lblue===$nocolor\n"
netstat -tn 2>/dev/null|grep :80|wc -l
###Top 10 Connects to HTTP
echo -e "\n$lblue===$nocolor$green Top 10 Connections to Apache$nocolor $lblue===$nocolor\n"
netstat -tn 2>/dev/null|grep :80|awk '{print $5}'|cut -f1 -d:|sort|uniq -c|sort -rn|head
###Number of SYN Connects
echo -e "\n$lblue===$nocolor$green Number of SYN connections$nocolor $lblue===$nocolor\n"
netstat -nap|grep SYN|wc -l
###Top 10 SYN Connects
echo -e "\n$lblue===$nocolor$green Top 10 SYN Flood Conections$nocolor $lblue===$nocolor\n"
netstat -tn 2>/dev/null|grep SYN|awk '{print $5}'|cut -f1 -d:|sort|uniq -c|sort -rn|head
###Max Clients
echo -e "\n$lblue===$nocolor$green MaxClients Hits$nocolor $lblue===$nocolor\n"
grep MaxClients /usr/local/apache/logs/error_log|tail
###Graceful Restarts
echo -e "\n$lblue===$nocolor$green Graceful Restarts$nocolor $lblue===$nocolor\n"
grep Graceful /usr/local/apache/logs/error_log |tail
###Most POST
echo -e "\n$lblue===$nocolor$green Domains With Most POST Requests (Today)$nocolor $lblue===$nocolor\n"
LC_ALL=C fgrep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/*|LC_ALL=c fgrep POST|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n5
###POST Folders/Files
echo -e "\n$lblue===$nocolor$green ${POST}'s Most (POST) Requested Folders/Files$nocolor $lblue===$nocolor\n"
grep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/${POST}|grep POST|awk '{print $7}'|sort |uniq -c|sort -n|tail -n5
###POST IPs
echo -e "\n$lblue===$nocolor$green ${POST}'s Top (POST) IP Connections$nocolor $lblue===$nocolor\n"
grep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/${POST}|grep POST|awk '{print $1}'|sort |uniq -c|sort -n|tail -n5
###Most GET
echo -e "\n$lblue===$nocolor$green Domains With Most GET Requests (Today)$nocolor $lblue===$nocolor\n"
LC_ALL=C fgrep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/*|LC_ALL=C fgrep GET|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n5
###GET Folders/Files
echo -e "\n$lblue===$nocolor$green ${GET}'s Most (GET) Requested Folders/Files$nocolor $lblue===$nocolor\n"
grep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/${GET}|grep GET|awk '{print $7}'|sort |uniq -c|sort -n|tail -n5
###GET IPs
echo -e "\n$lblue===$nocolor$green ${GET}'s Top (GET) IP Connections$nocolor $lblue===$nocolor\n"
grep 2> /dev/null "$(date +"%d/%b/%Y")" /home/domlogs/${GET}|grep GET|awk '{print $1}'|sort |uniq -c|sort -n|tail -n5
###Brute Force
echo -e "\n$lblue===$nocolor$green WordPress Brute Force Attempts (Today)$nocolor $lblue===$nocolor\n"
grep -s 2> /dev/null wp-login.php /usr/local/apache/domlogs/*|grep POST|grep "$(date +"%d/%b/%Y")"|cut -d: -f1|sort|uniq -c|sort -nr|head
###Robots
echo -e "\n$lblue===$nocolor$green Robot Crawls (Today)$nocolor $lblue===$nocolor\n"
find 2> /dev/null /usr/local/apache/domlogs/*/ -type f|grep -v -E $'(_|-)log|.gz'|xargs -i tail -5000 {}|grep $(date +%d/%b/%Y) |grep -i -E "crawl|bot|spider|yahoo|bing|google"|awk '{print $1}'|sort |uniq -c |sort -rn|head
###ModSec
echo -e "\n$lblue===$nocolor$green Top 10 Mod Sec Trips$nocolor $lblue===$nocolor\n"
tail -10000 /usr/local/apache/logs/error_log|LC_ALL=C fgrep ModSecurity| sed -e 's#^.*\[id "\([0-9]*\).*hostname "\([a-z0-9\-\_\.]*\)"\].*uri "#\1 \2 #' | cut -d\" -f1 | sort -n | uniq -c | sort -n | tail
###Apache Errors Your IP Triggered
echo -e "\n$lblue===$nocolor$green Apache Errors Your IP Triggered$nocolor $lblue===$nocolor\n"
tail -1000 /usr/local/apache/logs/error_log | grep "$IP"|tail
###PHP Info
echo -e "\n$lblue===$nocolor$green PHP Info$nocolor $lblue===$nocolor\n"
grep "memory_limit" $PHP;grep "max_execution_time" $PHP;grep "max_input_time" $PHP;grep "post_max_size" $PHP;grep "upload_max_filesize" $PHP;grep "max_file_uploads" $PHP
###PHP Processes
echo -e "\n$lblue===$nocolor$green PHP Handler$nocolor $lblue===$nocolor\n"
/usr/local/cpanel/bin/rebuild_phpconf --current;echo -e "\n$lblue===$nocolor$green Number of PHP Processes$nocolor $lblue===$nocolor\n";ps faux|grep php -c|grep -v grep
###MySQL Config
echo -e "\n$lblue===$nocolor$green MySQL Configuration$nocolor $lblue===$nocolor\n"
egrep 'max_connections|max_heap_table_size|tmp_table_size|query_cache_size|timeout|table_cache|open_files|thread|innodb' $MYSQL
###MySQL Opts
echo -e "\n$lblue===$nocolor$green MySQL Optimizations$nocolor $lblue===$nocolor\n"
bash <(curl -s https://raw.githubusercontent.com/Frankie-Sanzica/Not-My-Scripts/master/mysqltune.sh) | egrep 'Recommended|MyISAM|InnoDB|Upgrading|Current'
###Number of MySQL Connects
echo -e "\n$lblue===$nocolor$green Number of MySQL Connections$nocolor $lblue===$nocolor\n"
netstat -nap|grep -i sql.sock|wc -l
###MySQL Connects
echo -e "\n$lblue===$nocolor$green MySQL Connections$nocolor $lblue===$nocolor\n"
mysql -e 'show status;'|grep connect
###MySQL Queries
echo -e "\n$lblue===$nocolor$green MySQL Database queries$nocolor $lblue===$nocolor\n"
mysqladmin proc stat
###MySQL DBs
echo -e "\n$lblue===$nocolor$green MySQL Databases$nocolor $lblue===$nocolor\n"
du --max-depth=1 /var/lib/mysql|sort -nr|cut -f2|xargs du -sh 2>/dev/null|head|cut -d "/" -f1,5
###MySQL Table Types & Sizes
#echo -e "\n$lblue===$nocolor$green MySQL Table Types & Sizes$nocolor $lblue===$nocolor\n"
#mysql -e "show engines;" | grep DEFAULT | awk '{print $2" MYSQL ENGINE = "$1}'; mysql -e "SELECT engine, count(*) tables, concat(round(sum(table_rows)/1000000,2),'M') rows, concat(round(sum(data_length)/(1024*1024*1024),2),'G') data, concat(round(sum(index_length)/(1024*1024*1024),2),'G') idx, concat(round(sum(data_length+index_length)/(1024*1024*1024),2),'G') total_size, round(sum(index_length)/sum(data_length),2) idxfrac FROM information_schema.TABLES GROUP BY engine ORDER BY sum(data_length+index_length) DESC LIMIT 10;";
###MySQL Errors
echo -e "\n$lblue===$nocolor$green MySQL Errors$nocolor $lblue===$nocolor\n"
cat /var/lib/mysql/${HOST}.err|tail
###Backup Crons
echo -e "\n$lblue===$nocolor$green Backup Crons$nocolor $lblue===$nocolor\n"
crontab -l|grep backup
###Backups Last Ran
echo -e "\n$lblue===$nocolor$green When Backups Last Ran$nocolor $lblue===$nocolor\n"
ls -la /usr/local/cpanel/logs/cpbackup|grep -vi 'dr'|awk '{print $6,$7,$8}'| awk 'NR > 1 { print }'
###Are Backups Running Now
echo -e "\n$lblue===$nocolor$green Are Backups Running Now? (If Blank, No)$nocolor $lblue===$nocolor\n"
ps aux|grep -i backup|grep -i cpanel|grep -v 'grep'
###Last Cpanellogd Log Checks
echo -e "\n$lblue===$nocolor$green Last Cpanellogd Log Checks$nocolor $lblue===$nocolor\n"
cat /usr/local/cpanel/logs/stats_log | grep "Checking Logs" | tail
###Is Cpanellogd Running Now
echo -e "\n$lblue===$nocolor$green Is cpanellogd Running Now? (If Blank, No)$nocolor $lblue===$nocolor\n"
ps faux | grep -i cpanellogd | grep -v "grep"
###Cpanel Settings
echo -e "\n$lblue===$nocolor$green Cpanel Settings$nocolor $lblue===$nocolor\n"
egrep -i 'piped|extracpus|nocpbackuplogs|archived?-log' /var/cpanel/cpanel.config
###Logwatch Logs Today
echo -e "\n$lblue===$nocolor$green LoadWatch Logs (Today)$nocolor $lblue===$nocolor\n"
ls /root/loadwatch 2> /dev/null|grep $(date +%Y-%m-%d)|tail
###Lasest Logwatch Log Loadparsed
echo -e "\n$lblue===$nocolor$green Latest Loadwatch Log Loadparsed$nocolor $lblue===$nocolor\n"
watch=`ls /root/loadwatch 2> /dev/null|grep $(date +%Y-%m-%d)|tail -1`
cd 2> /dev/null /root/loadwatch
exec 3<&1 && bash <&3 <(curl -sq https://raw.githubusercontent.com/Frankie-Sanzica/Not-My-Scripts/master/loadparse.sh) $watch |awk 'NR > 1 { print }'
###Ask to Run Version Finder script
if (whiptail --title "Infoad" --yesno "Run CMS Version Finder Script?" 8 78) then
bash <(curl -sq https://raw.githubusercontent.com/Frankie-Sanzica/CMS-Version-Finder/master/cms-version-finder.sh)
else
echo ""
fi
