#What this bash script does ?
#It monitors memory usage with cron set, and when it exceeds the value set by you, it runs the commands you prefer and also notifies you by email.

#Now lets move on to get on with it (for beginners in shell)
#Go on with the following commands as it is
# touch /root/memon
# chmod 0755 /root/memon
# vim /root/memon


EMAIL="root" # EMAIL ID TO WHICH EMAIL SHOULD BE SENT
SUBJECT="Memory Alert" # SUBJECT OF EMAIL SENT
FILE="/root/tmpmu" # TEMP FILE TO WHICH EMAIL DATA IS WRITTEN
TRIGGER=205 # TRIGGER VALUE AT WHICH CMD's SHOULD BE EXECUTED
BURST=1024 # BURST RAM ALLOTTED
GUD=256 # GURANTEED RAM

#---------------------------DONOT CHANGE ANYTHING BELOW THIS -----------------------------
MF="$(grep MemF /proc/meminfo | awk '{print $2}')"
MemFree="$(( ${MF} / 1024 ))"
MT="$(grep MemT /proc/meminfo | awk '{print $2}')"
MemTotal="$(( ${MT} / 1024 ))"
MU="$(( ${MT} - ${MF} ))"
MemUsed="$(( ${MU} /1024 ))"
BRU=0
BRTT="$(( ${BURST} - ${GUD} ))"
if [ $MemUsed -gt $GUD ]; then
BRU="$(( ${MemUsed} - ${GUD} ))"
fi

echo "Hostname: $(hostname)" > $FILE
echo "Local Date & Time : $(date)" >> $FILE
echo "" >> $FILE

echo Memory Usage(Used/Guaranteed RAM): $MemUsed/$GUD >> $FILE
echo Burst Usage: $BRU/$BRTT >> $FILE
echo "" >> $FILE

if [ $MemUsed -gt $TRIGGER ]; then
#--------SET THE BELOW COMMANDS INSIDE THE BRACKETS WHICH YOU WANT TO RUN ON TRIGGER-------
 echo "$(/etc/rc.d/init.d/exim restart)" >> $FILE
 echo "$(/etc/rc.d/init.d/mysql restart)" >> $FILE
 #echo "$(abc3)" >> $FILE

 /bin/mail -s "$SUBJECT" "$EMAIL" < $FILE
fi
echo > $FILE
