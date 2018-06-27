#!/bin/sh

#Destination directory.  Where to put the backups. 
DESTINATION=/mnt/server/backups/
#Source directories.  What you want to backup. 
SOURCE="/etc /home /root /var"
#Put todays date in a variable. Will be used in the filename. 
DATE=`date +%F`
#Hostname of the server.  Will be used in the filename.
HOSTNAME=`echo $HOSTNAME`
#Location of tar. Set manually if below doesn't work. 
TAR=`type -p tar`
#Location of find. Set manually if below doesn't work. 
FIND=`type -p find`
#Location of xargs. Set manually if below doesn't work. 
XARGS=`type -p xargs`
#Location of rm. Set manually if below doesn't work. 
RM=`type -p rm`
#Remove ALL FILES in the destination directory that are over a week old. Change
# "7" to keep more/fewer backups. 
$FIND $DESTINATION -type f -atime +7 -print | $XARGS $RM
#Backup the files keeping acls and extended attributes.  
$TAR --create --gzip --verbose --acls --xattrs --preserve-permissions --file=$DESTINATION/$HOSTNAME-$DATE.tar.gz $SOURCE
