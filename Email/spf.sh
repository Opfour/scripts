#!/bin/bash
cd /var/named
localdomains=$(cat /etc/localdomains | grep '^[^.]*\.[^.]*$' | uniq -u)
for i in $localdomains
do
domain=$i
DNS_IP=$(host -t A `hostname` | awk '{print $4}')
echo "$domain. IN TXT \"v=spf1 a:$HOSTNAME mx ip4:"$DNS_IP" ~all\"" >> $i.db
done
wget http://layer3.liquidweb.com/updateserial.pl -O /var/named/updateserial.pl
cd /var/named
perl /var/named/updateserial.pl .
