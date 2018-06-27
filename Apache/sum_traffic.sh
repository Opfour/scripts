#                                                          +----+----+----+----+
#                                                          |    |    |    |    |
# Author: Mark David Scott Cunningham                      | M  | D  | S  | C  |
#                                                          +----+----+----+----+
# Created: 2014-04-18
# Updated: 2017-01-08
#
#
#!/bin/bash

## COLORS: Taste the Rainbow
      BLACK=$(tput setaf 0);        RED=$(tput setaf 1)
      GREEN=$(tput setaf 2);     YELLOW=$(tput setaf 3)
       BLUE=$(tput setaf 4);     PURPLE=$(tput setaf 5)
       CYAN=$(tput setaf 6);	  WHITE=$(tput setaf 7)
     BRIGHT=$(tput bold);        NORMAL=$(tput sgr0)
      BLINK=$(tput blink);	REVERSE=$(tput smso)
  UNDERLINE=$(tput smul);

## Add extended globbing
shopt -s extglob

## Initializations
hourtotal=($(for ((i=0;i<23;i++)); do echo 0; done)); grandtotal=0; nocolor=0; progress=''
DECOMP="$(which grep)"; THRESH=''; DATE=$(date +"%d/%b/%Y"); FMT=" %5s"
DOMAINS="/usr/local/apache/logs/access_log /usr/local/apache/domlogs/*/!(*[^ssl]_log*)";
RANGE=$(for x in {23..0}; do date --date="-$x hour" +"%d/%b/%Y:%H:"; done);

while getopts d:l:npr:8t:vh option; do
    case "${option}" in
	# Caclulate date string for searches
        d) DATE=$(date --date="-${OPTARG} days" +"%d/%b/%Y"); DECOMP="$(which zgrep)"; SUFFIX=$(date --date="-${OPTARG} days" +"-%b-%Y.gz")
	   DOMAINS="/usr/local/apache/logs/access_log /home/*/logs/!(*[^ssl]_log*)$SUFFIX"
	   RANGE=$(for x in {23..0}; do date --date="-${OPTARG} days -$x hour" +"%d/%b/%Y:%H:"; done) ;;

	# Use list of domains rather than all sites
        l) DOMAINS="$(for x in $(echo ${OPTARG} | sed 's/,/ /g'); do echo /usr/local/apache/domlogs/*/$x; done)" ;;

	# Print w/o color in b/w
	n) nocolor=1 ;;

	# Show progress indicator: account :: logfile
	p) progress=1 ;;

	# Print only a specified range of hours
	r) INPUT=$(echo ${OPTARG} | sed 's/,/ /g'); FMT=" %7s";
	   RANGE=$(for x in $(seq -w $INPUT); do echo "${DATE}:${x}:"; done) ;;

	8) RANGE=$(for x in {7..0}; do date --date="-$x hours" +"%d/%b/%Y:%H:"; done); FMT=" %7s" ;;

	# Threshold for printing only busy sites
        t) THRESH=${OPTARG} ;;

	# Verbose outpout for debugging
	v) echo -e "\nDecomp   : $DECOMP\nDate     : $DATE\nSuffix   : $SUFFIX\nRange    : $(echo -n $RANGE)\nDomains  : $DOMAINS\nThreshold: $THRESH\n" ;;

	# Help output
	h) echo -e "\n ${BRIGHT}Usage:${NORMAL} $0 [OPTIONS]\n
    -d ... days-ago <##>
    -h ... Print this help and quit
    -l ... list of domains <dom1,dom2,...>
    -n ... No Color (for output to files)
    -p ... Progress, show name of current log
    -r ... Range of hours <start#,end#>
    -8 ... Auto set to previous 8 hours
    -t ... threshold value <#####>
    -v ... Verbose (debugging output)\n"; exit ;;
    esac
done; echo

## Header
printf "${BRIGHT} %15s" "User/Hour";
for hour in $RANGE; do printf "$FMT" "$(echo $hour | cut -d: -f2):00"; done;
printf "%8s %-s${NORMAL}\n" "Total" " Domain Name"

## Data gathering and display
for logfile in $DOMAINS; do
        total=0;

    # If progress flag is given then print
    if [[ $progress ]]; then
        log=$(echo $logfile | awk -F/ '{print $(NF-1)" :: "$NF}')
        printf " Reading: %s                                                                                \r" "$log"
    fi

    # Only print if the threshold condition is set/met
    if [[ -z $THRESH || $THRESH -le $($DECOMP -c $DATE $logfile) ]]; then
        if [[ $nocolor != '1' ]]; then color="${BLUE}"; else color=''; fi
	if [[ $DATE != $(date +"%d/%b/%Y") ]]; then
	    ACCT=$(echo $logfile | cut -d/ -f3)
	    SITE=$(basename $logfile $SUFFIX)
	else
	    ACCT=$(echo $logfile | cut -d/ -f6)
	    SITE=$(echo $logfile | cut -d/ -f7)
	fi
        printf "${color} %15s" "$ACCT"

	i=0;
	# Iterate through the hours
        for hour in $RANGE; do
                count=$($DECOMP -c "$hour" $logfile);
                hourtotal[$i]=$((${hourtotal[$i]}+$count))

                if [[ $nocolor != '1' ]]; then ## COLOR VERSION (HEAT MAP)
                    if [[ $count -gt 20000 ]]; then color="${BRIGHT}${RED}";
                    elif [[ $count -gt 2000 ]]; then color="${RED}";
                    elif [[ $count -gt 200 ]]; then color="${YELLOW}";
                    else color="${GREEN}"; fi
                else color=''; fi

                printf "${color}$FMT${NORMAL}" "$count"
                total=$((${total}+${count})); i=$(($i+1))
        done
        grandtotal=$(($grandtotal+$total))

        if [[ $nocolor != '1' ]]; then ## Color version
          printf "${CYAN}%8s ${PURPLE}%-s${NORMAL}\n" "$total" "$SITE"
        else printf "%8s %-s\n" "$total" "$SITE"; fi
    fi
done

## Footer
printf "${BRIGHT} %15s" "Total"
for x in $(seq 0 $((${i}-1))); do printf "$FMT" "${hourtotal[$x]}"; done
printf "%8s %-s${NORMAL}\n" "$grandtotal" "<< Grand Total"
echo
