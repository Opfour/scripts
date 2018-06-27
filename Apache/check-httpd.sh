#!/bin/bash
FILE=apache-snapshot.txt
DIR=/root

#set this and then uncomment the mail command below line 30
MAILTO=drsinger1111@gmail.com

SUBJECT="APACHE_DOWN-host.mylwinfo.com"

LOAD=`cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}'`

#init file
echo "Date and Load" >  $DIR/$FILE
echo `date +%F.%X` - Load: $LOAD >>  $DIR/$FILE

echo "APACHE STATUS:" >> $DIR/$FILE
#capture apache status:
lynx -connect_timeout=20 -dump -width 500 http://127.0.0.1/server-status 2>&1 >> $DIR/$FILE
statusexit=$?

echo "" >> $DIR/$FILE
echo "Apache Status check return code (non-zero indicates error):" $statusexit >> $DIR/$FILE 

#bare line, log entries:
echo "" >> $DIR/$FILE
echo "Last 30 lines of apache error log:"  >> $DIR/$FILE
tail -n 30 /usr/local/apache/logs/error_log >> $DIR/$FILE


#if status check did not exit normally, mail file.
if [ $statusexit -ne 0 ]
then
  i=1
  mail -s $SUBJECT $MAILTO < $DIR/$FILE 
fi

