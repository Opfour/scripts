#!/bin/bash
#                                                          +----+----+----+----+
#                                                          |    |    |    |    |
# Author: Mark David Scott Cunningham                      | M  | D  | S  | C  |
#                                                          +----+----+----+----+
# Created: 2017-04-23
# Updated: 2017-05-07
#
# Purpose: Check available SSL version and ciphers (replicate nmap ssl-enum-ciphers)
#
# Notes: Based on concept and initial code by JBurnham
# Download the 'cipherlist.sh' script
#
# mkdir -p ~/bin
# wget http://layer3.liquidweb.com/scripts/mcunningham/cipherlist.sh -O ~/bin/cipherlist.sh
# chmod +x ~/bin/cipherlist.sh
#
# Run it against the domain/IP and port you want to check (assumes port 443 if no port is specified)
#
# cipherlist.sh -h
#
# Usage: cipherlist.sh [-p port1,port2,...] host1 [host2] [host3] ...
#  -p ... Comma separated list of port numbers to test
#  -q ... Quiet, do not print progress
#  -h ... Print this help and quit
# Example: cipherlist.sh -p443,465,2087 domain1.com ip.ad.dre.ss
# 
# 

# Set starting defaults
tempfile="/tmp/cipherlist.tmp";
PORTS="443"; quiet=''

#Help output function
usage(){
  echo "
Usage: $0 [-p port1,port2,...] host1 [host2] [host3] ...
  -p ... Comma separated list of port numbers to test
  -q ... Quiet, do not print progress

  -h ... Print this help and quit

  Example:
  $0 -p443,465,2087 domain1.com ip.ad.dre.ss
"
}

#Argument parsing
while getopts p:qh option; do
  case "${option}" in
    p ) PORTS=$(echo ${OPTARG} | sed 's/,/ /g'); shift ;;
    q ) quiet=1 ;;
    h|* ) usage; exit ;; # print help info
  esac
done

if [[ ! $@ ]]; then usage; exit; fi

#Outer loop over ports and hosts
for DOMAIN in "$@"; do
  for PORT in $PORTS; do

    # Initialize counter, and create tempfile
    i=0; echo -n > $tempfile; echo

    #Check port number for starttls requirements
    case $PORT in
      21) opt="-starttls ftp";;
      25|26|587) opt="-starttls smtp";;
      110) opt="-starttls pop3";;
      143) opt="-starttls imap";;
      *) opt="";;
    esac


    #Check OpenSSL version in use, and set protocol version list
    if [[ $(openssl version) =~ 0\.9\.[0-9] ]]; then #v0.9.x -- OLD
      PROTO="ssl2 ssl3 tls1";
    elif [[ $(openssl version) =~ 1\.[1-9]\.[1-9] ]]; then #1.1.x -- NEW
      PROTO="ssl2 ssl3 tls1 tls1_1 tls1_2 tls1_3";
    else
      PROTO="ssl2 ssl3 tls1 tls1_1 tls1_2"; #1.0.x -- CURRENT
    fi

    #Inner loop over protocols
    for v in $PROTO; do

        # Pretty up the version output
        case $v in
          ssl2) V="SSLv2.0";;
          ssl3) V="SSLv3.0";;
          tls1) V="TLSv1.0";;
          tls1_1) V="TLSv1.1";;
          tls1_2) V="TLSv1.2";;
          tls1_3) V="TLSv1.3";;
        esac

        # Loop over cipher list
        for c in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do
          if [[ ! $quiet ]]; then echo -ne " $V :: $c                    \r"; fi
          (echo | openssl s_client $opt -connect $DOMAIN:$PORT -cipher $c -$v 2>/dev/null | awk '/Cipher.*:/ && !/0000/ {print "|      "$NF}' >> ${tempfile}.$v &)
          i=$(($i+1))
        done;

        # Combine logs into final output
        if [[ -s ${tempfile}.$v ]]; then
          echo -e "|  $V:\n|    ciphers:" >> $tempfile;
          cat ${tempfile}.$v | sort -r | uniq >> $tempfile;
          rm -f ${tempfile}.$v;
        fi

    done

    #Gather host/domain/service information, and output results
    if [[ $DOMAIN =~ [a-z] ]]; then I=$(dig +short $DOMAIN | grep -v [a-z] | head -1); else I=$DOMAIN; fi
    rdns=$(dig +short -x $I | head -1)
    srv=$(awk "/ $PORT\/tcp/ || /\t$PORT\/tcp/"'{print $2,"("$1")"}' /etc/services)

    echo -e "Scan report for $DOMAIN ($I)                                        "
    if [[ -n $rdns ]]; then echo "rDNS for ($I): $rdns"; fi
    echo "$srv"

    cat $tempfile; echo -e "|_\n"

    echo -e "Done: ($i) Ciphers Tested :: ($( grep -E '-' $tempfile | wc -l )) Ciphers Supported\nUsing: $(openssl version)"
    rm -f $tempfile;

  done #end port loop
done #end host loop
echo
