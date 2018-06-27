#!/bin/bash
for i in `ls /var/cpanel/users` ;do /usr/local/cpanel/bin/domain_keys_installer $i ;done
cd /var/named
localdomains=$(cat /etc/localdomains | grep '^[^.]*\.[^.]*$' | uniq -u)
for i in $localdomains
do
echo "_domainkey IN TXT "t=y; o=~; n=Interim Sending Domain Policy; r=root@$HOSTNAME"" >> $i.db
done

wget http://layer3.liquidweb.com/updateserial.pl -O /var/named/updateserial.pl
cd /var/named
perl /var/named/updateserial.pl .
