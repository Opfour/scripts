#!/bin/bash
#VERSION#2.0.6
# dos-apf.sh    version 2.0.6
#    Will auto-detect dos attacks and block hosts accordingly via APF.
#
# Usage:
#   Modify 'maxcon' and 'maxbans' before running script.
#   Simply run 'bash dos-apf.sh'
#   Will not work as cron job.

# Change Log:
# Version 2.0.6
#    Changed netstat commandline to include better parsing, and inclusion of ipv6 ip addresses
#    Checks vor new version
# Version 2.0.5
#    New configuration variable: maxbans
#    badips is now an array
#    added several functions to help parse array (addnew, remove, contains)
#    Removes old bans from deny_hosts.rules & Reloads apf


### START CONFIGURATION

## How many connections allowed before we consider this a dos?
maxcon=100

## How many IPs to ban at one time before cycling old bans?
maxbans=500 #  This number is not yet known.  Please adjust.

## How many seconds to delay before checking for more DOS attacks?
delay=3

### END CONFIGURATION


######## DO NOT MODIFY PAST THIS LINE

# Check for update
wget http://layer3.liquidweb.com/scripts/dos-apf.sh --output-document dos-apf.update &>/dev/null
curver=`cat dos-apf.update | grep ".VERSION#" | sed -e 's/.VERSION#//' | head -1`
myver=`cat $0 | grep ".VERSION#" | sed -e 's/.VERSION#//' | head -1`
if [[ $curver != $myver ]]; then 
    echo "Updating $0"
    wget http://layer3.liquidweb.com/scripts/dos-apf.sh --output-document dos-apf.update &> /dev/null
    mv -f dos-apf.update $0
    echo "$0 has been updated.  Please re-configure and restart."
    exit 100
else
    echo "$0 is up to date."    
fi

badips=()
# Should we really run?
if [[ $UID != 0 ]]; then  # Are we root?
    echo "$0 must be ran as root."
    exit 1
fi
if [[ "`which apf`" == "" && "$1" != "--nodeps" ]]; then  # does apf exist?
    echo "$0 requires apf"
    exit 1
fi
# Array Functions
contains() 
{
    local temp=${badips[@]/$1/}
    if [[ "${badips[@]}" == "${badips[@]/$1/}" ]]; then
        echo "0"
    else
        echo "1"
    fi
}
## Remove element from array.
remove() {
    local temp=$1
    local output
    for each in $(seq 0 $((${#badips[@]} - 1))); do 
    if [[ ${badips[$each]} != $temp ]]; then
        output=( ${output[@]} ${badips[$each]} )
    fi
    done
    badips=( ${output[@]} )
    return
}
# Add new element to array
addnew() { 
   badips=( ${badips[@]} $1 )
   #echo "ADDED $1"
}
# Add apf entries.
echo -en "Parsing deny_hosts.rules: "
if [  -r /etc/apf/deny_hosts.rules ]; then # does ban file exist?
    apfhosts=`cat /etc/apf/deny_hosts.rules | sed -e '/^#/d'`
    for each in $apfhosts;do
        addnew $each
    done
    if [[ ${#badips[@]} -gt $maxbans ]]; then
        echo "" > /etc/apf/deny_hosts.rules
        for each in ${badips[0]:$((${#badips[@]} - maxbans))}; do
                apf -u $each
        done
        badips=( ${badips[@]:$((${#badips[@]} - maxbans))} )
    fi
    echo ${badips[@]}
        
else
    echo -e "Warning:\tdeny_hosts.rules does not exist"
fi
echo "Searching for dos attacks.."
while [[ "$1" != "-c" ]]; do
  netstat=`netstat -tun | sed -e '/^[(tcp)|(udp)]/!d' -e 's/::ffff://g' | awk '{print $5}' | sed -e 's/:.*//' | sort -n | uniq -c | sort -n | awk '{print $1"-"$2}'`
# Find DOS attacks
  for each in $netstat; do 
        connections=${each/-*/}
        ip=${each/*-/}
        if [[ "$ip" != "" && $connections -gt $maxcon && `contains $ip` == 0 ]]; then # Too many connections?
             echo "Auto-Detected DOS with $connections connections from $ip"
                ## Too many bans?
                if [[ $((${#badips[@]} + 1)) -gt $maxbans ]]; then
                  apf -u ${badips[0]}
                  badips=( ${badips[@]:1} )
                fi
                # add IP to our list
                addnew $ip
                apf -d $ip Auto-Detected DOS with $connections connections 2> /dev/null
        fi
  done
  if [[ "$1" != "-c" ]]; then
        sleep $delay  # Don't put a load the server
  fi
done
