#! /bin/bash

v_VERSION="0.6.2"

#################
### Functions ###
#################

function fn_check_ip_range {
   ### This function expects $1 to be the IP address, $2 to be the input file and $3 to be the output file.
   ### Convert IP to binary
   v_CHECK_IP="$1"
   ### Create an array fo all binary numbers 0 through 255
   D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1});
   v_CHECK_IPBIN=$( for i in $(echo ${v_CHECK_IP} | tr '.' ' '); do echo ${D2B[$i]}; done |tr -d "\n" | sed "s/^0*//" )
   v_ZEROS="00000000000000000000000000000000"
   v_ONES="11111111111111111111111111111111"
   if [[ -f "$2" ]]; then
      ### This specifically tosses out ip_address/netmask style ranges such as 10.30.6.0/255.255.255.0
      for v_IPCIDR in $( sed "s/#.*$//" "$2" | egrep -v "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+\.[0-9]+" | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+" ); do
         v_IP=$( echo $v_IPCIDR | cut -d"/" -f1 )
         v_BITS=$( echo $v_IPCIDR | cut -d"/" -f2 )
         v_BITSr=$(( 32 - $v_BITS ))
         v_IPBIN=$( for i in $(echo ${v_IP} | tr '.' ' '); do echo ${D2B[$i]}; done |tr -d "\n" )
         v_IPBIN_LOWEST=$( echo ${v_IPBIN:0:$v_BITS}${v_ZEROS:0:$v_BITSr} | sed "s/^0*//" )
         v_IPBIN_HIGHEST=$( echo ${v_IPBIN:0:$v_BITS}${v_ONES:0:$v_BITSr} | sed "s/^0*//" )
         if [[ $v_CHECK_IPBIN -ge $v_IPBIN_LOWEST && $v_CHECK_IPBIN -le $v_IPBIN_HIGHEST ]]; then
            echo $v_IPCIDR >> "$3"
         fi
      done
      ### And this specifically only takes ranges in ip_address/netmask format
      for v_IPNETMASK in $( sed "s/#.*$//" "$2" | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" ); do
         v_IP=$( echo $v_IPNETMASK | cut -d"/" -f1 )
         v_MASK=$( echo $v_IPNETMASK | cut -d"/" -f2 )
         v_MASK=$( for i in $(echo ${v_MASK} | tr '.' ' '); do echo ${D2B[$i]}; done |tr -d "\n" )
         v_BITS=$( echo $v_MASK | grep -o "1" | wc -l )
         v_BITSr=$(( 32 - $v_BITS ))
         v_IPBIN=$( for i in $(echo ${v_IP} | tr '.' ' '); do echo ${D2B[$i]}; done |tr -d "\n" )
         v_IPBIN_LOWEST=$( echo ${v_IPBIN:0:$v_BITS}${v_ZEROS:0:$v_BITSr} | sed "s/^0*//" )
         v_IPBIN_HIGHEST=$( echo ${v_IPBIN:0:$v_BITS}${v_ONES:0:$v_BITSr} | sed "s/^0*//" )
         if [[ $v_CHECK_IPBIN -ge $v_IPBIN_LOWEST && $v_CHECK_IPBIN -le $v_IPBIN_HIGHEST ]]; then
            echo $v_IPNETMASK >> "$3"
         fi
      done
   fi
}

function fn_check_ip {
   ### This function expects $1 to be a IPv4 IP address. It will check if that IP address is in any of the allow or deny lists within apf, including if it is within CIDR ranges.
   v_CHECK_IP="$1"
   ### Find where APF is installed.
   if [[ -d /etc/apf ]]; then
      f_ALLOW="/etc/apf/allow_hosts.rules"
      f_DENY="/etc/apf/deny_hosts.rules"
   elif [[ -d /etc/apf-firewall ]]; then
      f_ALLOW="/etc/apf-firewall/allow_hosts.rules"
      f_DENY="/etc/apf-firewall/deny_hosts.rules"
   else
      exit
   fi
   f_LOG="/var/log/bfd_log"
   if [[ ! -f "$f_ALLOW" || -z $( which apf ) ]]; then
      exit
   fi
   ### If the ip address isn't IPv4, then it must be IPv6, which APF doesn't support.
   if [[ $( echo "$v_CHECK_IP" | egrep -c "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" ) -eq 0 ]]; then
      echo -e "$v_RED""* Address provided is IPv6, which is not supported by APF. This is *probably* not a problem.""$v_WHITE"
      v_CHECK_CLEAR=false
   else
      f_ALLOW_TMP="$(mktemp)"
      ### If the IP address that we're looking for is in the allow list, put it in a temporary file.
      sed "s/#.*$//" "$f_ALLOW" | grep -v "/" | grep $v_CHECK_IP >> "$f_ALLOW_TMP"
      if [[ -n "$f_DENY" ]]; then
         f_DENY_TMP="$(mktemp)"
         f_LOG_TMP="$(mktemp)"
         ### Same with the deny list.
         sed "s/#.*$//" "$f_DENY" | grep -v "/" | grep $v_CHECK_IP >> "$f_DENY_TMP"
      fi
      ### Convert cidr ranges in allow list to binary, and check if the ip we're searching for falls within them
      fn_check_ip_range "$v_CHECK_IP" "$f_ALLOW" "$f_ALLOW_TMP"
      ### Convert cidr ranges in deny list to binary, and check if the ip we're searching for falls within them
      if [[ -n "$f_DENY" ]]; then
         fn_check_ip_range "$v_CHECK_IP" "$f_DENY" "$f_DENY_TMP"
         ### Grab any relevant log entries
         v_FOUND="$( cat "$f_ALLOW_TMP" "$f_DENY_TMP" | tr "\n" "|" | sed "s/|$//" )"
         if [[ -n "$v_FOUND" && -f "$f_LOG" ]]; then
            egrep "$v_FOUND" "$f_LOG" >> "$f_LOG_TMP"
         fi
      fi
      ### Output what we've found
      if [[ -n "$f_DENY" ]]; then
         if [[ $( cat "$f_ALLOW_TMP" | wc -l ) -gt 0 ]]; then
            echo "The following IP's / ranges were ALLOWED in $f_ALLOW:"
            cat "$f_ALLOW_TMP" | sed "s/^/     ALLOWED: /"
         fi
         if [[ $( cat "$f_DENY_TMP" | wc -l ) -gt 0 ]]; then
            echo "The following IP's / ranges were BLOCKED in $f_DENY:"
            cat "$f_DENY_TMP" | sed "s/^/     BLOCKED: /"
         fi
         if [[ $( cat "$f_LOG_TMP" | wc -l ) -gt 0 ]]; then
            echo "The following log entries were found regarding the above IP's / ranges:"
            cat "$f_LOG_TMP" | sed "s/^/     /"
         fi
         if [[ $( cat "$f_ALLOW_TMP" "$f_DENY_TMP" "$f_LOG_TMP" | wc -l ) -eq 0 ]]; then
            echo "No Matches Found."
         fi
      else
         if [[ $( cat "$f_ALLOW_TMP" | wc -l ) -gt 0 ]]; then
            echo "The following IP's / ranges from the list, matched IP $v_CHECK_IP:"
            cat "$f_ALLOW_TMP" | sed "s/^/     /"
         else
            echo "No Matches Found."
         fi
      fi
      
      rm -f "$f_ALLOW_TMP" "$f_DENY_TMP" "$f_LOG_TMP"
   fi
}

function fn_compare_version {
   ### Check to see if a newer version of the script is available; report if that's the case
   v_REMOTE_VERSION="$( wget -q --timeout=10 -O "/dev/stdout" http://layer3.liquidweb.com/acwilliams/mail_info.sh | head -n 10 | egrep "^v_VERSION" | cut -d "\"" -f2 )"
   if [[ -n "$v_REMOTE_VERSION" ]]; then
      if [[ $( echo "$v_REMOTE_VERSION" | cut -d "." -f1 ) -gt $( echo "$v_VERSION" | cut -d "." -f1 ) ]]; then
         v_UPDATE=true
      elif [[ $( echo "$v_REMOTE_VERSION" | cut -d "." -f1 ) -eq $( echo "$v_VERSION" | cut -d "." -f1 ) && $( echo "$v_REMOTE_VERSION" | cut -d "." -f2 ) -gt $( echo "$v_VERSION" | cut -d "." -f2 ) ]]; then
         v_UPDATE=true
      elif [[ $( echo "$v_REMOTE_VERSION" | cut -d "." -f1 ) -eq $( echo "$v_VERSION" | cut -d "." -f1 ) && $( echo "$v_REMOTE_VERSION" | cut -d "." -f2 ) -eq $( echo "$v_VERSION" | cut -d "." -f2 ) && $( echo "$v_REMOTE_VERSION" | cut -d "." -f3 ) -gt $( echo "$v_VERSION" | cut -d "." -f3 ) ]]; then
         v_UPDATE=true
      fi
      if [[ $v_UPDATE == true ]]; then
         echo
         echo -e "\e[1;31mThere is a newer version of mail_info.sh available at http://layer3.liquidweb.com/acwilliams/mail_info.sh\e[00m"
         echo
      fi
   fi
}

function fn_digicert_results {
   ### This function automates the checking for SSL issues at digicert.
   if [[ ( $v_CHECK_993 != false && $v_CHECK_PORT == 993 ) || ( $v_CHECK_995 != false && $v_CHECK_PORT == 995 ) ]]; then
      v_DIGICERT_CHECK="$( curl -s -L 'https://www.digicert.com/api/check-host.php' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36' --data 'host='"$v_CHECK_HOST:$v_CHECK_PORT" | tr "\n" " " )"
      echo
      echo "Checking errors regarding the ssl on $v_CHECK_HOST on port $v_CHECK_PORT:"
      if [[ $( echo "$v_DIGICERT_CHECK" | grep -c "h2 class=" ) -gt 0 && $( echo "$v_DIGICERT_CHECK" | sed "s/<h2/\n\n<h2/g" | egrep "<h2 class=\"(warning|error)\"" | wc -l ) -gt 0 ]]; then
         echo -en "$v_RED"
         echo "$v_DIGICERT_CHECK" | sed "s/<h2/\n\n<h2/g" | egrep "<h2 class=\"(warning|error)\"" | sed "s/<[^>]*>/ /g;s/^ SSL Certificate/* The SSL Certificate/;s/^ /* /"
         echo -en "$v_WHITE"
      elif [[ $( echo "$v_DIGICERT_CHECK" | grep -c "h2 class=" ) -gt 0 ]]; then
         echo -e "$v_BLUE""...did not detect any issues.""$v_WHITE"
      else
         ### If the result of the curl does not contain "h2 class=", then it probably failed, but honeslty I have nothing to test against.
         v_CERT_CHECK=false
         echo -e "$v_RED""* Unable to connect to digicert to check the certificate. This will need to be done manually.""$v_WHITE"
      fi
   fi
}

function fn_version {
echo "Current Version: $v_VERSION"
cat << 'EOF' > /dev/stdout

Version Notes:
Future Versions -
     Better testing to ensure that the script is as robust as I want it to be.

0.6.2 (2016-03-02) -
     Some of our kicks don't include "bc" - figured out how to convert IP's to binary without. (Thanks JDebeer)

0.6.1 (2016-03-02) -
     If ports 993 and 995 aren't open, or nothing is listening to them, it won't attempt to check the SSL on these ports.
     Added the "--details" flag to help users have a better understanding of what is being checked for.

0.6.0 (2016-02-29) -
     Fixed an issue where the script was erroring out when no IP address was provided.
     Added checking for SSL certificates by curling dgicert

0.5.5 (2015-02-28) -
     Fixed an issue where one variable name was being used under two different circumstances, thus muddling up results.
     Fixed an issue where the hosts files were not being checked appropriately if they contained only comments. 

0.5.4 (2015-02-15) -
     Fixed an instance where double parenthesis were used rather than single. (Thanks MShooltz)

0.5.3 (2015-12-23) -
     The script now checks for a newer version of itself and lets the user know if one is available.

0.5.2 (2015-12-07) -
     Was checking port 578 rather than 587. Fix'd.
     Added in a function to allow "csf -g" style functionality for apf.
     The script checks for the IP being blocked in the software firewall.
     Checks for the IP in the cphulk logs, as well as in the /etc/hosts.allow and deny files.
     Output is now colorized.

0.5.1 (2015-11-25) -
     Also checks hostname DNS.

0.5.0 (2015-11-25) -
     Original version.

EOF
#'do
exit
}

function fn_help {
cat << 'EOF' > /dev/stdout

./mail_info.sh --help
./mail_info.sh -h
     Prints this text.

./mail_info.sh --version
./mail_info.sh -v
     Gives version and changelog information

./mail_info.sh --details
     Gives specific details on the things that this script is checking for.

./mail_info.sh --check-ip [ip address]
     Checks if an IP address is denied in APF, or is within a range that is denied in APF. (This functions similarly to "csf -g")

./mail_info.sh --check-ip-range [ip address] [file]
     Checks if an IP address is present in a range within a given file. The range can be either cidr notation, or netmask notation.

EOF
#'do
exit
}

function fn_details {
cat << 'EOF' > /dev/stdout

What does mail_info.sh check for?

* What is the version of cPanel, and should it be upgraded?
* Is the server running Courier or Dovecot?
* What ports are exim, dovecot, and courier listening on?
   * Are those the correct ports?
   * Are those ports open in APF or CSF?
* Does the email user exist in the cPanel users etc/passwd and etc/shadow file?
* Does the mail directory for that user exist?
* Is the mail directory for that user appropriately symlinked?
* Is DNS appropriately configured to route mail to this server (or mailsecure)?
* Does the hostname of the server have an IP address?
* Is the IP address that they're trying to access from explicitly blocked in CSF or APF?
* Is the IP address that they're trying to access from blocked in the hosts files?
* Is the IP address that they're trying to access from blocked within a range in CSF or APF or the hosts files?
* Is the IP address that they're trying to access from mentioned recently in the lfd, bfd, or cphulk logs?
* What issues (if any) does digicert's SSL checker see for ports 993 and 995?
   * For the server's hostname
   * For domain.tld (if mentioned in dovecot's sni.conf file)
   * For mail.domain.tld (if mentioned in dovecot's sni.conf file)
   * For the domain specified in the mx record (if mentioned in dovecot's sni.conf file, and different from both of the above)

EOF
#'do
exit
}

#####################
### End Functions ###
#####################

fn_compare_version

v_BLUE="\e[1;34m"
v_RED="\e[1;31m"
v_WHITE="\e[00m"

if [[ "$1" == "--version" || "$1" == "-v" ]]; then
   fn_version
elif [[ "$1" == "--check-ip" && -n "$2" ]]; then
   fn_check_ip "$2"
   exit
elif [[ "$1" == "--check-ip-range" && -n "$2" && -n "$3" ]]; then
   if [[ -z "$4" ]]; then
      v_OUTPUT="/dev/stdout"
   else
      v_OUTPUT="$4"
   fi
   fn_check_ip_range "$2" "$3" "$v_OUTPUT"
   exit
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
   fn_help
   exit
elif [[ "$1" == "--details" ]]; then
   fn_details
   exit
fi

### What email address are they having problems with?
echo
read -p "What is the email adress the customer is trying to connect to? (or hit enter if you don't have this information yet) " v_EMAIL_ADDRESS
echo
if [[ -n $v_EMAIL_ADDRESS && $( echo "$v_EMAIL_ADDRESS" | egrep -c "..*@..*\...*" ) -gt 0 ]]; then
   v_DOMAIN="$( echo $v_EMAIL_ADDRESS | sed "s/^.*:\/\///;s/^.*@//;s/^\([^/]*\)\/.*$/\1/" )"
   v_USER="$( echo "$v_EMAIL_ADDRESS" | sed "s/@$v_DOMAIN//" )"
   v_ACCOUNT="$( /scripts/whoowns $v_DOMAIN )"
   if [[ -z $v_ACCOUNT ]]; then
      echo -e "$v_RED""* $v_DOMAIN does not appear to be a domain owned by an account on this server.""$v_WHITE"
      exit
   fi
   v_HOMEDIR="$( egrep "^$v_ACCOUNT:" /etc/passwd | cut -d ":" -f6 )"
elif [[ -n $v_EMAIL_ADDRESS ]]; then
   echo "The address you specified doesn't appear to be in \"user@domain.tld\" format. Exiting."
   exit
elif [[ -z $v_EMAIL_ADDRESS ]]; then
   echo -e "$v_RED""*** Don't forget to re-run this script once you know the email address they're trying to connect to ***""$v_WHITE"
fi

read -p "What is the IP address that they are connecting from? (or hit enter if you don't have this information yet) " v_IP_ADDRESS
echo
if [[ -n $v_IP_ADDRESS && $( echo "$v_IP_ADDRESS" | egrep -c "^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[^[:blank:]]*:[^[:blank:]]*)$" ) -eq 0 ]]; then
   echo "The IP address you specified doesn't appear to be in the correct format. Exiting."
   exit
elif [[ -z $v_IP_ADDRESS ]]; then
   echo -e "$v_RED""*** Don't forget to re-run this script once you know the IP address they'er trying to connect from ***""$v_WHITE"
fi

### Is their version of cPanel outdated:
echo "Checking cPanel and mailserver..."
### As of 11.54, cPanle has changed the output of this script so that it no longer shows the major version. This complicates things, but shouldn't be an issue for the immediate future, so long as we just check whether the version number starts with "11" or not.
v_CHECK_CLEAR=true
v_CPANEL_VERSION="$( /usr/local/cpanel/cpanel -V | cut -d " " -f1 )"
if [[ $( echo "$v_CPANEL_VERSION" | cut -d "." -f1 ) -lt 11 ]]; then
   echo -e "$v_RED""* Version of cPanel is older than version 11. This is actually pretty scary.""$v_WHITE"
   v_CHECK_CLEAR=false
elif [[ $( echo "$v_CPANEL_VERSION" | cut -d "." -f1 ) -eq 11 && $( echo "$v_CPANEL_VERSION" | cut -d "." -f2 ) -lt 34 ]]; then
   echo -e "$v_RED""* Version of cPanel is older than 11.34. An upgrade is recommended""$v_WHITE"
   v_CHECK_CLEAR=false
elif [[ $( echo "$v_CPANEL_VERSION" | cut -d "." -f1 ) -eq 11 && $( echo "$v_CPANEL_VERSION" | cut -d "." -f2 ) -gt 34 && $( echo "$v_CPANEL_VERSION" | cut -d "." -f2 ) -le 52 ]]; then
   echo -e "$v_RED""* Version of cPanel is between 11.34 and 11.52. This should be upgraded, but is probably okay.""$v_WHITE"
fi

### Is the server using Courier or Dovecot?
if [[ $( netstat -lpn | egrep -c "^tcp.*/dovecot(/.*)*[[:blank:]]*$" ) -gt 0 ]]; then
   v_IS_DOVECOT=true
fi
if [[ $( netstat -lpn | egrep -c "^tcp.*/couriertcpd[[:blank:]]*$" ) -gt 0 ]]; then
   v_IS_COURIER=true
   if [[ $v_IS_DOVECOT == true ]]; then
      echo -e "$v_RED""* Server appears to have both Courier and Deovecot listening on ports. This is not right and needs to be investigated further.""$v_WHITE"
      exit
   fi
   echo -e "$v_RED""* This server is running Courier. cPanel discontinued Courier as an option starting in version 11.54. It is highly recommended that the server be switched to Dovecot.""$v_WHITE"
   v_CHECK_CLEAR=false
fi
if [[ -z $v_IS_COURIER && -z $v_IS_DOVECOT ]]; then
   echo -e "$v_RED""* The server appears to be running neither Courier nor Dovecot. Without one of these, clients will not be able to connect.""$v_WHITE"
   exit
fi

if [[ $v_CHECK_CLEAR == true ]]; then
   echo -e "$v_BLUE""...did not detect any issues.""$v_WHITE"
fi

### Start building a list of ports to check in the firewall.
v_PORTS_OUT="$( netstat -lpn | grep "^tcp.*/exim[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep "." | sort -n | uniq | tr "\n" " " )"
v_PORTS_IN="$( netstat -lpn | egrep "^tcp.*/(dovecot|exim|couriertcpd)(/.*)*[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep "." | sort -n | uniq | tr "\n" " " ) 2095 2096"

### The SSL will be checked on these ports, unless these values are later changed to false.
v_CHECK_993=true
v_CHECK_995=true

echo "Checking processes and ports..."
v_CHECK_CLEAR=true
### Are there any ports that should be listened to, but are not?
for i in 25 26 465 587; do
   if [[ $( netstat -lpn | egrep "^tcp.*/exim[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep -c "^$i$" ) -lt 1 ]]; then
      echo -e "$v_RED""* Exim is not listening on port $i.""$v_WHITE"
      v_CHECK_CLEAR=false
   fi  
done
for i in 110 143 993 995; do
   if [[ $( netstat -lpn | egrep "^tcp.*/(dovecot|couriertcpd)(/.*)*[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep -c "^$i$" ) -lt 1 ]]; then
      if [[ $v_IS_COURIER == true ]]; then
         echo -e "$v_RED""* Courier is not listening on port $i.""$v_WHITE"
         v_CHECK_CLEAR=false
      elif [[ $v_IS_DOVECOT == true ]]; then
         echo -e "$v_RED""* Dovecot is not listening on port $i.""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
      if [[ $i == 993 ]]; then
         v_CHECK_993=false
      elif [[ $i == 995 ]]; then
         v_CHECK_995=false
      fi
   fi  
done
for i in 2095 2096; do
   if [[ $( netstat -lpn | egrep "^tcp.*/cpsrvd.*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep -c "^$i$" ) -lt 1 ]]; then
      echo -e "$v_RED""* Webmail is not listening on port $i.""$v_WHITE"
      v_CHECK_CLEAR=false
   fi  
done

### What ports are open in the software firewall?
if [[ -n $( type -path -a csf ) ]]; then
   v_IS_CSF=true
   for i in $v_PORTS_IN; do
      if [[ $( grep "^TCP_IN" /etc/csf/csf.conf | cut -d "\"" -f2 | tr "," "\n" | grep -c "^$i$" ) -lt 1 ]]; then
         echo -e "$v_RED""* Port $i TCP is not open incoming in /etc/csf/csf.conf""$v_WHITE"
         v_CHECK_CLEAR=false
         if [[ $i == 993 ]]; then
            v_CHECK_993=false
         elif [[ $i == 995 ]]; then
            v_CHECK_995=false
         fi
      fi
   done
   for i in $v_PORTS_OUT; do
      if [[ $( grep "^TCP_OUT" /etc/csf/csf.conf | cut -d "\"" -f2 | tr "," "\n" | grep -c "^$i$" ) -lt 1 ]]; then
         echo -e "$v_RED""* Port $i TCP is not open outgoing in /etc/csf/csf.conf""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
   done
fi
if [[ -n $( type -path -a apf ) ]]; then
   v_IS_APF=true
   if [[ $v_IS_CSF == true ]]; then
      echo -e "$v_RED""* APF and CSF Both installed. This is a problem and needs to be resolve before the script can go forward.""$v_WHITE"
      exit
   fi
   for i in $v_PORTS_IN; do
      if [[ $( grep "^IG_TCP_CPORTS" /etc/apf/conf.apf | cut -d "\"" -f2 | tr "," "\n" | grep -c "^$i$" ) -lt 1 ]]; then
         echo -e "$v_RED""* Port $i TCP is not open incoming in /etc/apf/conf.apf""$v_WHITE"
         v_CHECK_CLEAR=false
         if [[ $i == 993 ]]; then
            v_CHECK_993=false
         elif [[ $i == 995 ]]; then
            v_CHECK_995=false
         fi
      fi
   done
   for i in $v_PORTS_OUT; do
      if [[ $( grep "^EG_TCP_CPORTS" /etc/apf/conf.apf | cut -d "\"" -f2 | tr "," "\n" | grep -c "^$i$" ) -lt 1 ]]; then
         echo -e "$v_RED""* Port $i TCP is not open outgoing in /etc/apf/conf.apf""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
   done
fi
if [[ -z $v_IS_APF && -z $v_IS_CSF ]]; then
   v_CHECK_CLEAR=false
   echo -e "$v_RED""* Neither APF nor CSF appear to be installed. Check IPTables manually to make sure that the following TCP Incoming ports are open:""$v_WHITE"
   echo "$v_PORTS_IN"
fi

if [[ $v_CHECK_CLEAR == true ]]; then
   echo -e "$v_BLUE""...did not detect any issues.""$v_WHITE"
fi

echo "Checking user files and DNS..."
v_CHECK_CLEAR=true
if [[ -n $v_ACCOUNT ]]; then
   ### Let's make sure that everything looks good for that account.
   if [[ $( grep -c "^$v_USER:" "$v_HOMEDIR/etc/$v_DOMAIN/passwd" ) -ne 1 ]]; then
      echo -e "$v_RED""* This user doesn't appear in \"$v_HOMEDIR/etc/$v_DOMAIN/passwd\".""$v_WHITE"
      v_CHECK_CLEAR=false
   fi
   if [[ $( grep -c "^$v_USER:" "$v_HOMEDIR/etc/$v_DOMAIN/shadow" ) -ne 1 ]]; then
      echo -e "$v_RED""* This user doesn't appear in \"$v_HOMEDIR/etc/$v_DOMAIN/shadow\".""$v_WHITE"
      v_CHECK_CLEAR=false
   fi
   if [[ ! -L "$v_HOMEDIR/mail/.$( echo $v_EMAIL_ADDRESS | sed "s/\./_/g" )" ]]; then
      echo -e "$v_RED""* Symlink \"$v_HOMEDIR/mail/.$( echo $v_EMAIL_ADDRESS | sed "s/\./_/g" )\" does not exist. This should be a link to \"$v_HOMEDIR/mail/$v_DOMAIN/$v_USER\".""$v_WHITE"
      echo "     (Does this user actually exist in cPanel?)"
      v_CHECK_CLEAR=false
   fi
   if [[ ! -d "$v_HOMEDIR/mail/$v_DOMAIN/$v_USER" ]]; then
      echo -e "$v_RED""* Directory \"$v_HOMEDIR/mail/$v_DOMAIN/$v_USER\" does not appear to exist.""$v_WHITE"
      echo "     (Does this user actually exist in cPanel?)"
      v_CHECK_CLEAR=false
   fi

   ### Does DNS Look Good?
   if [[ $( dig +short mx $v_DOMAIN | grep -c "bmx0..sourcedns.com" ) -gt 0 ]]; then
      echo "Note: Domain appears to be using mailsecure. Ensure that this is configured correctly."
   else
      v_DIG_IP_ADDRESS="$( dig +short mx $v_DOMAIN | sort -n | awk -v pref=65536 '($1<=pref) {pref=$1; print $2}' | dig +short -f - | uniq | head -n1 )"
      if [[ -z $v_DIG_IP_ADDRESS ]]; then
         echo -e "$v_RED""* Either the MX record or the A record that it's pointing to are incorrectly configured. Further investigation is required.""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
      if [[ $( ifconfig | grep "inet addr:" | awk '{print $2}' | cut -d ":" -f2 | grep -c "^$v_DIG_IP_ADDRESS$" ) -lt 1 ]]; then
         echo -e "$v_RED""* It doesn't apepar that the IP address associated with the MX record is pointed to the server.""$v_WHITE"
         echo "     (Double check this. Verifiy that their server doesn't have natted IP addresses.)"
         v_CHECK_CLEAR=false
      fi
      v_HOSTNAME_IP="$( dig +short $( hostname ) )"
      if [[ -z $v_HOSTNAME_IP ]]; then
         echo -e "$v_RED""* The hostname of the server doesn't appear to have an IP address.""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
   fi
fi

if [[ $v_CHECK_CLEAR == true ]]; then
   echo -e "$v_BLUE""...did not detect any issues.""$v_WHITE"
fi

if [[ -n $v_IP_ADDRESS ]]; then
   echo "Checking for the IP within the firewall and cphulk..."
   v_CHECK_CLEAR=true
   
   if [[ $v_IS_CSF == true ]]; then
      if [[ $( csf -g "$v_IP_ADDRESS" | grep -c "DROP.*$v_IP_ADDRESS" ) -gt 0 ]]; then
         echo -e "$v_RED""* The IP address appears to currently be blocked in CSF. This will need to be manually removed.""$v_WHITE"
         v_CHECK_CLEAR=false
      elif [[ $v_IS_CSF == true && $( grep -c "$v_IP_ADDRESS" /var/log/lfd.log ) -gt 0 ]]; then
         echo -e "$v_RED""* There are recent entries regarding this IP address in /var/log/lfd.log""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
   elif [[ $v_IS_APF == true ]]; then
      if [[ $( fn_check_ip $v_IP_ADDRESS | grep -c "BLOCKED: $v_IP_ADDRESS" ) -gt 0 ]]; then
         echo -e "$v_RED""* The IP address appears to currently be blocked in APF. This will need to be manually removed.""$v_WHITE"
         v_CHECK_CLEAR=false
      elif [[ $( fn_check_ip $v_IP_ADDRESS | egrep -c "BLOCKED: [0-9]+.[0-9]+.[0-9]+.[0-9]+/[0-9]+" ) -gt 0 ]]; then
         echo -e "$v_RED""* A range containing the IP address appears to currently be blocked in APF. This will need to be manually removed.""$v_WHITE"
         v_CHECK_CLEAR=false
      elif [[ $v_IS_APF == true && $( grep -c "$v_IP_ADDRESS" /var/log/bfd_log ) -gt 0 ]]; then
         echo -e "$v_RED""* There are recent entries regarding this IP address in /var/log/bfd_log""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
   fi

   if [[ $( ps aux | grep -i cphulk | grep -civ "grep" ) -gt 0 ]]; then
   ### cphulk is active
      if [[ $( egrep -c "\[Remote IP Address\]=\[$v_IP_ADDRESS\]" /usr/local/cpanel/logs/cphulkd.log ) -gt 0 ]]; then
         echo -e "$v_RED""* There are recent entries regarding this IP address in the cphulk logs.""$v_WHITE"
         v_CHECK_CLEAR=false
      fi
   fi
   ### Check the hosts.allow file for ranges
   v_HOSTS_ALLOW_RANGE=0
   for v_RANGE in $( fn_check_ip_range "$v_IP_ADDRESS" /etc/hosts.allow /dev/stdout ); do 
      v_HOSTS_ALLOW_RANGE=$(( $( grep $v_RANGE /etc/hosts.allow | grep -ci deny ) + $v_HOSTS_ALLOW_RANGE ))
   done
   if [[ $v_HOSTS_ALLOW_RANGE -gt 0 ]]; then
      echo -e "$v_RED""* There is a range being denied in /etc/hosts.allow that includes this IP address.""$v_WHITE"
      v_CHECK_CLEAR=false
   fi
   ### Check the hosts.deny file for ranges
   v_HOSTS_DENY_RANGE=0
   for v_RANGE in $( fn_check_ip_range "$v_IP_ADDRESS" /etc/hosts.deny /dev/stdout ); do 
      v_HOSTS_DENY_RANGE=$(( $( grep $v_RANGE /etc/hosts.allow | grep -ci deny ) + $v_HOSTS_DENY_RANGE ))
   done
   if [[ $v_HOSTS_DENY_RANGE -gt 0 ]]; then
      echo -e "$v_RED""* There is a range being denied in /etc/hosts.deny that includes this IP address.""$v_WHITE"
      v_CHECK_CLEAR=false
   fi
   ### Check both files for the IP address itself.
   if [[ $( cat /etc/hosts.deny /etc/hosts.allow | grep -ic "$v_IP_ADDRESS.*deny" ) -gt 0 ]]; then
      echo -e "$v_RED""* This IP address is being denied in either /etc/hosts.deny or /etc/hosts.allow.""$v_WHITE"
      v_CHECK_CLEAR=false
   fi

   if [[ $v_CHECK_CLEAR == true ]]; then
      echo -e "$v_BLUE""...did not detect any issues.""$v_WHITE"
   fi
fi

v_CERT_CHECK=true

### Check digicert for the server's hostname.
v_CHECK_PORT=993; v_CHECK_HOST="$( hostname )"
fn_digicert_results
v_CHECK_PORT=995; v_CHECK_HOST="$( hostname )"
fn_digicert_results
### If the domain is listed in dovecot's sni.conf, check digicert for the domain.
if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $( grep -c "local_name[[:blank:]]*$v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
   v_CHECK_PORT=993; v_CHECK_HOST="$v_DOMAIN"
   fn_digicert_results
   v_CHECK_PORT=995; v_CHECK_HOST="$v_DOMAIN"
   fn_digicert_results
fi
### if the mail. subdomain is in dovecot's sni.conf, check digicert for the mail. subdomain.
if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $( grep -c "local_name[[:blank:]]*mail.$v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
   v_CHECK_PORT=993; v_CHECK_HOST="mail.$v_DOMAIN"
   fn_digicert_results
   v_CHECK_PORT=995; v_CHECK_HOST="mail.$v_DOMAIN"
   fn_digicert_results
fi
### If the mx record is for something completely different, and that something is in the sni.conf, check digicert for that.
v_MX_DOMAIN="$( dig mx $v_DOMAIN +short | awk '{print $2}' | sed "s/.$//" )"
if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $v_MX_DOMAIN != "$v_DOMAIN" && $v_MX_DOAMIN != "mail.$v_DOMAIN" && $( grep -c "local_name[[:blank:]]*$v_MX_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
   v_CHECK_PORT=993; v_CHECK_HOST="$v_MX_DOMAIN"
   fn_digicert_results
   v_CHECK_PORT=995; v_CHECK_HOST="$v_MX_DOMAIN"
   fn_digicert_results
fi


echo
echo "Other things to investigate:"
echo "* Check if the server has an active Storm firewall."
echo "* Check if the server is behind a physical firewall or other network device."
if [[ $v_CERT_CHECK != true ]]; then
   ### If there were any issues with the automated digicert checks, prompt the user to do them manually.
   echo "* Navigate to the following URL's to check SSL's:"
   if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $( grep -c "local_name $v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
      echo "   * https://www.digicert.com/help/ (and search for \"$v_DOMAIN:993\")"
      echo "   * https://www.digicert.com/help/ (and search for \"$v_DOMAIN:995\")"
   fi
   if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $( grep -c "local_name mail.$v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
      echo "   * https://www.digicert.com/help/ (and search for \"mail.$v_DOMAIN:993\")"
      echo "   * https://www.digicert.com/help/ (and search for \"mail.$v_DOMAIN:995\")"
   fi
   echo "   * https://www.digicert.com/help/ (and search for \"$( hostname ):993\")"
   echo "   * https://www.digicert.com/help/ (and search for \"$( hostname ):995\")"
   echo "* At the above URL's, verify the following:"
   echo "   * Is the SSL self-signed?"
   echo "   * Is the SSL revoked?"
   echo "   * Does the SSL's common name or SANs match the hostname specified?"
   echo "   * Does the chain complete?"
   echo "   * Are there are any other errors?"
fi
echo "* In WHM > Service Configuration > Mailserver Configuration, is SSLv3 listed as a protocol?"
echo

### Let's find out more about the SSL
#if [[ $v_IS_DOVECOT == true ]]; then
#   if [[ $( grep -c "local_name $v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
#      v_CERT_FILE="$( grep -A3 "local_name $v_DOMAIN {" /etc/dovecot/sni.conf | grep "^[[:blank:]]*ssl_cert " | cut -d "<" -f2 )"
#   else
#      v_CERT_FILE="$( grep "^[[:blank:]]*ssl_cert " /etc/dovecot/dovecot.conf | cut -d "<" -f2 )"
#   fi
#elif [[ $v_IS_COURIER == true ]]; then
#   v_CERT_FILE="$( grep "^[[:blank:]]*TLS_CERTFILE" /usr/lib/courier-imap/etc/imapd-ssl | cut -d "=" -f2 )"
#fi


### Note: aerelon.liquidweb.com is running courier and CSF on cPanel 11.30.
### Note: 67.227.221.1 is running APF.
### Note: splendid.liquidweb.com is running dovecot.
