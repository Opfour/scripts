#!/bin/bash
##############################################################################
# maldet-per-user
# version 0.22
# 2012-01 by Nick Hope
#
# Written to be able to start/stop/resume maldet scans for all CPanel accounts
# on a server. Most servers that warrant a scan of every user are in no shape
# to actually run such a large scan uninteruppted. This scans each user
# individually, and will skip over any previously scanned users if the scan
# is stopped.
#
# The automatic backup/quarantine functions (especially the quarantine) rely
# on maldet's output format to work correctly. This script will break if
# maldet changes its output format.
#
# CHANGELOG
# 0.22
#    * maldet output changed in 1.4.1 (vs 1.4.0), breaking the method for
#      grabbing maldet session ids from the output of the maldet scan.
#      Updated this to correctly parse the session ID from both version.
#    * Modified a comment as a workaround for report/file list generation
#      accidentally parsing a line in this script and including it in those
#      files when this script is run from the scan results directory
#
# 0.21
#    * fixed a stupid bug in parsing a user's homedir/displaying scan count
#    * workaround for saving scan results properly when run multiple times
#      a day (nuke the previously saved results)
#
# 0.2
#    * --exclude-users command line flag 
#    * --reset command line flag to remove incomplete scan results before
#      scanning again
#
# 0.11
#    * add user count during scan [Benjamin Cathey]
#    * ctrl+c trap to cleanly exit out of the scan loop
#
##############################################################################
# Path variables, modify as necessary, no trailing slashes                   #
##############################################################################
TEMPFILE="/tmp/maldet-per-user-temp"
DEFAULT_WORKDIR="/root/maldet-scan"
BACKUPDIR_BASE="/backup"
##############################################################################
# date format
DATE=`date +%Y-%m-%d`
 
##############################################################################
# Start functions                                                            #
##############################################################################

###
# fn_scan
#
# The main part of this script. Loops through /var/cpanel/users to run
# individual maldet scans on each user's public_html directory.
# 
# The loop will skip over any previously scanned users by checking for a file
# with the name of the CPanel user
#
function fn_scan {
    maldet -u > /dev/null
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
    userlist=$(ls /var/cpanel/users)
    usertotal=$(ls /var/cpanel/users | wc -l | awk '{print $1}')

    for user in $userlist
    do
        count=$(echo "$userlist" | grep -n $user$ | cut -d: -f1) 
        #only scan the user's public_html directory
        #if a scan hasn't already been run
        if [ ! -e $WORKDIR/$user ]
        then
            HOMEDIR=`grep "$user:" /etc/passwd | cut -d: -f6`
            #make sure we grabbed a valid username and homedir to scan
            #primarily this is to skip the "system" cpanel user
            if [ ! -z $HOMEDIR ]
            then
                echo "[$count/$usertotal] Scanning public_html for $user"
                maldet -a $HOMEDIR/public_html > $TEMPFILE
                #Still a dirty way to grab maldet session id, updated to work
                #with both maldet 1.4.0 and 1.4.1
                SESSID=`grep "-report" $TEMPFILE | awk '{print $NF}' | sed "s/'//"`
                #a maldet session file is not created if there's no files
                #to scan in the first place
                if [ -e /usr/local/maldetect/sess/session.$SESSID ]
                then
                    cp /usr/local/maldetect/sess/session.$SESSID $WORKDIR/$user
                else
                    echo "No files found" > $WORKDIR/$user
                fi
                rm $TEMPFILE
            else #homedir does not exist
                echo "Could not find a home directory for $user"
            fi
        #scan already completed for this user
        else
            echo "skipping scan for $user"
        fi
    done
}

###
# fn_report
#
# Creates a list of all files found in the maldet scans, as well as
# the standard classification : $file format that maldet outputs
#
# The fn_backup function depends on the file list this function generates
#
function fn_report {
    REPORTFILE=/root/maldet-report.$DATE
    FILELIST=/root/maldet-files.$DATE

    if [ -e $REPORTFILE ]; then rm -f $REPORTFILE; fi

    for file in `ls $WORKDIR/`
    do
        grep "/home" $WORKDIR/$file | grep -v PATH >> $REPORTFILE 
    done
    cat $REPORTFILE | cut -d: -f2 | sed 's/ //' > $FILELIST

    echo "Report saved in $REPORTFILE"
    echo "Plain file list saved in $FILELIST"
}

###
# fn_saveworkdir
#
# Just renames the current scan result directory with a date,
# so that a previous scan can be quarantined at a later date
#
function fn_saveworkdir {
    # unlikely that this will be run multiple times a day, aside from testing
    if [ -d $WORKDIR.$DATE ]
    then
        rm -rf $WORKDIR.$DATE
    fi
    mv $WORKDIR $WORKDIR.$DATE
    echo "Quarantine this finished scan with `basename $0` -q $WORKDIR.$DATE"
}

###
# fn_backup
#
# Although maldet quarantines do backup files, you'll need the session id to
# restore the maldet backup files. This copies all the suspicious files to
# a backup directory, preserving permissions and directory hierarchy for
# easy reference if a file needs to be restored/examined.
#
function fn_backup {
    BACKUPDIR=$BACKUPDIR_BASE/maldet-files.$DATE
    mkdir -p $BACKUPDIR

    echo "Copying suspicious files to $BACKUPDIR"
    for file in `cat $FILELIST`; do cp -p -f --parents $file $BACKUPDIR; done
}

###
# fn_quarantine
#
# Grabs session IDs from previous scans, then runs maldet -q to quarantine
# everything. Depends on maldet sessions not being purged.
#
function fn_quarantine {
    #dirty way to grab maldet session IDs
    grep "NOTE" $WORKDIR/* | cut -d\' -f2 | awk '{print $3}' > $TEMPFILE

    echo "Quarantining/cleaning suspicious files"
    for sessid in `cat $TEMPFILE`; do maldet -q $sessid > /dev/null; done
    rm $TEMPFILE
}

###
# fn_usage
#
# prints terribly useful help message
#
function fn_usage {
    echo "Usage: `basename $0` [--reset] [-q [path]] [--exclude user1[,user2,etc]]"
    echo ""
    echo "no arguments: scan all users public_html directories, generate report"
    echo "   -q [path]: scan and quarantine, using previous scan results from [path]"
    echo "     --reset: remove incomplete previous scan results"
    echo "   --exclude: comma seperated list of users to exclude from scans"
}

###
# fn_trapctrlc
#
# traps ctrl+c/kill signals, primarily to stop the for loop advancing in
# in the fn_scan function
# An incomplete scan will die off before copying maldet results to a file
#
function fn_trapctrlc {
   echo "Exiting"
   exit -1
}

###
# fn_excludeusers
#
# fn_scan looks for the presence of a file matching the current CPanel username
# in the scanning loop, to determine whether or not to proceed with a scan.
# Simply touch the file to make it skip the user.
#
function fn_excludeusers {
    excluded=$1
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
    IFS=","
    for user in $excluded
    do
	touch $WORKDIR/$user
    done
    unset IFS
}
##############################################################################
# End functions                                                              #
##############################################################################

# Setup
WORKDIR=$DEFAULT_WORKDIR
QUARANTINE_MODE=0

# Spring a ctrl+c trap
trap fn_trapctrlc SIGINT SIGTERM SIGKILL

# Parse arguments and figure out what to do
while [ $# -gt 0 ]
do
    case "$1" in
        # clear incomplete scan results
        --reset)
            rm -rf $DEFAULT_WORKDIR
            shift 1
            ;;
        # quarantine?
        -q|--quarantine)
            QUARANTINE_MODE=1
            # path to previous scan results passed?
            if [ ! -z $2 ]
            then
                WORKDIR=$2
                shift 1
            fi
            shift 1
            ;;
        # exclude users from scan
        --exclude)
            # make sure a userlist was passed
            if [ ! -z $2 ]
            then
                fn_excludeusers $2
                shift 1
            fi
            shift 1
            ;;
        # catchall, print help and exit
        *)
            fn_usage
            exit 1
    esac
done

# Start working
fn_scan
fn_report
if [ $QUARANTINE_MODE -eq 1 ]
then
    fn_backup
    fn_quarantine
else
    fn_saveworkdir
fi
