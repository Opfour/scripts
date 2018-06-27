#!/bin/bash
# A Simple (Poor Man) disk based backup script
# Will backup all user home directories in seperate archives
# as a single /home backup file can be quite large and unwieldly.
# Does not need to be modified if users are added/deleted

# Step - 1 Create Timestamp and set up variables and functions
# BUDTSTAMP = Backup Date/Time Stamp
BUTDSTAMP=$(date +%Y%m%d)

# variable holding directories containing files to backup eg: BACKUPTHESE="/home /root /etc"
BACKUPTHESE="/home"

#directory containing today's backup
BKUPDIR="/vol/backup/daily"
#directory containing yesterday's backup
YDBKUPDIR="/vol/backup/yesterday"
#directory containing the day before yesterday's backup
DBBKUPDIR="/vol/backup/daybefore"

# log files
LOG="mail.txt"
ERRORLOG="ERROR.txt"

# tag for backup file name
TAG="homebackup"

# function that quits and logs on error
exiterror()
{
# use this function by supplying $LINENO as first arg
echo "Fatal error caused by line ${1} of ${0}" >> $ERRORLOG
mail somebody@somedomain.com -s "Backup Job ERROR" -v < $ERRORLOG
mail somebody@somedomain.com -s "Backup Job Report" -v < $LOG
exit 1
}

# Step - 2 Start Email Message To Be Sent

# Remove mail message from previous backup
# I do this at the beginning of the script instead of the end
# in case the mail does not send for whatever reason or
# I need to debug it

rm $LOG > /dev/null 2>&1
echo "System Backup $BUTDSTAMP" >> $LOG

# The email sends a user friendly note showing the start and
# end time/dates. This is important so you can compare logs
# and see if a backup ran ok.

echo "Backup Began $(date)" >> $LOG

# Step - 3 Rotate Backups
# Simple three backupset rotation, keeps only last three
# Use directory /vol/backup as an example, make sure you change this path
# to fit your local settings. Have three directories in /vol/backup named daily,
# yesterday and daybefore.
# Make sure /vol/backup is on a different disk (preferably a different machine)
# than the files you are backing up

#looks specifically for backup files in case other files are kept in these directories
for bkfile in $DBBKUPDIR/*; do
echo $bkfile | grep $TAG >/dev/null &&
(rm $bkfile || exiterror $LINENO )
done
for bkfile in $YDBKUPDIR/*; do
echo $bkfile | grep $TAG >/dev/null &&
(mv $bkfile $DBBKUPDIR/ || exiterror $LINENO )
done
for bkfile in $BKUPDIR/*; do
echo $bkfile | grep $TAG >/dev/null &&
(mv $bkfile $YDBKUPDIR/ || exiterror $LINENO )
done

# Step - 4 Archive Home Directories
# Creates a seperate tar file for each directory in the directories in $BACKUPTHESE


# change to dir to backup. Check in case cd failed for some reason.
cd $BACKUPTHIS || exiterror $LINENO
#backup all files listed in BACKUPTHESE
for DIRTOBACKUP in $BACKUPTHESE; do
for FOLDERNAME in $DIRTOBACKUP/*
do
# Archives are created in the format someuser-$TAG-datetime.tar.gz
# basename is used here so as not to include absolute paths
# -p preserves permissions
echo -e "-------------------\n>>>taring ${FOLDERNAME}\n\n" >> $LOG
tar -czvpf ${BKUPDIR}/$( basename $FOLDERNAME )-${TAG}-${BUTDSTAMP}.tar.gz ${FOLDERNAME} >> $LOG || exiterror $LINENO
done
done

# Step - 5 Finish Email Report and Send

echo "Backup ended $(date)" >> $LOG

# df -h includes a human readable disk usage report of the media that /vol/backup
# is mounted on. Good to now if your backup disk is running out of space.
# Of course /dev/hdb1 is the device I use, modify it for your local settings

df -h /dev/hdb1 >> $LOG
mail somebody@somedomain.com -s "Backup Job Report" -v < $LOG

# Step - 6 All Done 
