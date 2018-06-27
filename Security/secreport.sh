#!/bin/bash
# LW Security Check Report
# Erin Ammons 2009-07-20
# v1 - very clunky and clumsy.
# next version will have include/exclude options.

#variables
LOG_FILE=/root/secreport.txt
CLAMLOG=/root/clamscan.log
EMAIL=erin@liquidweb.com
DATE=`date +%a-%F`

# rotate/setup logs
mv $LOG_FILE $LOG_FILE.1
mv $CLAMLOG $CLAMLOG.1
touch $LOG_FILE

# report header
echo Security Check Log for $HOSTNAME on $DATE >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

# download and run jlewis' lqchecks
cd /tmp
rm -f lqchecks
wget jlewis.liquidweb.com/lwscripts/lqchecks
echo System Info >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE
perl lqchecks >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

# shellcheck
echo Shell Check >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE
find /home/*/public_html -type f -print0 | xargs -0 egrep '(\/tmp\/cmdtemp|SnIpEr_SA|Bhlynx|x2300|c99shell|r57shell|milw0rm|g00nshell|locus7|MyShell|PHP\ Shell|phpshell|PHPShell|PHPKonsole|Haxplorer|phpRemoteView|w4ck1ng|PHP-Proxy|Locus7s|ccteam|nstview|N3tshell)' | cut -d ':' -f1 | sort | uniq >> $LOG_FILE
echo  >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

# base64 check
echo Base64 check >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE
find /home/*/public_html -type f -print0 | xargs -0 egrep 'eval\(base64_decode\(' | cut -d ':' -f1 | sort | uniq >> $LOG_FILE
echo  >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

# darkmailer check
echo Darkmailer check >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE
find /home/*/public_html -type f -print0 | xargs -0 egrep 'YellSOFT' | cut -d ':' -f1 | sort | uniq >> $LOG_FILE
echo  >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

# clamscan
clamscan -i -r --log=$CLAMLOG /home/*/public_html
echo Clamscan >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE
cat /root/clamscan.log >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

# spam script check
echo Spam script check >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE
grep cwd=\/home /var/log/exim_mainlog| cut -d' ' -f4 | sort | uniq -c | sort -n >> $LOG_FILE
echo -------------------------------- >> $LOG_FILE
echo  >> $LOG_FILE

mail -s "Security Report for $HOSTNAME on $DATE" < $LOG_FILE $EMAIL

