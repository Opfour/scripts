#!/bin/bash

unalias cp

echo "Archiving Logs..."

cp -f /home/apache/domlogs/* /home/apache/old_logs/

echo "Clearing Log Files..."

FILES=`find /home/apache/domlogs/ -type f|grep -v ftp. |grep -v bytes`

for i in $FILES 
	do cat /dev/null > $i
done

echo "Done!"
