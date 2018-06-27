#!/bin/bash
# 
# written by benjamin cathey (bcathey@liquidweb.com) 20081016
#
# script to be called by cron to send a report if load is too high

# User configurable, highload and email
# cron to setup: */2 * * * * /root/whatnow.sh > /dev/null 2>&1

highload="10"
email="bcathey@liquidweb.com"

##########################################################################
#                     Do Not Modfiy Below please                         #

load=$(uptime | sed -e 's/.*load average: \(.*\...\), \(.*\...\), \(.*\...\)/\1/' -e 's/ //g')
comp=$(echo "scale=2; $load > $highload" | bc)

if [ "$comp" == "1" ]
then
  cpushot=$(ps aux --sort -%cpu | head)
  sitestat=$(/usr/bin/lynx -dump -width 500  http://127.0.0.1/whm-server-status | grep GET | awk '{print $12}' | sort | uniq -c | sort -rn | head)
  portstat=$(netstat -an |grep :80| awk '{print $5}' | sed 's/::ffff://'| cut -d':' -f1 | sort | uniq -c |sort -nr |head)
  sqlprocs=$(mysqladmin proc stat)
  sqlcount=$(mysqladmin processlist | sed -n '3,$p' | sed '/^+.*$/d' | awk '/^\|/' | awk '{print $8}' | awk '!/\|/' | sort | uniq -c | sort -nr)
  sarstat=$(printf "                  CPU     %%user     %%nice   %%system   %%iowait     %%idle\n"; sar | tail)

  body=$(printf "Usage statistics for `hostname` on `date`\n"; echo; echo; printf "TOP output\n"; echo; echo -e "$cpushot"; echo; echo; printf "SITE Stats\n"; echo; echo -e "$sitestat"; echo; echo; printf "PORT 80 Stats\n"; echo; echo -e "$portstat"; echo; echo; printf "MySQL PROC Stats\n"; echo; echo -e "$sqlprocs"; echo; echo; printf "MySQL table usage count\n"; echo; echo -e "$sqlcount"; echo; echo; printf "SAR Stats\n"; echo; echo -e "$sarstat")

  echo -e "$body"| mail -s "Load is $load on `hostname`" $email
fi


