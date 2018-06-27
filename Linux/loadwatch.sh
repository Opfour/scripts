#!/bin/bash
# let's add a version num for easier identification:
# version 0.1.4-aburk (modified by Austin Burk)

# aburk's modifications: process count is now accurate for httpd and php, et cetera;
# Also, we now print a line that has the time in EDT, to save time when local timezone and server timezone differ.

# Let's check to see if the output directory exists and create it if not.
#
#
if [ ! -d /root/loadwatch ]; then
    mkdir -p /root/loadwatch
fi
#

#config
FILE=loadwatch.`date +%F.%H.%M`
DIR=/root/loadwatch
COLUMNS=512
SUBJECT="LoadWatch on $HOSTNAME triggered. Please check it out."
EMAILMESSAGE="/tmp/emailmessage.txt"

#Load Threshold for doing a dump.
THRESH=10

#pull load average, log
LOAD=`cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}'`
echo `date +%F.%X` - Load: $LOAD >> $DIR/checklog

#trip
if [ $LOAD -ge $THRESH ]
then
	#log 
	echo Loadwatch tripped, dumping info to $DIR/$FILE >> $DIR/checklog
	echo `date +%F.%H.%M` > $DIR/$FILE
	echo "LoadWatch on $HOSTNAME triggered. Please Check it out." > $EMAILMESSAGE
	chmod 600 $DIR/$FILE

	#email (optional, set email address to customer and uncomment below lines)
	#EMAIL="customer@exampledomain.com"
	#/bin/mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE

	#summary
	echo -e "\n\nSummary------------------------------------------------------------\n\n" >> $DIR/$FILE
	echo "Current time for $HOSTNAME is $(date)" >> $DIR/$FILE
	echo "Current time (America/Detroit) is $(TZ='America/Detroit' date)" >> $DIR/$FILE
	NUMHTTPD=`ps aux|grep '[h]ttpd'|wc -l`
	echo "Number of HTTPD Processes: $NUMHTTPD" >> $DIR/$FILE
	HTTPDCPU=`ps aux|awk '/[h]ttpd/ {sum+=$3} END {print sum}'`
	echo "HTTPD CPU consumption: $HTTPDCPU %" >> $DIR/$FILE 
	HTTPDMEM=`ps aux|awk '/[h]ttpd/ {sum+=$6} END {print sum}'`
	HTTPDMEMMEG=$((HTTPDMEM/1024))
	echo "HTTPD memory consumption: $HTTPDMEM Kilobytes ($HTTPDMEMMEG Megabytes)" >> $DIR/$FILE
	NUMPROCS=`grep -c processor /proc/cpuinfo`
	echo "Number of CPU Cores: $NUMPROCS" >> $DIR/$FILE
	NUMPHP=`ps aux|grep '[p]hp'|wc -l`
	echo "Number of PHP Processes: $NUMPHP" >> $DIR/$FILE
	PHPCPU=`ps aux|awk '/[p]hp/ {sum+=$3} END {print sum}'`
	echo "PHP CPU consumption: $PHPCPU %" >> $DIR/$FILE
	PHPMEM=`ps aux|awk '/[p]hp/ {sum+=$6} END {print sum}'`
	PHPMEMMEG=$((PHPMEM/1024))
	echo "PHP memory consumption: $PHPMEM Kilobytes ($PHPMEMMEG Megabytes)" >> $DIR/$FILE
	MYSQLCPU=`top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $9'}`
	echo "MYSQL CPU consumption: $MYSQLCPU %" >> $DIR/$FILE
	MYSQLMEM=`top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $6'}`
	echo "MYSQL RAM consumption: $MYSQLMEM" >> $DIR/$FILE
	uptime >> $DIR/$FILE
	free -m >> $DIR/$FILE
	echo " " >> $DIR/$FILE

        echo '######## Top 20 Memory Users Based on Resident Memory Size ########' >> $DIR/$FILE 
        echo " ">> $DIR/$FILE
        ps h -Ao rsz,vsz,cmd | sort -rn | head -20 >> $DIR/$FILE
        echo " ">> $DIR/$FILE
        echo -n "total resident memory usage: ">> $DIR/$FILE
        ps h -Ao rsz,vsz,cmd | sort -rn | awk '{total = total + $1 }END{print total/1000}'>> $DIR/$FILE

        #echo '######## Top 20 Swap Users ########' >> $DIR/$FILE
        #echo " " >> $DIR/$FILE
        #for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -n -r | head -20>> $DIR/$FILE

	echo '######## CPU top 20 ########' >> $DIR/$FILE
        top -bcn1 | head -n 26 >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	echo '######## Mem top 20 ########' >> $DIR/$FILE
        top -bmcn1 | head -n 26 >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	#mysql
	echo -e "\n\nMySQL:------------------------------------------------------------\n\n" >> $DIR/$FILE
	mysqladmin stat >> $DIR/$FILE
	mysqladmin proc >> $DIR/$FILE

	#apache
	echo -e "\n\nApache------------------------------------------------------------\n\n" >> $DIR/$FILE
	if [ -d /var/cpanel ]
	then
	        lynx -dump -width 500 http://127.0.0.1/whm-server-status >> $DIR/$FILE
	else
		/usr/sbin/httpd fullstatus >> $DIR/$FILE
	fi

	#network
	echo -e "\n\nNetwork------------------------------------------------------------\n\n" >> $DIR/$FILE
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head >> $DIR/$FILE
	echo -e "\n\nNetwork 2----------------------------------------------------------\n\n" >> $DIR/$FILE
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -d: -f4 | sort | uniq -c | sort -nr | head >> $DIR/$FILE

	#email
	echo -e "\n\nEmail------------------------------------------------------------\n\n" >> $DIR/$FILE
	#EXIMQUEUE=`exim -bpc`
	#echo "Exim Queue: $EXIMQUEUE " >> $DIR/$FILE 
	/usr/sbin/exiwhat >> $DIR/$FILE

	#process list
	echo -e "\n\nProcesses------------------------------------------------------------\n\n" >> $DIR/$FILE
	ps auxf >> $DIR/$FILE
fi
