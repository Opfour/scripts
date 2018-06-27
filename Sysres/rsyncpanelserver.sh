#!/bin/sh
#
# HOST = User + IP / Hostname to copy files TO.
HOST="root@PUTDESTINATIONIP"

echo Creating key pair...
ssh-keygen -t dsa 
echo Create .ssh directory on destination server...
ssh $HOST 'mkdir /root/.ssh'
scp /root/.ssh/id_dsa.pub $HOST:~/.ssh/authorized_keys

# /etc User / IP's + passwd files
echo Transferring /etc
rsync -aqHl -e ssh /etc/passwd $HOST:/root/
rsync -aqHl -e ssh /etc/shadow $HOST:/root/
rsync -aqHl -e ssh /etc/group $HOST:/root/
rsync -aqHl -e ssh /etc/wwwacct.conf $HOST:/etc/
rsync -aqHl -e ssh /etc/quota.conf $HOST:/etc/
rsync -aqHl -e ssh /etc/domainalias $HOST:/etc/
rsync -aqHl -e ssh /etc/remotedomains $HOST:/etc/
rsync -aqHl -e ssh /etc/localdomains $HOST:/etc/
rsync -aqHl -e ssh /etc/userdomains $HOST:/etc/
rsync -aqHl -e ssh /etc/valiases $HOST:/etc/
rsync -aqHl -e ssh /etc/vfilters $HOST:/etc/
rsync -aqHl -e ssh /etc/vmail $HOST:/etc/
rsync -aqHl -e ssh /etc/trueuserdomains $HOST:/etc/
rsync -aqHl -e ssh /etc/trueuserowners $HOST:/etc/
rsync -aqHl -e ssh /etc/ips $HOST:/etc/
rsync -aqHl -e ssh /etc/ipaddresspool $HOST:/etc/
rsync -aqHl -e ssh /etc/services $HOST:/etc/

# ftpd files
echo Transferring FTP configs
rsync -aqHl -e ssh /etc/sysconfig/pure-ftpd $HOST:/etc/sysconfig/
rsync -aqHl -e ssh /etc/pure-ftpd.conf $HOST:/etc/
rsync -aqHl -e ssh /etc/pure-ftpd $HOST:/etc/
rsync -aqHl -e ssh /etc/proftpd $HOST:/etc/
rsync -aqHl -e ssh /etc/proftpd.* $HOST:/etc/
# /var
echo Transferring /var
rsync -aqHl -e ssh /var/cpanel $HOST:/var/
rsync -aqHl -e ssh /var/spool/cron $HOST:/var/spool/

# /usr config - 3rdparty
echo Transferring 3rd party and SSL certs
rsync -aqHl -e ssh /usr/share/ssl $HOST:/usr/share/
rsync -aqHl -e ssh/usr/local/cpanel/3rdparty/mailman $HOST:/usr/local/cpanel/3rdparty/
rsync -aqHl -e ssh /usr/local/cpanel/base/frontend $HOST/usr/local/cpanel/base/

# Apache
echo Transferring Apache configs
rsync -aqHl -e ssh /usr/local/apache/conf $HOST:/usr/local/apache/
rsync -aqHl -e ssh /usr/local/apache/libexec $HOST:/usr/local/apache/
rsync -aqHl -e ssh /usr/local/frontpage $HOST:/usr/local/

# Mysql config
echo Transferring MySQL configs
rsync -aqHl -e ssh /root/.my.cnf $HOST:/root/
rsync -aqHl -e ssh /etc/my.cnf $HOST:/etc/

# Named
echo Transferring zone files and bind configs
rsync -aqHl -e ssh /var/named $HOST:/var/
rsync -aqHl -e ssh /etc/named.conf $HOST:/etc/
rsync -aqHl -e ssh /etc/rndc.conf $HOST:/etc/

#User Files
# Mysql
echo Transferring MySQL databases
rsync -aqHl -e ssh /var/lib/mysql $HOST:/var/lib/

# Home
echo Tansferring /home
rsync -aqHl -e ssh /home/* $HOST:/home/

# system swap ips between servers 
echo Transferring network configs
#rsync -aqHl -e ssh /etc/sysconfig/network-scripts/ifcfg-eth0 $HOST:/etc/sysconfig/network-scripts/ifcfg-eth0
