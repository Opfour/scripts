#!/bin/bash
#written by Mike Shooltz for assistance email me at mshooltz@liquidweb.com.
# add coloring
RESTORE='\e[0m'
RED='\e[0;31m'
GREEN='\e[0;32m'
CYAN='\e[0;36m'
LYELLOW='\e[1;33m'

## Variables
SCRIPT_NAME=$0
selection=$1
SCRIPT_VERSION=1.0
DomainList=`cat /etc/userdomains | cut -d: -f1 | grep -v "*" | sed ':a;N;$!ba;s/\n/ /g'`
#DomainList=(List manually here)
tmPfile=/tmp/domaincheck-`date +%Y%m%d%M%S`.tmp

function broken {
	echo >> $tmPfile
	echo -e "$RED""Problematic Domains:$RESTORE" >> $tmPfile
	for i in ${DomainList[@]}; do
	responsecode=`curl -Is http://$i | grep HTTP | cut -d\  -f1`
	if [ -z $responsecode ]; then 
		echo -en "$GREEN\t$i~-~$RED""Doesnt resolve or is not setup$RESTORE\n" >> $tmPfile
		curl -Is http://$i | grep HTTP >> $tmPfile
		responsecode=""
	fi
	done
	echo >> $tmPfile
}

function reporting {
	echo >> $tmPfile
	echo -e "$CYAN""Domains with apache response codes:$RESTORE" >> $tmPfile
	for i in ${DomainList[@]}; do
		responsecode=`curl -Is http://$i | grep HTTP | cut -d\  -f1`
		if [ ! -z $responsecode ]; then
			responsecode2=`curl -Is http://$i | grep HTTP | cut -d\  -f2`
			if [ "$responsecode2" -ne "200" ]; then
				result=`echo $(curl -Is http://$i | grep HTTP)| tr -d "\r"`
				echo -en "$GREEN\t$i~-~$RED""$result""$RESTORE" >> $tmPfile
				echo >> $tmPfile
			else
	                        echo -en "$GREEN\t$i~-~$RESTORE" >> $tmPfile
				curl -Is http://$i | grep HTTP >> $tmPfile
			fi
			responsecode2=""
	        	responsecode=""
		fi
	done
	echo >> $tmPfile
}

function helpinfo {
	echo ""
	echo -e "$LYELLOW""Usage: $0 <reporting|broken|help>$RESTORE"
        echo ""
}

function format {
	MaxLength=$(echo $(egrep -o '[[:alnum:][:graph:]]*~' $tmPfile |awk -F~ '/~/ {print length}' | sort -nr | head -1) +10 | bc)
	awk -F "~" -v MaxLength="$MaxLength" '{ printf("%-" MaxLength "s%-5s %-10s\n", $1, $2, $3) }' $tmPfile
}

#Logic
if [ "$selection" == broken ]; then
	broken
        format
elif [ "$selection" == reporting ]; then
	reporting
        format
elif [ "$selection" == help ]; then
	helpinfo
else
	broken
	reporting
	format
fi
