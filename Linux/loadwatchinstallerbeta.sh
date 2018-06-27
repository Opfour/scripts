#LoadWatchInstaller
#Checks for and/or installs Loadwatch
#Created By: Mark Benedict
#!/bin/bash

clear
ver=v1.0
echo "LoadWatch Installer $ver"
echo "Mark Benedict"
echo ""
echo "Please report any issues to mbenedict@liquidweb.com"
echo ""
verify=$(crontab -l|grep loadwatch)

if  [ -z "$verify"  ] 
then
echo ""
echo "Installing LoadWatch"
rm -f /root/bin/loadwatch.sh
rm -f lwwgetfile
mkdir /root/bin
mkdir /root/loadwatch
wget http://www.unrealwebsolutions.com/scripts/lwwgetfile
cp lwwgetfile /root/bin/loadwatch.sh
chmod 700 /root/bin/loadwatch.sh
echo "What would you like to set the threshold to?"
echo "Server has `grep -c proc /proc/cpuinfo` CPU/s"
echo ""
read -p "Threshold: " thrshld
thrshld=${thrshld:-60}
sed -i '5 s|THRESH=60''|'"THRESH=$thrshld"'|' /root/bin/loadwatch.sh
echo "Threshold set to $thrshld"
echo "Adding Cron"
echo "*/3 * * * * /root/bin/loadwatch.sh > /dev/null 2>&1" >> /var/spool/cron/root
echo "Install Successful"
sleep 2
echo "Exiting"
	
else

echo "Looks like loadwatch is already installed. Here are the last 10 trip logs and a quick summary"
grep -B1 tripped /root/loadwatch/checklog |tail -10
echo ""
echo "---------------"
echo "Quick Summary--"
echo "---------------"
TIMESTAMP="loadwatch.2012-12-06." && cd /root/loadwatch && echo -e "\nTop database tables:" && egrep "$(ls /home | sed s/\ /\|/g)" ${TIMETAMP}* | awk '{print $4}' | egrep "$(echo ${ACCOUNTS} | sed s/\ /\|/g)" | uniq -c | sort -rn | head -5 && echo -e "\nBusiest accounts/domains:" && egrep "$(echo ${ACCOUNTS} | sed s/\ /\|/g)" ${TIMETAMP}* | awk '{print $2}' | egrep "$(echo ${ACCOUNTS} | sed s/\ /\|/g)" | sort | uniq -c | sort -rn | head -5 && echo -e "\nTop process users:" && egrep "$(echo ${ACCOUNTS} | sed s/\ /\|/g)" ${TIMETAMP}* | awk '{print $1}' | cut -d ':' -f 2 | egrep "$(echo ${ACCOUNTS} | sed s/\ /\|/g)" | sort | uniq -c | sort -rn | head -5
exit
	
fi