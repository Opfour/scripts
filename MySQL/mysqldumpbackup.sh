#Backup multiple MySQL databases into separate files and one full backup of all of them and then tars them in to archive directory and 
#retains 7 day archives
#!/bin/bash
# backup each mysql db into a different file, rather than one big file
# as with --all-databases - will make restores easier

USER="root"
PASSWORD="password"
OUTPUTDIR="mysqldumpoutput"
MYSQLDUMP="/usr/bin/mysqldump"
MYSQL="/usr/bin/mysql"
purgedir="mysqldumptars"
now=`date '+%Y-%m-%d-%H-%M-%S'`

# clean up any old backups - save space
/bin/rm "OUTPUTDIR/*bak" > /dev/null 2>&1

# does a all database mysql dump backup 
$MYSQLDUMP --single-transaction --force --opt --user=$USER --password=$PASSWORD --all-databases > "$OUTPUTDIR/alldbdump.bak"

# get a list of databases
databases=`$MYSQL --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

# dump each database in turn
for db in $databases; do
    echo $db
    $MYSQLDUMP --single-transaction --force --opt --user=$USER --password=$PASSWORD --databases $db > "$OUTPUTDIR/$db.bak"
    done

#Backup section
#===================

#this make a tar of the new separate dumpfiles with a time stamp and moves the tar to separate directory upon completion
cd mysqldumpoutput/
/bin/tar -zcvf mysqldump.tar ./*
/bin/mv mysqldumpoutput/mysqldump.tar /mysqldumptars/mysqldump_${now}.tar

#This deletes any tar that is more than 7 days old for the dump backups
/usr/bin/find ${purgedir} -maxdepth 1 -name "mysqldump_*" -mtime +6 -exec rm -rf {} \; -ls

