#!/bin/bash
#                                                          +----+----+----+----+
#                                                          |    |    |    |    |
# Author: Mark David Scott Cunningham                      | M  | D  | S  | C  |
#                                                          +----+----+----+----+
# Created: 2015-11-30
# Updated: 2017-02-13
#
# Purpose: Gather IP/DNS/Mail informaion for some or all domains on a server
#

# Taste the rainbow
      BLACK=$(tput setaf 0);        RED=$(tput setaf 1)
      GREEN=$(tput setaf 2);     YELLOW=$(tput setaf 3)
       BLUE=$(tput setaf 4);     PURPLE=$(tput setaf 5)
       CYAN=$(tput setaf 6);      WHITE=$(tput setaf 7)

     BRIGHT=$(tput bold);        NORMAL=$(tput sgr0)
      BLINK=$(tput blink);      REVERSE=$(tput smso)
  UNDERLINE=$(tput smul)

# Setting defaults
httpdconf=$(httpd -V 2>/dev/null | awk -F\" '/HTTPD_ROOT|SERVER_CONFIG_FILE/ {printf "/"$2}')
notLive=''
dnsLookup=''
recordType="MX"
account=".*"
csvMode=''
wide=40
main=''

# Utility Functions
getusr(){ pwd | sed 's:^/chroot::' | cut -d/ -f3; }
dash(){ for ((i=1; i<=$1; i++)); do printf "-"; done; }

# Parsing input from command line flags
#local OPTIND
while getopts a:cd:mnwh option; do
  case "${option}" in
    a) if [[ ${OPTARG} == '.' ]]; then account=$(getusr); else account=${OPTARG}; fi ;;
    c) csvMode=1 ;;
    d) recordType=${OPTARG}; dnsLookup=1;;
    m) main=1 ;;
    n) notLive=1 ;;
    w) wide=60 ;;
    h) echo "
  ${BRIGHT}Usage:${NORMAL} $0 [OPTIONS] [ARGUMENTS]

    -a ... Specify Account or use '.' for AutoDetect using \$PWD
    -c ... Format output as CSV (use with > to file)
    -d ... DNS lookup for given record type
    -n ... Only list domains NOT pointed to the server
    -m ... Only list main domains for each account
    -w ... Wide mode (60 character columns; default is 40)
    -h ... Print this help and quit

  Examples:

  Show main domains only
    $0 -m

  Show only domains not pointed to the server
    $0 -n

  Perform additional DNS lookup (for mx records)
    $0 -d mx

  Output in CSV format (and send to file, for use as spreadsheet)
    $0 -c > domains-report-\$(hostname)-\$(date +%F).csv
       "; exit ;;
  esac
done

# Formatting
FMT="%-15s %-15s %-3s %-6s %-8s %-${wide}s %-s\n"
HIGHLIGHT="${BRIGHT}${RED}%-15s %-15s${NORMAL} %-3s %-6s %-8s ${BRIGHT}${RED}%-${wide}s${NORMAL} %-s\n"
CSV="\"%-s\",\"%-s\",\"%-s\",\"%-s\",\"%-s\",\"%-s\",\"%-s\"\n"
if [[ $csvMode ]]; then FMT=$CSV; HIGHLIGHT=$CSV; fi

# Lookup all the domains on the server
domainList=$(sed 's/==/: /g' < /etc/userdatadomains | sort -k2 | awk -F: "/: ${account}/"' {print $1}')
#domainList=$(awk -F: "/: ${account}/"' {print $1}' /etc/userdatadomains)
#domainList=$(awk '/ServerName/ {print $2}' $httpdconf | sort | uniq)

# Check if mail is configured for remote or local
_remoteLocal(){
if [[ $csvMode ]]; then # CSV mode
  if [[ -n $(grep $1 /etc/localdomains) ]]; then echo "Local "
    elif [[ -n $(grep $1 /etc/remotedomains) ]]; then echo "Remote"
    else echo "NoConf"
  fi
else # Print colors
  if [[ -n $(grep $1 /etc/localdomains) ]]; then echo "${GREEN}Local${NORMAL} "
    elif [[ -n $(grep $1 /etc/remotedomains) ]]; then echo "${RED}Remote${NORMAL}"
    else echo "${BRIGHT}NoConf${NORMAL}"
  fi
fi
}

# Printing Column Headers
printf "\n$FMT" " Vhost-IP" " DNS-IP" "SSL" "MailEx" " Type" " Domain" " Additional Info"
printf "$FMT" "$(dash 15)" "$(dash 15)" "---" "------" "--------" "$(dash $wide)" "$(dash $wide)"

# Loop through the list of domains and gather information.
for domain in $domainList; do
  # Find the IP configured in httpd.conf
  vhostIP=$(grep -B5 -E "Server(Name|Alias).*\ $domain" $httpdconf | awk '/<VirtualHost.*:80/ {print $2}' | cut -d: -f1 | head -1;)

  # Find if there is an SSL installed on the domain
  if [[ -n $(grep -B5 -E "Server(Name|Alias).*\ $domain" $httpdconf | awk '/<VirtualHost.*:443/ {print}') ]]; then
    if [[ $csvMode ]]; then ssl="SSL"; else ssl="${YELLOW}SSL${NORMAL}"; fi
  else ssl=""; fi

  # Find the IP resolving in DNS
  dnsIP=$(dig +short +time=2 +tries=2 $domain | grep [0-9] | head -1;)

  # Find a DNS record
  if [[ $recordType =~ [Aa] ]]; then
    dnsRecord=""
    dnsRecordIP=$(dig +short +time=2 +tries=2 $domain | tail -1 | grep -v 'root-server';)
  else
    dnsRecord=$(dig $recordType +short +time=2 +tries=2 $domain | awk 'END{print $NF}' | grep -v 'root-server';)
    dnsRecordIP=$(dig +short +time=2 +tries=2 $dnsRecord | tail -1 | grep -v 'root-server';)
  fi

  # Lookup DocRoot in  httpd.conf
  docRoot=$(grep -A5 -E "Server(Name|Alias).*\ $domain" $httpdconf | awk '/DocumentRoot/ {print $2}' | head -1)
  #docRoot=$(sed 's/==/: /g' < /etc/userdatadomains | awk -F: "/^$domain/"'{print $6}';)

  # Lookup domain type in /etc/userdatadomains
  domType=$(sed 's/==/: /g' < /etc/userdatadomains | awk -F: "/^$domain/"'{print $4}' | head -1;)

  # Get user/acct from the document root
  acct=$(echo $docRoot | sed 's:^/chroot::' | cut -d/ -f3;)

  if [[ $dnsLookup ]]; then addInfo="$dnsRecordIP $dnsRecord"; else addInfo="$docRoot"; fi

  if [[ (-n $main && $domType =~ main) || -z $main ]]; then
    if [[ ($vhostIP == $dnsIP) && -z $notLive ]]; then
      printf "$FMT" "$vhostIP" "$dnsIP" "${ssl:- - }" "$(_remoteLocal $domain)" "$domType" "$domain" "$addInfo"
    elif [[ $vhostIP != $dnsIP ]]; then
      # Check if the domain is using a masking service and then report that
      masking=$(curl -s ipinfo.io/$dnsIP | grep -Eio 'cloudflare|incapsula|sucuri' | tail -1)
      if [[ $masking ]]; then dnsIP=$masking; fi
      printf "$HIGHLIGHT" "$vhostIP" "$dnsIP" "${ssl:- - }" "$(_remoteLocal $domain)" "$domType" "$domain" "$addInfo"
    fi
  fi
done; echo
