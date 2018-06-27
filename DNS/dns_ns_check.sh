#!/bin/bash
# conofrio v0.1.0 GPL
#script that shows the domains that the name servers need to be updated on due to failing dns looksups: i.e when named is getting hammered because a customer has a ton of domains still pointing to their server for dns record - this will show you which ones in a nice list - https://liquidweb.zendesk.com/agent/#/tickets/149529


for i in $(grep denied  /var/log/messages |grep named |awk '{print $10}'|cut -d/ -f1| cut -d"'" -f2| awk -F. '{print $(NF-1)"."$(NF)}'  |sort |tr [A-Z] [a-z]| uniq -c |sort -rn | head -n20 |awk '{print $2}'); do whois $i |egrep 'Domain Name:|Name Server:'| sed 's/Name Server://g'|tr [A-Z] [a-z] |egrep '[a-z]'  ; done
