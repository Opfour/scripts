#!/bin/bash
#                                                          +----+----+----+----+
#                                                          |    |    |    |    |
# Author: Mark David Scott Cunningham                      | M  | D  | S  | C  |
#                                                          +----+----+----+----+
# Created: 2015-12-21
# Updated: 2017-02-06
#
# Purpose: Find accounts full of symlinks (indicating symlink hacks)
#

#Utility functions
dash(){ for ((i=1;i<=$1;i++)); do printf $2; done; }

# trap command to capture ^C and cleanup function
cleanup(){
  echo -e "\n\nAlert :: Closing Scan  :: Cleaning up and exiting.\n Info :: To Resume Run ::  $0\n";
  rm -f $tmplog $pidfile; exit;
  }
trap cleanup SIGINT SIGTERM

scan_complete(){
# Final log and variable cleanup
rm -f $tmplog ${logdir}/*.user $pidfile $lockfile
unset logdir tmplog log userlist username homedir maxdepth count
}

# Resume a partial scan
resume(){
  resuming=1;
  log=$(tail -1 $lockfile);
  scanid=$(head -1 $lockfile)
  echo -e "\n Info :: Resuming Scan :: Continuing Scan_ID [${scanid}]\n\n";
  }

# Output help and usage information
usage(){
  echo "
  Usage: $0 [OPTIONS]

  -f ... Fast Mode, set scan directory depth to 3
  -t ... Threshold count of links to be logged
  -u ... User list: <usr1,usr2,usr3...>

  -h ... Print this help information and quit.
  ";
  scan_complete; exit;
  }

# Check for other running instances, and abort
pidfile="/var/run/symlinkhunter.pid"
if [[ -f $pidfile ]]; then scanid=$(cat $pidfile); fi
if [[ -f $pidfile && -d /proc/${scanid} ]]; then
  echo -e "
  It looks like another scan [${scanid}] is running.
  Started ::  $(ps -o lstart --pid=${scanid} | tail -1)
  Aborting to prevent logging conflicts.
  "; exit;
else
  echo "$$" > $pidfile; scanid="$$"
fi

# Initialize and count the number of /home/dirs
i=0; min=1; resuming=''; cpanel=''; plesk=''
if [[ -d /usr/local/cpanel/ ]]; then #CPANEL
  userlist="/home*/*/public_html/";
  cpanel=1;
elif [[ -d /var/www/vhosts/ ]]; then #PLESK
  userlist="/var/www/vhosts/*/"
  plesk=1;
fi

t=$(echo $userlist | wc -w);

# /usr/local/maldetect/sess/session.160111-0004.20837 (for reference)
logdir="/usr/local/symdetect"
tmplog="${logdir}/symlinkhunter.tmplog"
log="${logdir}/symlinkhunter.$(date +%y%m%d-%H%M).${scanid}.log"
if [[ ! -d $logdir ]]; then mkdir -p $logdir; fi

# Argument parsing
echo; while getopts fht:u: option; do
  case "${option}" in
    f) maxdepth="-maxdepth 3";
	echo " Info :: Fast Mode Enabled :: Setting link search depth to 3" ;;
    t) min="${OPTARG}";
	echo " Info :: Min Threshold Set :: Setting logging threshold to ${OPTARG} links" ;;
    u) if [[ $cpanel ]]; then
         userlist="$(for x in $(echo ${OPTARG} | sed 's/,/ /g'); do echo /home*/${x}/public_html/; done)" ;
       elif [[ $plesk ]]; then
         userlist="$(for x in $(echo ${OPTARG} | sed 's/,/ /g'); do echo /var/www/vhosts/${x}/; done)" ;
       fi
       t=$(echo $userlist | wc -w) ;;
  *|h) usage ;;
  esac
done;

# Check if a previous scan was running, and resume
lockfile="/var/run/symlinkhunter.lock"
if [[ -f $lockfile ]]; then
  echo -e "Alert :: Lock File Exists :: Interrupted scan detected.\n Info :: Scan Started On  ::  $(sed -n 2p < $lockfile)\n Info :: Log File Found   :: $(basename $(tail -1 $lockfile))\n"
  read -p "  Continue previous scan? [Y/n]: " yn;
  if [[ $yn =~ [yY] ]]; then resume; else rm -f ${logdir}/*.user; fi;
else
  echo -e "$$\n$(ps -o lstart --pid=$$ | tail -1)\n${log}" > $lockfile;
fi

# Start new log only if not resuming a previous scan
if [[ ! $resuming ]]; then
  if [[ $cpanel ]]; then
    # Check last runs of EA to see if Symlink Protection is enabled
    echo -e "$(dash 80 -)\n  Symlink Protection Status\n$(dash 40 -)\n" | tee $log;
    if [[ -d /var/cpanel/easy/apache/runlog/ ]]; then
      for logfile in /var/cpanel/easy/apache/runlog/build.*; do
        echo -n "$(grep SymlinkProtection $logfile | sed 's/1/Enabled/g;s/0/Disabled/g') :: ";
        stat $logfile | awk '/^Modify/ {print $2}';
      done | tail -5 | tee -a $log;
    else #EA4
      grep symlink /var/cpanel/conf/apache/local
    fi
  fi

  # Start Symlink Hunting
  echo -e "\n$(dash 80 -)\n  Symlink Search Results\n$(dash 40 -)\n" | tee -a $log;
  echo -e "START_SCAN: $(date +%F_%T)\n" >> $log;
fi

# Loop through the homedirs
for homedir in $(echo $userlist); do
  # Print scanning progress
  count=0; ((i++));

  if [[ $cpanel ]]; then
    username="$(echo $homedir | cut -d/ -f3)"
  elif [[ $plesk ]]; then
    username="$(echo $homedir | cut -d/ -f5)"
  fi

  printf "%-80s\r" "[$i/$t] :: $username :: Scanning"

  # Actually search symlinks and count them
  if [[ ! -f ${logdir}/${username}.user ]]; then
    echo -n > $tmplog

    if [[ $cpanel ]]; then
      find $homedir $maxdepth -type l -print | sort | uniq > $tmplog;
    elif [[ $plesk && ! $homedir =~ /var/www/vhosts/system/.* ]]; then
      homedirs=$(find $homedir -maxdepth 1 -type d -group psaserv -print)
      find $homedirs $maxdepth -type l -print | sort | uniq > $tmplog;
    fi

    count=$(wc -l < $tmplog)

    # Only print the results above the $min threshold
    if [[ $count -ge $min ]]; then
      # Count per subdirectory (verbose output sent to log)
      printf "%8s :: %-80s\n" "$count" "$homedir" | tee -a $log;
      printf "%-80s\r" "[$i/$t] :: $username :: Generating Report"
      awk -F/ '$NF=""; {freq[$0]++} END {for (x in freq) {printf "%8s :: {SYM} ::%s\n",freq[x],x}}' $tmplog\
        | sed 's/\b /\//g; s/ home/ \/home/g; s/ var/ \/var/g; s/\/:/ :/g;' >> $log;
      echo >> $log;
    else
      printf "%-80s\r" " ";
    fi
    echo $i > ${logdir}/${username}.user
  fi
done

# Close out log file
printf "%-80s\r" " ";
echo -e "  END_SCAN: $(date +%F_%T)\n" >> $log;

# Finish and print footer
echo -e "\n$(dash 80 -)\n  Scan log: $log\n$(dash 40 -)\n"

# Run final cleanup after complete scan
scan_complete; exit;
