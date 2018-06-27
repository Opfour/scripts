#							   +----+----+----+----+
# 							   |    |    |    |    |
# Author: Mark David Scott Cunningham			   | M  | D  | S  | C  |
# 							   +----+----+----+----+
# Created: 2014-01-01
# Updated: 2015-08-16
#
#
#!/bin/bash

dash(){ for ((i=1;i<=$1;i++)); do printf "-"; done; }

    QUIET=0;VERBOSE=0;COUNT=10;DATE="$(date +'%a.%b.%d')";LOGFILE="/usr/local/apache/logs/error_log" # Initialization

modsec(){
    local OPTIND
    while getopts d:D:hi:l:n:qv option; do
      case "${option}" in
        q) QUIET=1 ;;
        v) VERBOSE=1 ;;
	d) DATE=$(date --date="-${OPTARG} days" +"%a.%b.%d");
	   echo; date --date="-${OPTARG} days" +"%A, %B %d, %Y -- %Y.%m.%d" ;;
	D) DOMAIN=${OPTARG} ;;
        i) IP=${OPTARG} ;;
	l) LOGFILE=${OPTARG} ;;
        n) COUNT=${OPTARG} ;;
        h) echo -e "\n Usage: $0 [OPTIONS]\n
    -d ... <days ago> (1-9...) otherwise assumes today
    -D ... <domain> to specify when searching errors
    -h ... display this help output and quit
    -i ... <ipaddress> (can be full IP or regex)
    -l ... <logfile> (set alternate log file)
    -n ... <linecount> (number of results to print)
    -q ... quiet, don't print error message
    -v ... verbose debugging output\n";
        return 0 ;;
      esac
    done

    echo; FORMAT="%-8s %-9s %-16s %-16s\n";

    nomsg=$(grep "$DATE" $LOGFILE | grep -v "\[msg" | grep "phase 2" | head -1)
    pcre=$(grep "$DATE.*PCRE" $LOGFILE | head -1)

    if [[ $QUIET != 1 ]]; then
      printf "$FORMAT" " Count#" " Error#" " Remote-IP" " Error Message";

      printf "$FORMAT" "--------" "---------" "$(dash 16)" "$(dash 42)";
      grep -Ei "$DATE.*client.$IP.*id..[0-9]{6,}\".*\[msg.*$DOMAIN" $LOGFILE\
         | perl -pe 's/.*\[client\ (.*?)\].*\[id "([0-9]{6,})"\].*\[msg "(.*?)"\].*/\2\t\1\t\3/' | sed 's/ /_/g'\
         | sort | uniq -c | sort -rn | awk '{printf "%7s   %-8s  %-16s %s\n",$1,$2,$3,$4}' | sed 's/_/ /g' | head -n $COUNT

      if [[ -n $nomsg ]]; then
	echo -e "\nPattern Matches"
        printf "$FORMAT" "--------" "---------" "$(dash 16)" "$(dash 42)";
        grep -v "\[msg" $LOGFILE | grep -E "$DATE.*client.$IP.*phase\ 2.*$DOMAIN"\
           | perl -pe 's/.*\[client\ (.*?)\].*phase.2\).\ (.*?)\[file.*\[id\ "(.*?)"\].*/\3\t\1\t\2/g' | sed 's/ /_/g'\
	   | sort | uniq -c | sort -rn | awk '{printf "%7s   %-8s  %-16s %s\n",$1,$2,$3,$4}' | sed 's/_/ /g' | head -n $COUNT
      fi

      if [[ -n $pcre ]]; then
	echo -e "\nPCRE Limits"
        printf "$FORMAT" "--------" "---------" "$(dash 16)" "$(dash 42)";
        grep PCRE $LOGFILE | grep -Ei "$DATE.*client.$IP.*id..[0-9]{6,}\".*$DOMAIN"\
           | perl -pe 's/.*\[client\ (.*?)\].*\[id\ "(.*?)"\].*(Execution.*?):.*/\2\t\1\t\3/' | sed 's/ /_/g'\
           | sort | uniq -c | sort -rn | awk '{printf "%7s   %-8s  %-16s %s\n",$1,$2,$3,$4}' | sed 's/_/ /g' | head -n $COUNT
      fi

    else
      printf "$FORMAT" " Count#" " Error#" " Remote-IP";
      printf "$FORMAT" "--------" "---------" "$(dash 16)";
      if grep -qEi '\[id: [0-9]{6,}\]' $LOGFILE; then
        grep -Ei "$DATE.*client.$IP.*\] |id.*[0-9]{6,}\]" $LOGFILE | awk 'BEGIN {RS="]\nc"} {print $4,$2}'\
         | tr -d \] | sort | uniq -c | awk '{printf "%7s   %-8s  %s\n",$1,$2,$3}' | sort -rnk1 | head -n $COUNT;
      else
        grep -Ei "$DATE.*client.$IP.*id..[0-9]{6,}\".*$DOMAIN" $LOGFILE | perl -pe 's/.*\[client\ (.*?)\].*\[id\ \"([0-9]{6,})\"\].*/\2 \1/'\
	 | sort | uniq -c | awk '{printf "%7s   %-8s  %s\n",$1,$2,$3}' | sort -rn | head -n $COUNT;
      fi
    fi
    echo

    if [[ $VERBOSE == 1 ]]; then
      echo -e "LOGFILE: $LOGFILE\nDOMAIN : $DOMAIN\nDATE   : $DATE\nCOUNT  : $COUNT\nIP     : $IP\n"; fi
}
modsec "$@"

###
#
# http://stackoverflow.com/questions/1103149/non-greedy-regex-matching-in-sed
#
# So apparently the easy way to do this without having to be very very specific with the regex in 'sed'
# is to use 'perl -pe' this allows for 'non-greedy' regex and grab just the bits I want from the error
#
# perl -pe 's/.*client\ (.*?)\].*id "([0-9]{6,})".*hostname "(.*?)".*/\2 \3 \1/'
# ^^ Solution to replace really long sed command
#
####
