#!/bin/bash
#                                                          +----+----+----+----+
#                                                          |    |    |    |    |
# Author: Mark David Scott Cunningham                      | M  | D  | S  | C  |
#                                                          +----+----+----+----+
# Created: 2015-03-09
# Updated: 2017-02-25
#
# Purpose: Checking blacklists both public and private by sending SMTP connections
#
# Original concept, Brian Nelson; greatly expanded by me.

# Taste the rainbow
      BLACK=$(tput setaf 0);        RED=$(tput setaf 1)
      GREEN=$(tput setaf 2);     YELLOW=$(tput setaf 3)
       BLUE=$(tput setaf 4);    PURPLE=$(tput setaf 5)
       CYAN=$(tput setaf 6);	  WHITE=$(tput setaf 7)

     BRIGHT=$(tput bold);        NORMAL=$(tput sgr0)
      BLINK=$(tput blink);	REVERSE=$(tput smso)
  UNDERLINE=$(tput smul)

dash(){ for ((i=1; i<=$1; i++)); do printf "$2"; done; }

quiet=''; verb=''; from_addr=''; ip_list=''; all='';

mailcheck(){
local OPTIND
while getopts af:i:qvh option; do
  case "${option}" in
    # Tell script to loop through all public IPs on server
    a) all=1 ;;

    # Set the from address to something other than root@hostname
    f) from_addr=" -f ${OPTARG}"; echo -e "\nSending tests as: ${BRIGHT}${RED}${OPTARG}${NORMAL}" ;;

    i) ip_list=$(echo ${OPTARG} | sed 's/,/ /g');;

    # Set Quiet Mode for not printing links
    q) quiet=1 ;;

    # Print out resuts for all the mail hosts regardless of errors
    v) verb=1 ;;

    # Help Output and quit
    h|*)
      echo -e "\n  ${BRIGHT}Usage:${NORMAL} $0 [options] [arguments]\n
    -a ... check all public IPs on server
    -f ... Set the <FROM> address for testing
    -i ... Comma separated list of <IPs> for testing
    -q ... Quiet (don't print web links)
    -v ... Verbose (print empty swaks results)\n
    -h ... Print this help and quit\n"; return 0 ;;
  esac
done

print_delist_link(){
  if [[ $result =~ 5[0-9][0-9] ]]; then
    printf "${CYAN}DeList:${NORMAL} "
    case $domain in
            aol.com ) echo "https://postmaster.aol.com/sa-ticket" ;;
            att.net ) echo "http://rbl.att.net/cgi-bin/rbl/block_admin.cgi" ;;
        comcast.net ) echo "http://postmaster.comcast.net/block-removal-request.html" ;;
      earthlink.net ) echo "https://support.earthlink.net/articles/email/email-blocked-by-earthlink.php" ;;
           live.com ) echo "https://support.live.com/eform.aspx?productKey=edfsmsbl3&ct=eformts&wa=wsignin1.0&scrx=1" ;;
             rr.com ) echo "http://postmaster.rr.com/amIBlockedByRR" ;;
        verizon.net ) echo "http://my.verizon.com/micro/whitelist/RequestForm.aspx?id=isp" ;;
          yahoo.com ) echo "http://help.yahoo.com/l/us/yahoo/mail/postmaster/bulkv2.html" ;;
    esac
  fi
  }

# What IPs to check
if [[ $all ]]; then
  ip_list="$(/sbin/ip addr show | awk '/inet / && ($2 !~ /^127\.|^10\.|^192\.168\./) {print $2}' | cut -d/ -f1)"; # All IPs
elif [[ ! $ip_list ]]; then
  ip_list="$(/sbin/ip addr show | awk '/inet / && ($2 !~ /^127\.|^10\.|^192\.168\./) {print $2}' | cut -d/ -f1 | head -1)"; # Main IP
fi

# Check to see if using NAT IPs behind HW Firewall
if [[ $ip_list =~ ^172\. ]]; then
  dnsip=$(curl -s http://ip.robotzombies.net);
  echo -e "\nServer appears to be NAT'd behind a firewall.\nThe public IP appears to be: $dnsip";
fi

for ipaddr in $ip_list; do
  if [[ ! $quiet ]]; then
    if [[ $dnsip ]]; then realip=${dnsip}; else realip=${ipaddr}; fi
    echo -e "\n$(dash 80 =)\n${WHITE}  Web Based Checks -- ${realip} ${NORMAL}\n$(dash 80 -)"
    rdns="$(dig +short -x $realip)" # Check RDNS
    echo "rDNS/PTR: ${GREEN}${rdns:-${RED}Is not setup ...}${NORMAL}"

    # Web based lookups
    echo "http://multirbl.valli.org/lookup/${YELLOW}${realip}${NORMAL}.html"
    echo "http://www.senderbase.org/lookup/?search_string=${YELLOW}${realip}${NORMAL}"
    echo "http://mxtoolbox.com/SuperTool.aspx?action=blacklist%3a${YELLOW}${realip}${NORMAL}&run=toolpage"
  fi

  # Sanity Check -- Does Swaks exist, if not, install it
  if [[ ! -x /usr/bin/swaks ]]; then wget -q http://jetmore.org/john/code/swaks/latest/swaks -O /usr/bin/swaks; chmod +x /usr/bin/swaks; fi
  echo -e "\n$(dash 80 =)\n${WHITE}  Swaks Based Checks -- ${ipaddr} ${NORMAL}\n$(dash 80 -)"

  # Send test emails with swaks to check for errors
  for domain in aol.com att.net comcast.net earthlink.com gmail.com live.com rr.com verizon.net yahoo.com; do
    mx=$(dig mx +short ${domain} | awk 'END {print $NF}')
    if [[ $domain =~ gmail.com ]]; then emailAddress="no-reply@gmail.com"; else emailAddress="postmaster@${domain}"; fi
    result=$(swaks -4 -q RCPT --server $mx -t $emailAddress $from_addr -li $ipaddr 2>&1 | egrep ' 4[25][01]| 5[257][0-4]';)
    if [[ $verb == "1" || -n $result ]]; then
      printf "\n%-40s  %-40s\n" "${CYAN}Domain:${NORMAL} $domain" "${CYAN}Server:${NORMAL} $mx"
      print_delist_link
      echo -e "$(dash 80 -)\n${result:-No Reported Errors}";
    fi
  done; echo
done
echo -e "$(dash 80 =)\n"

unset ipaddr ip_list rdns result verb quiet cont from_addr dnsip realip
}

mailcheck "$@"
