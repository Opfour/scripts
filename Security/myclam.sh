#!/bin/bash
nice -n 5 clamscan -ri /home/ > /home/temp/clamscan.output
clammd5=`md5sum /home/temp/clamscan.output`
oldmd5=`cat /home/temp/clamscan.md5save`

if [[ `echo $clammd5` != `echo $oldmd5` ]]; then
  cat /home/temp/clamscan.output | mail -s "ClamScan Notification" wwong@wmmediacorp.com
  echo $clammd5 > /home/temp/clamscan.md5save
fi

exit 0

