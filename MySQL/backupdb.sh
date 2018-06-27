#!/bin/bash
#ssullivan.org/scripts
#ssullivan@liquidweb.com
uid=`id -u`
root_uid=0
E_NOTROOT=87
datadumpdir='/home/dumps/'
date=$(/bin/date +%H:%MHoursOn:%m-%d-%Y)
datadir=`/usr/bin/mysql -e "show variables like 'datadir'" | grep / | cut -f 2`

if [ "$uid" -ne "$root_uid" ]
  then
        echo "Must be root to run this script."
        exit $E_NOTROOT
  else
        echo ""
        echo "------------------------------------------------"
        echo "--The MySQL data directory is $datadir"
        echo "--MySQL dumps will be placed in $datadumpdir"
        echo "------------------------------------------------"
        echo ""
        echo -n "Backup all MySQL databases to $datadumpdir now (y/n)?"
        read choice
                if [ "$choice" == "y" ]; then
                        #Create the database dump files
                        mkdir -p $datadumpdir$date
                        echo ""
                        echo "Creating database dump files.."
                        echo ""

                        for i in `mysql -e "show databases;" | sed 's/Database$//'`; do
                                mysqldump --opt $i > $datadumpdir$date/$i.sql;
                                echo "Created: $i.sql"
                        done
                        echo ""
                        echo "Backups created in $datadumpdir$date"
                        echo ""
                else
                        echo "Bailing out..."
                        exit
                fi
fi

