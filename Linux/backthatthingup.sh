#!/bin/bash - 
#===============================================================================
#
#          FILE:  backthatthingup.sh
# 
#         USAGE:  ./backthatthingup.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Dennis Walters (dwalters), dwalters@liquidweb.com
#       COMPANY: Liquid Web, Inc.
#       CREATED: 05/03/10 17:29:49 EDT
#      REVISION:  ---
#===============================================================================

die () { #verified
  echo "$1" 1>&2
  exit 255
}

defined () { #verified
  [ -n "$1" ]
}

full_backup_needed () { #verified
  namemonth=$(date +"%a %b")
  day=$(date +"%d")
  if [ $day -lt 10 ]
  then
    day=$(echo $day | sed "s/0/ /")
  fi
  datestamp="$namemonth $day"
  ! /usr/local/bin/duply ${PROFILE} status | grep "Full" | grep "$datestamp" > /dev/null 2>&1
}

lockfile_exists () { #verified
  [ -f "/var/lock/subsys/backup-${PROFILE}" ]
}

backup_command () { #verified
  cmd="/usr/local/bin/duply ${PROFILE}"
  today=$(date +"%u")
  temp="backup"
  if [ $today -eq 1 ]
  then
    if full_backup_needed
    then
      $cmd purge-full --force > /dev/null 2>&1
      temp="full"
    fi
  fi

  echo "$cmd $temp"
}

lockfile_pid () { #verified
  lockfile_exists && pid=$(cat /var/lock/subsys/backup-${PROFILE})

  defined "$pid" || pid=-1

  echo $pid
}

create_lockfile () {
  echo "$(my_pid)" > /var/lock/subsys/backup-${PROFILE}
}

remove_lockfile () {
  rm -f /var/lock/subsys/backup-${PROFILE}
}

process_running () { #verified
  [ -d "/proc/${1}" ]
}

is_lockfile_fresh () { #verified
  lockfile_exists && process_running $(lockfile_pid)
}

should_run_backups () {
  if is_lockfile_fresh
  then
    return 1
  else
    remove_lockfile
    return 0
  fi
}

my_pid () { #verified
  echo $$
}

PROFILE=$1

if should_run_backups
then
  create_lockfile
  cmd=$( backup_command )
  eval "$cmd"
  remove_lockfile
else
  echo "A backup is already in progress."
fi
