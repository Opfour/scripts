#!/bin/bash
#							   +----+----+----+----+
# 							   |    |    |    |    |
# Author: Mark David Scott Cunningham			   | M  | D  | S  | C  |
# 							   +----+----+----+----+
# Created: 2014-03-20
# Updated: 2017-06-28
#
#
# Purpose: Quick DNS Summary for domain to confirm server/mail/rdns/ns/etc

dash (){ for ((i=1; i<=$1; i++)); do printf "-"; done; }
OPTS="+time=2 +tries=2 +short +noshort"
OPTS2="+time=2 +tries=2 +short"
localns=$(awk '/nameserver/ {print $2}' /etc/resolv.conf | head -1)
all=''
fullwhois=''
nameserver=''
verbose=''

# Argument parsing with getopt
OPTIONS=$(getopt -o "an:vwh" -- "$@")
eval set -- "$OPTIONS"
while true; do
  case $1 in
    -a) all=1 ;;
    -n) nameserver=$(echo $2 | sed "s/^\(.\)/@\1/g;s/,/ @/g"); shift ;;
    -v) verbose=1 ;;
    -w) fullwhois=1 ;;
    --) shift; break ;;
    -h) echo -e "\n  Usage: $0 [options] [arguments]
    -a ... Check DNS records at default list of resolvers
    -n ... <ns1,ns2,ns3...> to use for DNS records lookups
    -v ... Lookup DNS records and Whois Nameservers/Registrar
    -w ... Provide a whois summary instead of DNS records
    -h ... Print this help and quit\n
  Examples:\n
  DNS Summary with additional WHOIS information
    $0 -v <dom1>\n
  DNS Summary from specified resolver for multiple domains
    $0 -n 8.8.8.8,4.2.2.2 <dom1> <dom2>\n
  WHOIS Summary for multiple domains
    $0 -w <dom1> <dom2>\n"; exit ;;
  esac;
  shift;
done;

# Prompt for input if none provided
if [[ -z "$@" ]]; then
  read -p "Domain Name: " D;
else
  D="$@";
fi;

# Clean up inputs and start loop
for domain in $(echo $D | sed 's/\///g;s/http://g;s/https://g'); do
  echo -e "\nDNS Summary: ${domain}\nIntoDNS: http://www.intodns.com/${domain}\nWhatsMyDNS: https://www.whatsmydns.net/#A/${domain}\nGeoPeeker: https://geopeeker.com/fetch/?url=${domain}"

if [[ ! $fullwhois ]]; then
  # Attempt to check whois for nameservers and registrar if verbose
  if [[ $verbose ]]; then
    echo -ne "Whois-NS: ...working...\r"
    if [[ $domain =~ \.edu$ ]]; then
      echo -ne "Whois-NS: "; whois $domain  | tr -d '\r' | awk '/.ame.?.erver.?/,/^$/ {print}' | tail -n+2 | awk '{printf $1" "}'; echo
    else
      whois $domain | tr -d '\r' | awk 'BEGIN{printf "Whois-NS: "}; ($NF !~ /.ervers?:/) && /.ame.?.erver|DNS:/{printf $NF" "}; /egistrar:/ {registrar=$0}; END{printf "\n%s\n",registrar}'
    fi
  fi

  # Use predefined list of resolvers for lookups (all option)
  if [[ $all ]]; then
    nameserver="@$localns @google-public-dns-a.google.com @ns1.liquidweb.com";
    # Check resolvers listed as nameservers in DNS except ns/ns1.liquidweb.com
    if [[ -n $(dig ns $OPTS $domain | grep -Ev 'liquidweb.com|sourcedns.com') ]]; then
      nameserver+=" @$(dig ns $OPTS2 $domain | sort | head -1)"
      nameserver+=" @$(dig ns $OPTS2 $domain | sort | tail -1)"
    fi
  fi

  # Use locally defined resolver if none specified
  if [[ ! $nameserver ]]; then nameserver=$localns; fi

  for resolver in $nameserver; do
    # Print dividers between headers and dns results
    if [[ ! $nameserver == $localns ]]; then
      echo -e "\n$(dash 80)\nDNS Records from :: $resolver\n$(dash 60)";
    else
      echo -e "$(dash 80)";
    fi

    # Loop through DNS record lookups
    for record in a aaaa ns mx txt soa; do
      if [[ $record == 'ns' || $record == 'mx' ]]; then
        dig $OPTS $record $domain $resolver | grep -v root \
        | while read result; do echo "$result -> "$(dig +short $(echo $result | awk '{print $NF}') $resolver); done | sort -k5
      else
        dig $OPTS $record $domain $resolver
      fi
    done;

  if [[ $verbose ]]; then
    # Check for default DKIM records
    dig $OPTS txt default._domainkey.$domain $resolver | grep 'TXT'
    dig $OPTS txt _dmarc.$domain $resolver | grep 'TXT'

    # Lookup SRV records for live.com
    for SRV in '_sip._tls' '_sipfederationtls._tcp'; do
      dig $OPTS srv $SRV.$domain $resolver | grep 'SRV'
    done;
  fi

    # Lookup rDNS/PTR for the IP
    dig $OPTS -x $(dig $OPTS2 $domain) $resolver 2>/dev/null | grep -v '^;;'
  done;

else
  echo -e "$(dash 80)";
  whois $domain | tr -d '\r' | grep -Ei 'Name.?Server:|DNS:|Registrar:|Status:|Expir.*:|Updated';
fi

done;
echo;
