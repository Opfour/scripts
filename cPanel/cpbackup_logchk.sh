#!/bin/bash

# written by bcathey 20090317

logfile=$1

get_users(){
  users=$(cat $logfile | grep pkgacct | grep user | sed -n 's/^.*user : \([^\ ]*\).*$/\1/p'|sort)
}

find_bad_users(){
IFS=$'\n'
  for user in $users
  do
    errors=$(sed -n "/pkgacct version 8.3 - user : $user/,/pkgacctfile is:/p" $logfile | grep 'Permission')
    if [ "$errors" ]
    then
      echo "------------"
      printf "| %-8s |\n" $user
      echo "------------"
      for error in $errors
      do
        file=$(echo $error | sed -n 's/^.*\/bin\/gtar: .\(.*\): Can.*$/\1/p')
        echo $file
        echo "  `ls -lahd /home/$user$file`"
      done
      echo
    fi
  done
IFS=$' '
}

if [ -a "$logfile" -o -n "$1" ]
then
  echo
  get_users
  find_bad_users
  echo
else
  echo
  echo "Invalid log file specified"
  echo "Usage: cpbackup_logchk /usr/local/cpanel/logs/cpbackup/##########.log"
  echo
fi

