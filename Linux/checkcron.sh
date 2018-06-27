#!/bin/bash
a=$(cat /etc/passwd | cut -d: -f1)
for i in $a
do
echo -e "\E[31m<<--------------------------->>"
echo -e "\E[34m\033[1m"$i"'s cron entries\033[0m"
tput sgr0
echo ""
crontab -u $i -l
echo -e "\E[31m<<--------------------------->>"
echo ""
tput sgr0
done

-b

