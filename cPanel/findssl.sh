#!/bin/bash
#							   +----+----+----+----+
# 							   |    |    |    |    |
# Author: Mark David Scott Cunningham			   | M  | D  | S  | C  |
# 							   +----+----+----+----+
# Created: 2014-03-29
# Updated: 2017-05-23
#
# Purpose: Test SSL connection and cert loading on a particular server and port

dash(){ for ((i=1; i<=$1; i++)); do printf "$2"; done; }

verbose=''
quiet=''
links=''
ip=''
P=443
I=''

OPTIONS=$(getopt -o "hi:lp:qv" -- "$@") # Execute getopt
eval set -- "$OPTIONS" # Magic
while true; do # Evaluate the options for their options
case $1 in
  -i ) I=$2; shift ;;
  -l ) links=1 ;;
  -q ) quiet=1 ;;
  -p ) P=$2; shift ;;
  -v ) verbose=1 ;;
  -- ) shift; break ;; # More Magic
  -h|* ) echo -e "\n  Usage: $0 [options] <dom1> <dom2> ...
    -i ... <ipaddress> for SSL connections
    -l ... Print just web links
    -q ... Hide web links
    -p ... <port> for SSL connections
    -v ... Verbose (Check revocation status with ocsp)
    -h ... Print this help and quit\n
  Examples:\n
  Check SSL loading for https (multiple domains)
    $0 <dom1> <dom2> <dom3> ...\n
  Check SSL for domain at specified port
    $0 -p <port> <domain>\n
  Check SSL for domain at specified IP address
    $0 -i <ipaddress> <domain>\n
  Print just web links (and just one checker service)
    $0 -l <dom1> <dom2> <dom3> | grep shopper\n"; exit;;
esac;
shift;
done

echo;
for domain in $@; do
  # Cleanup Domain input
  D=$(echo $domain | sed 's|^http:||g;s|https:||g;s|\/||g;');

  # If IP not specified lookup IP
  if [[ ! $I ]]; then I=$(dig +short $D | grep [0-9] | head -1); fi
  if [[ ! $D =~ [a-z] ]]; then I=$D; fi

  # Check if local version of OpenSSL has SNI support
  if [[ $(openssl version | awk '{print $2}') =~ ^1\. ]]; then SNI="-servername $D"; else SNI=''; fi

  # Add some TLS options if special ports are specified
  case $P in
    25|587) SNI="$SNI -starttls smtp" ;;
    21) SNI="$SNI -starttls ftp" ;;
    110) SNI="$SNI -starttls pop3" ;;
    143) SNI="$SNI -starttls imap" ;;
  esac

  # Print header
  echo "$(dash 80 =)"; echo "$D :: $I:$P"; echo "$(dash 80 -)";

  # Print SSL checker service URLs
  if [[ ! $quiet ]]; then
    echo "https://www.sslshopper.com/ssl-checker.html#hostname=$D:$P"
    echo "https://certlogik.com/ssl-checker/$D:$P"
    echo "https://www.ssllabs.com/ssltest/analyze.html?d=${D}&s=${I}&latest"
    echo
  fi

  # Print full output if not links mode
  if [[ ! $links ]]; then
    # Connect to the IP at port; get SSL; Decode SSL; clean up output and print
    echo | openssl s_client -connect $I:$P $SNI -showcerts 2>/dev/null| awk '/-----BEGIN/,/-----END/ {print}' > /tmp/fullchain.pem
      cat /tmp/fullchain.pem | openssl x509 > /tmp/$domain.pem

    openssl x509 -noout -text -in /tmp/$domain.pem | egrep -i 'subject:|dns:|issuer:'\
     | sed 's/DNS:/\nDNS:/;s/.*Subject: /\nSubject:\n/;s/.*Issuer: /Issuer:\n/;s/, Inc./ Inc./g;s/, /\n/g;s/[=:]/: /g;s/\/email/\nemail/g;s/\/busi/\nBusi/g;s/\/seri/\nSeri/g;s/\/1\.3\.6\./\n1\.3\.6\./g';
    echo
    echo | openssl s_client -connect $I:$P $SNI -cipher "EDH" 2>/dev/null | grep "Server Temp Key";
    openssl x509 -noout -text -in /tmp/$domain.pem | grep Signature.Algorithm | head -1 | sed 's/.*Sig/Sig/g'
    openssl x509 -noout -in /tmp/$domain.pem -dates | sed 's/notBefore=/Issued : /;s/notAfter=/Expires: /'
    echo;

    # If verbose mode, check OCSP for revocation status
    if [[ $verbose ]]; then
      linenum=$(grep -n BEGIN /tmp/fullchain.pem | awk -F: 'NR==2 {print $1}')
        tail -n +$linenum /tmp/fullchain.pem > /tmp/chain.pem

      echo -e "$(dash 40 =)\nChain Verification"
      echo | openssl s_client -connect $I:$P $SNI 2>&1 | grep -E 'depth|verify' | tac\
       | sed -r 's/(verify)/----------------------------------------\n\1/g;'

      echo -e "\n$(dash 40 =)\nRevocation Status\n$(dash 40 -)"
      ocspurl=$(openssl x509 -in /tmp/$domain.pem -noout -ocsp_uri)
      ocsphost=$(echo $ocspurl | cut -d/ -f3)
        echo -e "OCSP URL : $ocspurl\nOCSP HOST: $ocsphost"
      openssl ocsp -no_nonce -header host $ocsphost -issuer /tmp/chain.pem -cert /tmp/$domain.pem -url $ocspurl -CAfile /tmp/chain.pem 2>/dev/null
        echo
    fi

    # Check for common SSL issues, and their error messages.
    echo "SSL Return Code"; echo "$(dash 80 -)";
    rcode=$(echo | openssl s_client -connect $I:$P $SNI 2>/dev/null | grep Verify.*)
    echo $rcode
    if [[ $(echo $rcode | awk '{print $4}') =~ [0-9]{2} ]]; then
      curl -s https://www.openssl.org/docs/apps/verify.html | grep -A4 "$(echo $rcode | awk '{print $4}') X509" | grep -v X509 | sed 's/<[^>]*>//g' | tr '\n' ' '; echo;
    fi; echo

    #rm -f /tmp/fullchain.pem /tmp/$domain.pem /tmp/chain.pem
  fi
done
