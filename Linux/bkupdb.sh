#!/bin/bash
HOME=/root
if [ -f /etc/bashrc ]; then
       . /etc/bashrc
fi

BACKUPLOC="/home/dbbackups"
mkdir -p $BACKUPLOC

for db in `mysql -s -B -e "show databases"`; do nice -n 18 mysqldump --opt $db
> $BACKUPLOC/$db.`date +%Y%m%d-%H%M%S`.sql; done nice -n 18 bzip2 -9
$BACKUPLOC/*.sql chown root:root $BACKUPLOC/* chmod 600 $BACKUPLOC/*

# find $BACKUPLOC -mtime +7 | xargs rm -f

