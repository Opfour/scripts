#!/bin/bash
FILE=loadwatch.`date +%F.%H.%M`.txt
DIR=/root/loadwatch
#Load Threshold for doing a dump.
LOADTHRESH=12
SQLTHRESH=25
MEMTHRESH=80
SWAPTHRESH=10
APACHETHRESH=120

LOAD=`cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}'`

read MEM SWAP <<<$(free|awk '$1 ~ /Mem:/ {printf "%.0f\t", ($3 - $7) / $2 * 100} $1 ~ /Swap:/ {printf "%.0f\t", $3 / $2 * 100}')

CURSQL=`/usr/bin/mysqladmin stat|awk '{print $4}'`

HISTSQL=`/usr/bin/mysql -Bse 'show global status LIKE "Max_used_connections";'|awk '{print $2}'`

APACHECONN=$(/usr/sbin/httpd status|awk '/requests\ currently\ being\ processed,/ {print $1}')


echo `date +%F.%X` - Load: $LOAD Mem: $MEM Swap: $SWAP MySQL conn: $CURSQL Highest MySQL conn: $HISTSQL Current httpd conn: $APACHECONN >> $DIR/checklog

if [ $LOAD -gt $LOADTHRESH ] || [ $MEM -gt $MEMTHRESH ] || [ $SWAP -gt $SWAPTHRESH ] || [ $CURSQL -gt $SQLTHRESH ] || [ $APACHECONN -gt $APACHETHRESH ]
then
	echo Loadwatch tripped, dumping info to $DIR/$FILE >> $DIR/checklog
	echo `date +%F.%H.%M` > $DIR/$FILE
	free -m >> $DIR/$FILE
	uptime >> $DIR/$FILE
	mysqladmin processlist stat >> $DIR/$FILE
	/bin/netstat -nut|awk '$4 ~ /:(80|443)/ {gsub(/:[0-9]*$/, "", $5); print $5, $6}'|sort|uniq -c|sort -n|tail -n50 >> $DIR/$FILE
	top -bcn1 >> $DIR/$FILE
	ps auxf >> $DIR/$FILE
	/sbin/service httpd fullstatus >> $DIR/$FILE 2> /dev/null
fi
