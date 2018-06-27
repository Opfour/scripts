#! /bin/bash

v_VERSION="0.7.0"

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
      fn_text_out "* Address provided is IPv6, which is not supported by APF. This is *probably* not a problem." "$v_RED"
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
            fn_text_out "The following IP's / ranges were ALLOWED in $f_ALLOW:"
            cat "$f_ALLOW_TMP" | sed "s/^/     ALLOWED: /"
         fi
         if [[ $( cat "$f_DENY_TMP" | wc -l ) -gt 0 ]]; then
            fn_text_out "The following IP's / ranges were BLOCKED in $f_DENY:"
            cat "$f_DENY_TMP" | sed "s/^/     BLOCKED: /"
         fi
         if [[ $( cat "$f_LOG_TMP" | wc -l ) -gt 0 ]]; then
            fn_text_out "The following log entries were found regarding the above IP's / ranges:"
            cat "$f_LOG_TMP" | sed "s/^/     /"
         fi
         if [[ $( cat "$f_ALLOW_TMP" "$f_DENY_TMP" "$f_LOG_TMP" | wc -l ) -eq 0 ]]; then
            fn_text_out "No Matches Found."
         fi
      else
         if [[ $( cat "$f_ALLOW_TMP" | wc -l ) -gt 0 ]]; then
            fn_text_out "The following IP's / ranges from the list, matched IP $v_CHECK_IP:"
            cat "$f_ALLOW_TMP" | sed "s/^/     /"
         else
            fn_text_out "No Matches Found."
         fi
      fi
      
      rm -f "$f_ALLOW_TMP" "$f_DENY_TMP" "$f_LOG_TMP"
   fi
}

function fn_compare_version {
   ### Function Version 1.0.0
   ### "$1" is the remote URL of the script. "$2" is "run" if a newer version should be run automatically, "color" if we should alert the user in color, and "plain" if we should alert the user with plain text. "plain" is assumed if none of these values are set.
   ### The "run" functionality assumes that "${a_CL_ARGUMENTS[@]}" is populated with the command line arguments of the current run. It also assumes that the string "End of Script" is within the last 10 lines of the script.
   ### Check to see if a newer version of the script is available; report if that's the case.
   v_PROGRAMDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
   v_PROGRAMDIR="$( echo "$v_PROGRAMDIR" | sed "s/\([^/]\)$/\1\//" )"
   v_PROGRAMNAME="$( basename "${BASH_SOURCE[0]}" )"
   if [[ "$2" == "run" ]]; then
      timeout 5 wget -q --timeout=3 -O "$v_PROGRAMDIR""$v_PROGRAMNAME"1 "$1"
      v_REMOTE_VERSION="$( head -n 10 "$v_PROGRAMDIR""$v_PROGRAMNAME"1 2> /dev/null | egrep "^v_VERSION" | cut -d "\"" -f2 )"
   else
      v_REMOTE_VERSION="$( timeout 5 wget -q --timeout=2 -O "/dev/stdout" "$1" | head -n 10 | egrep "^v_VERSION" | cut -d "\"" -f2 )"
   fi
   if [[ -n "$v_REMOTE_VERSION" ]]; then
      if [[ ( "$2" == "run" && $( tail -n 10 "$v_PROGRAMDIR""$v_PROGRAMNAME"1 2> /dev/null | egrep -c "End of Script" ) -eq 1 ) || "$2" != "run" ]]; then
      ### If the version number is present and the last line of the script is present...
         if [[ $( echo "$v_REMOTE_VERSION" | cut -d "." -f1 ) -gt $( echo "$v_VERSION" | cut -d "." -f1 ) ]]; then
            v_UPDATE=true
         elif [[ $( echo "$v_REMOTE_VERSION" | cut -d "." -f1 ) -eq $( echo "$v_VERSION" | cut -d "." -f1 ) && $( echo "$v_REMOTE_VERSION" | cut -d "." -f2 ) -gt $( echo "$v_VERSION" | cut -d "." -f2 ) ]]; then
            v_UPDATE=true
         elif [[ $( echo "$v_REMOTE_VERSION" | cut -d "." -f1 ) -eq $( echo "$v_VERSION" | cut -d "." -f1 ) && $( echo "$v_REMOTE_VERSION" | cut -d "." -f2 ) -eq $( echo "$v_VERSION" | cut -d "." -f2 ) && $( echo "$v_REMOTE_VERSION" | cut -d "." -f3 ) -gt $( echo "$v_VERSION" | cut -d "." -f3 ) ]]; then
            v_UPDATE=true
         fi
         if [[ $v_UPDATE == true && "$2" == "run" ]]; then
            mv -f "$v_PROGRAMDIR""$v_PROGRAMNAME"1 "$v_PROGRAMDIR""$v_PROGRAMNAME"
            chmod +x "$v_PROGRAMDIR""$v_PROGRAMNAME"
            echo 
            echo "Downloaded a newer version of $v_PROGRAMNAME."
            echo
            "$v_PROGRAMDIR""$v_PROGRAMNAME" "${a_CL_ARGUMENTS[@]}" --no-version-check
            exit $?
         elif [[ $v_UPDATE == true && "$2" = "color" ]]; then
            echo
            echo -e "\e[1;31mThere is a newer version of $v_PROGRAMNAME available at $1""\e[00m"
            echo
         elif [[ $v_UPDATE == true ]]; then
            echo
            echo "--------There is a newer version of $v_PROGRAMNAME available at $1""--------"
            echo
         else
            rm -f "$v_PROGRAMDIR""$v_PROGRAMNAME"1
         fi
      fi
   fi
}

function fn_text_out {
   ### $1 is the text. If $2 is populated, it's the color that the text should be changed to.
   ### Output text both to the user, as well as to a text file.
   if [[ -z "$f_TEMP_RESULTS" ]]; then
      f_TEMP_RESULTS="mail_info_results_""$( date +%s )"".txt"
      touch "$f_TEMP_RESULTS"
   fi
   echo "$1" >> "$f_TEMP_RESULTS"
   if [[ "$2" != "--just-file" ]]; then
      echo -e "$2""$1""$v_WHITE"
   fi
}

function fn_send_results {
   if [[ -n "$f_TEMP_RESULTS" ]]; then
      cat "$f_TEMP_RESULTS" | mail -s "mail_info.sh results from $( hostname )" acwilliams@liquidweb.com
   fi
   exit
}

function fn_digicert_results {
   ### This function automates the checking for SSL issues at digicert.
   ### This is a bit of a lazy solution, but honestly, I have no idea what all of the items might be on a comprehensive list of things to check for. If we can pull info from digicert, it saves us a lot of time and ensures that we don't overlook potential issues.
   if [[ ( $v_CHECK_993 != false && $v_CHECK_PORT == 993 ) || ( $v_CHECK_995 != false && $v_CHECK_PORT == 995 ) ]]; then
      v_DIGICERT_CHECK="$( curl -s -L 'https://www.digicert.com/api/check-host.php' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36' --data 'host='"$v_CHECK_HOST:$v_CHECK_PORT" | tr "\n" " " )"
      fn_text_out
      fn_text_out "Checking errors regarding the ssl on $v_CHECK_HOST on port $v_CHECK_PORT:"
      fn_text_out "$( echo "$v_DIGICERT_CHECK" | sed "s/<h2/\n\n<h2/g" | sed "s/<[^>]*>/ /g;s/^ SSL Certificate/* The SSL Certificate/;s/^ /* /" )" "--just-file"
      fn_text_out "" "--just-file"
      fn_text_out "Data reported to the user for $v_CHECK_HOST on port $v_CHECK_PORT:" "--just-file"
      if [[ $( echo "$v_DIGICERT_CHECK" | grep -c "h2 class=" ) -gt 0 && $( echo "$v_DIGICERT_CHECK" | sed "s/<h2/\n\n<h2/g" | egrep "<h2 class=\"(warning|error)\"" | wc -l ) -gt 0 ]]; then
         fn_text_out "$( echo "$v_DIGICERT_CHECK" | sed "s/<h2/\n\n<h2/g" | egrep "<h2 class=\"(warning|error)\"" | sed "s/<[^>]*>/ /g;s/^ SSL Certificate/* The SSL Certificate/;s/^ /* /" )" "$v_RED"
      elif [[ $( echo "$v_DIGICERT_CHECK" | grep -c "h2 class=" ) -gt 0 ]]; then
         fn_text_out "...did not detect any issues." "$v_BLUE"
      else
         ### If the result of the curl does not contain "h2 class=", then it probably failed, but honeslty I have nothing to test against.
         v_CERT_CHECK=false
         fn_text_out "* Unable to connect to digicert to check the certificate. This will need to be done manually." "$v_RED"
      fi
   fi
}

function fn_version {
echo "Current Version: $v_VERSION"
cat << 'EOF' > /dev/stdout

Version Notes:
Future Versions -
     Better testing to ensure that the script is as robust as I want it to be.

0.7.0 (2016-03-15) -
     Added checked for failed login attempts within the mail log.

0.6.6 (2016-03-12) -
     Checking whether the MX IP address was hosted on the server was failing on cent7 boxes. This has been fixed (thanks LRumler).

0.6.5 (2016-03-11) -
     Full digicert information is now being captured in the email.

0.6.4 (2016-03-10) -
     Rather than just checking the version, the script downloads a newer version. (Thanks CHansen)
     It then runs that newer version.
     At some point, I appear to have accidentally removed the output that shows the OS and OpenSSL version. I have readded this.

0.6.3 (2016-03-09) -
     The script gathers the results into a text file and emails them out for tracking purposes.

0.6.2 (2016-03-02) -
     Some of our kicks don't include "bc" - figured out how to convert IP's to binary without. (Thanks JDebeer)
     email address and IP address can be specified at the command line.

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

./mail_info.sh --email [email address]
     Allows the user to specify the email address at the command line rather than wait to be prompted for it.

./mail_info.sh --ip [IP address]
     Allows the user to specify the IP address at the command line rather that wait to be prompted for it.

./mail_info.sh --help
./mail_info.sh -h
     Prints this text.

./mail_info.sh --version
./mail_info.sh -v
     Gives version and changelog information.

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
* Does the address they're connecting to have failed login attempts in the mail log?
* Do other addresses on the domain have failed login attempts in the mail log?
* Are their failed login attempts in the mail log from that IP address to ANY email account?
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

v_BLUE="\e[1;34m"
v_RED="\e[1;31m"
v_WHITE="\e[00m"

### Report the hostname to the results file.
fn_text_out "Server hostname: $( hostname )" "--just-file"
fn_text_out "" "--just-file"

if [[ $( echo "$@" | grep -c "[[:blank:]]*--no-version-check" ) -eq 0 ]]; then
   a_CL_ARGUMENTS=( "$@" )
   fn_compare_version "http://layer3.liquidweb.com/acwilliams/mail_info.sh" "run"
fi

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
elif [[ "$1" == "--ip" || "$1" == "--email" ]]; then
   if [[ "$1" == "--ip" ]]; then
      v_IP_ADDRESS="$2"
   fi
   if [[ "$3" == "--ip" ]]; then
      v_IP_ADDRESS="$4"
   fi
   if [[ "$1" == "--email" ]]; then
      v_EMAIL_ADDRESS="$2"
   fi
   if [[ "$3" == "--email" ]]; then
      v_EMAIL_ADDRESS="$4"
   fi
fi

### What email address are they having problems with?
fn_text_out
if [[ -z $v_EMAIL_ADDRESS ]]; then
   read -p "What is the email address the customer is trying to connect to? (or hit enter if you don't have this information yet) " v_EMAIL_ADDRESS
   fn_text_out
fi
fn_text_out "What is the email address the customer is trying to connect to? (or hit enter if you don't have this information yet) $v_EMAIL_ADDRESS" "--just-file"
fn_text_out "" "--just-file"
if [[ -n $v_EMAIL_ADDRESS && $( echo "$v_EMAIL_ADDRESS" | egrep -c "..*@..*\...*" ) -gt 0 ]]; then
   v_DOMAIN="$( echo $v_EMAIL_ADDRESS | sed "s/^.*:\/\///;s/^.*@//;s/^\([^/]*\)\/.*$/\1/" )"
   v_USER="$( echo "$v_EMAIL_ADDRESS" | sed "s/@$v_DOMAIN//" )"
   v_ACCOUNT="$( /scripts/whoowns $v_DOMAIN )"
   if [[ -z $v_ACCOUNT ]]; then
      fn_text_out "* $v_DOMAIN does not appear to be a domain owned by an account on this server." "$v_RED"
      fn_send_results
   fi
   v_HOMEDIR="$( egrep "^$v_ACCOUNT:" /etc/passwd | cut -d ":" -f6 )"
elif [[ -n $v_EMAIL_ADDRESS ]]; then
   fn_text_out "The address you specified doesn't appear to be in \"user@domain.tld\" format. Exiting."
   fn_send_results
elif [[ -z $v_EMAIL_ADDRESS ]]; then
   fn_text_out "*** Don't forget to re-run this script once you know the email address they're trying to connect to ***" "$v_RED"
fi

if [[ -z $v_IP_ADDRESS ]]; then
   read -p "What is the IP address that they are connecting from? (or hit enter if you don't have this information yet) " v_IP_ADDRESS
   fn_text_out
fi
fn_text_out "What is the IP address that they are connecting from? (or hit enter if you don't have this information yet) $v_IP_ADDRESS" "--just-file"
fn_text_out "" "--just-file"
if [[ -n $v_IP_ADDRESS && $( echo "$v_IP_ADDRESS" | egrep -c "^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[^[:blank:]]*:[^[:blank:]]*)$" ) -eq 0 ]]; then
   fn_text_out "The IP address you specified doesn't appear to be in the correct format. Exiting."
   fn_send_results
elif [[ -z $v_IP_ADDRESS ]]; then
   fn_text_out "*** Don't forget to re-run this script once you know the IP address they're trying to connect from ***" "$v_RED"
fi

### Is their version of cPanel outdated:
fn_text_out "Checking cPanel and mailserver..."
### As of 11.54, cPanle has changed the output of this script so that it no longer shows the major version. This complicates things, but shouldn't be an issue for the immediate future, so long as we just check whether the version number starts with "11" or not.
v_CHECK_CLEAR=true
v_CPANEL_VERSION="$( /usr/local/cpanel/cpanel -V | cut -d " " -f1 )"
if [[ $( echo "$v_CPANEL_VERSION" | cut -d "." -f1 ) -lt 11 ]]; then
   fn_text_out "* Version of cPanel is older than version 11. This is actually pretty scary." "$v_RED"
   v_CHECK_CLEAR=false
elif [[ $( echo "$v_CPANEL_VERSION" | cut -d "." -f1 ) -eq 11 && $( echo "$v_CPANEL_VERSION" | cut -d "." -f2 ) -lt 34 ]]; then
   fn_text_out "* Version of cPanel is older than 11.34. An upgrade is recommended" "$v_RED"
   v_CHECK_CLEAR=false
elif [[ $( echo "$v_CPANEL_VERSION" | cut -d "." -f1 ) -eq 11 && $( echo "$v_CPANEL_VERSION" | cut -d "." -f2 ) -gt 34 && $( echo "$v_CPANEL_VERSION" | cut -d "." -f2 ) -le 52 ]]; then
   fn_text_out "* Version of cPanel is between 11.34 and 11.52. This should be upgraded, but is probably okay." "$v_RED"
fi

### Is the server using Courier or Dovecot?
if [[ $( netstat -lpn | egrep -c "^tcp.*/dovecot(/.*)*[[:blank:]]*$" ) -gt 0 ]]; then
   v_IS_DOVECOT=true
fi
if [[ $( netstat -lpn | egrep -c "^tcp.*/couriertcpd[[:blank:]]*$" ) -gt 0 ]]; then
   v_IS_COURIER=true
   if [[ $v_IS_DOVECOT == true ]]; then
      fn_text_out "* Server appears to have both Courier and Deovecot listening on ports. This is not right and needs to be investigated further." "$v_RED"
      fn_send_results
   fi
   fn_text_out "* This server is running Courier. cPanel discontinued Courier as an option starting in version 11.54. It is recommended that the server be switched to Dovecot." "$v_RED"
   v_CHECK_CLEAR=false
fi
if [[ -z $v_IS_COURIER && -z $v_IS_DOVECOT ]]; then
   fn_text_out "* The server appears to be running neither Courier nor Dovecot. Without one of these, clients will not be able to connect." "$v_RED"
   fn_send_results
fi

if [[ $v_CHECK_CLEAR == true ]]; then
   fn_text_out "...did not detect any issues." "$v_BLUE"
fi

### Start building a list of ports to check in the firewall.
v_PORTS_OUT="$( netstat -lpn | grep "^tcp.*/exim[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep "." | sort -n | uniq | tr "\n" " " )"
v_PORTS_IN="$( netstat -lpn | egrep "^tcp.*/(dovecot|exim|couriertcpd)(/.*)*[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep "." | sort -n | uniq | tr "\n" " " ) 2095 2096"

### The SSL will be checked on these ports, unless these values are later changed to false.
v_CHECK_993=true
v_CHECK_995=true

fn_text_out "Checking processes and ports..."
v_CHECK_CLEAR=true
### Are there any ports that should be listened to, but are not?
for i in 25 26 465 587; do
   if [[ $( netstat -lpn | egrep "^tcp.*/exim[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep -c "^$i$" ) -lt 1 ]]; then
      fn_text_out "* Exim is not listening on port $i." "$v_RED"
      v_CHECK_CLEAR=false
   fi  
done
for i in 110 143 993 995; do
   if [[ $( netstat -lpn | egrep "^tcp.*/(dovecot|couriertcpd)(/.*)*[[:blank:]]*$" | awk '{print $4}' | rev | cut -d ":" -f1 | rev | grep -c "^$i$" ) -lt 1 ]]; then
      if [[ $v_IS_COURIER == true ]]; then
         fn_text_out "* Courier is not listening on port $i." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $v_IS_DOVECOT == true ]]; then
         fn_text_out "* Dovecot is not listening on port $i." "$v_RED"
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
      fn_text_out "* Webmail is not listening on port $i." "$v_RED"
      v_CHECK_CLEAR=false
   fi  
done

### What ports are open in the software firewall?
if [[ -n $( type -path -a csf ) ]]; then
   v_IS_CSF=true
   for i in $v_PORTS_IN; do
      if [[ $( grep "^TCP_IN" /etc/csf/csf.conf | cut -d "\"" -f2 | tr "," "\n" | grep -c "^$i$" ) -lt 1 ]]; then
         fn_text_out "* Port $i TCP is not open incoming in /etc/csf/csf.conf" "$v_RED"
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
         fn_text_out "* Port $i TCP is not open outgoing in /etc/csf/csf.conf" "$v_RED"
         v_CHECK_CLEAR=false
      fi
   done
fi
if [[ -n $( type -path -a apf ) ]]; then
   v_IS_APF=true
   if [[ $v_IS_CSF == true ]]; then
      fn_text_out "* APF and CSF Both installed. This is a problem and needs to be resolve before the script can go forward." "$v_RED"
      fn_send_results
   fi
   for i in $v_PORTS_IN; do
      if [[ $( grep "^IG_TCP_CPORTS" /etc/apf/conf.apf | cut -d "\"" -f2 | tr "," "\n" | grep -c "^$i$" ) -lt 1 ]]; then
         fn_text_out "* Port $i TCP is not open incoming in /etc/apf/conf.apf" "$v_RED"
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
         fn_text_out "* Port $i TCP is not open outgoing in /etc/apf/conf.apf" "$v_RED"
         v_CHECK_CLEAR=false
      fi
   done
fi
if [[ -z $v_IS_APF && -z $v_IS_CSF ]]; then
   v_CHECK_CLEAR=false
   fn_text_out "* Neither APF nor CSF appear to be installed. Check IPTables manually to make sure that the following TCP Incoming ports are open:" "$v_RED"
fi

if [[ $v_CHECK_CLEAR == true ]]; then
   fn_text_out "...did not detect any issues." "$v_BLUE"
fi

fn_text_out "Checking user files and DNS..."
v_CHECK_CLEAR=true
if [[ -n $v_ACCOUNT ]]; then
   ### Let's make sure that everything looks good for that account.
   if [[ $( grep -c "^$v_USER:" "$v_HOMEDIR/etc/$v_DOMAIN/passwd" ) -ne 1 ]]; then
      fn_text_out "* This user doesn't appear in \"$v_HOMEDIR/etc/$v_DOMAIN/passwd\"." "$v_RED"
      v_CHECK_CLEAR=false
   fi
   if [[ $( grep -c "^$v_USER:" "$v_HOMEDIR/etc/$v_DOMAIN/shadow" ) -ne 1 ]]; then
      fn_text_out "* This user doesn't appear in \"$v_HOMEDIR/etc/$v_DOMAIN/shadow\"." "$v_RED"
      v_CHECK_CLEAR=false
   fi
   if [[ ! -L "$v_HOMEDIR/mail/.$( echo $v_EMAIL_ADDRESS | sed "s/\./_/g" )" ]]; then
      fn_text_out "* Symlink \"$v_HOMEDIR/mail/.$( echo $v_EMAIL_ADDRESS | sed "s/\./_/g" )\" does not exist. This should be a link to \"$v_HOMEDIR/mail/$v_DOMAIN/$v_USER\"." "$v_RED"
      fn_text_out "     (Does this user actually exist in cPanel?)"
      v_CHECK_CLEAR=false
   fi
   if [[ ! -d "$v_HOMEDIR/mail/$v_DOMAIN/$v_USER" ]]; then
      fn_text_out "* Directory \"$v_HOMEDIR/mail/$v_DOMAIN/$v_USER\" does not appear to exist." "$v_RED"
      fn_text_out "     (Does this user actually exist in cPanel?)"
      v_CHECK_CLEAR=false
   fi

   ### Are there failures for that account in /var/log/maillog?
   if [[ $( head -n1 /var/log/maillog 2> /dev/null | wc -l ) -eq 0 ]]; then
      fn_text_out "* Either there is no data in /var/log/maillog, or /var/log/maillog doesn't exist. This may be indicative of a bigger problem." "$v_RED"
   elif [[ $v_IS_DOVECOT == true ]]; then
      if [[ -n $v_IP_ADDRESS && $( grep -c "auth failed.*$v_EMAIL_ADDRESS.*$v_IP_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to $v_EMAIL_ADDRESS from IP $v_IP_ADDRESS in /var/log/maillog." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $( grep -c "auth failed.*$v_EMAIL_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to $v_EMAIL_ADDRESS in /var/log/maillog, but *NOT* from IP $v_IP_ADDRESS." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ -n $v_IP_ADDRESS && $( grep -c "auth failed.*$v_DOMAIN.*$v_IP_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to an address at $v_DOMAIN from IP address $v_IP_ADDRESS in /var/log/maillog." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $( grep -c "auth failed.*$v_DOMAIN" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to an address at $v_DOMAIN in /var/log/maillog, but *NOT* from IP $v_IP_ADDRESS." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ -n $v_IP_ADDRESS && $( grep -c "auth failed.*$v_IP_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed email login attempts from IP address $v_IP_ADDRESS in /var/log/maillog, but *NOT* associated with $v_DOMAIN" "$v_RED"
         v_CHECK_CLEAR=false
      fi
   elif [[ $v_IS_COURIER == true ]]; then
      if [[ -n $v_IP_ADDRESS && $( grep -c "LOGIN FAILED.*$v_EMAIL_ADDRESS.*$v_IP_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to $v_EMAIL_ADDRESS from IP $v_IP_ADDRESS in /var/log/maillog." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $( grep -c "LOGIN FAILED.*$v_EMAIL_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to $v_EMAIL_ADDRESS in /var/log/maillog, but *NOT* from IP $v_IP_ADDRESS." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ -n $v_IP_ADDRESS && $( grep -c "LOGIN FAILED.*$v_DOMAIN.*$v_IP_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to an address at $v_DOMAIN from IP address $v_IP_ADDRESS in /var/log/maillog." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $( grep -c "LOGIN FAILED.*$v_DOMAIN" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed attempts to login to an address at $v_DOMAIN in /var/log/maillog, but *NOT* from IP $v_IP_ADDRESS." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ -n $v_IP_ADDRESS && $( grep -c "LOGIN FAILED.*$v_IP_ADDRESS" /var/log/maillog ) -gt 0 ]]; then
         fn_text_out "* There are recent failed email login attempts from IP address $v_IP_ADDRESS in /var/log/maillog, but *NOT* associated with $v_DOMAIN" "$v_RED"
         v_CHECK_CLEAR=false
      fi
   elif [[ $(( $( date +%s ) - $( date --date="$( head -n1 /var/log/maillog | awk '{print $1,$2,$3}' )" +%s ) )) -lt 86400 ]]; then
   ### If the first time stamp in the mail log happened less than a day ago...
      fn_text_out "* The first time stamp in /var/log/maillog is from less than 24 hours ago. You might want to investigate older logs to see if there have been failed logins for that email address or IP address." "$v_RED"
      v_CHECK_CLEAR=false
   fi

   ### Does DNS Look Good?
   if [[ $( dig +short mx $v_DOMAIN | grep -c "bmx0..sourcedns.com" ) -gt 0 ]]; then
      fn_text_out "Note: Domain appears to be using mailsecure. Ensure that this is configured correctly."
   else
      v_MX_IP_ADDRESS="$( dig +short mx $v_DOMAIN | sort -n | awk -v pref=65536 '($1<=pref) {pref=$1; print $2}' | dig +short -f - | uniq | head -n1 )"
      if [[ -z $v_MX_IP_ADDRESS ]]; then
         fn_text_out "* Either the MX record or the A record that it's pointing to are incorrectly configured. Further investigation is required." "$v_RED"
         v_CHECK_CLEAR=false
      fi
      if [[ $( ifconfig | egrep -c "^[[:blank:]]*inet addr:[0-9]" ) -gt 0 ]]; then
      ### This is the ifconfig format for cent6 and below
         if [[ $( ifconfig | egrep "^[[:blank:]]*inet addr:[0-9]" | awk '{print $2}' | cut -d ":" -f2 | grep -c "^$v_MX_IP_ADDRESS$" ) -lt 1 ]]; then
            fn_text_out "* It doesn't appear that the IP address associated with the MX record ($v_MX_IP_ADDRESS) is hosted on the server." "$v_RED"
            fn_text_out "     (Double check this. Verifiy that their server doesn't have natted IP addresses.)"
            v_CHECK_CLEAR=false
         fi
      elif [[ $( ifconfig | egrep -c "^[[:blank:]]*inet [0-9]" ) -gt 0 ]]; then
      ### This is the ifconfig format for cent 7
         if [[ $( ifconfig | egrep "^[[:blank:]]*inet [0-9]" | awk '{print $2}' | grep -c "^$v_MX_IP_ADDRESS$" ) -lt 1 ]]; then
            fn_text_out "* It doesn't appear that the IP address associated with the MX record ($v_MX_IP_ADDRESS) is hosted on the server." "$v_RED"
            fn_text_out "     (Double check this. Verifiy that their server doesn't have natted IP addresses.)"
            v_CHECK_CLEAR=false
         fi
      fi
      v_HOSTNAME_IP="$( dig +short $( hostname ) )"
      if [[ -z $v_HOSTNAME_IP ]]; then
         fn_text_out "* The hostname of the server doesn't appear to have an IP address." "$v_RED"
         v_CHECK_CLEAR=false
      fi
   fi
fi

if [[ $v_CHECK_CLEAR == true ]]; then
   fn_text_out "...did not detect any issues." "$v_BLUE"
fi

if [[ -n $v_IP_ADDRESS ]]; then
   fn_text_out "Checking for the IP within the firewall and cphulk..."
   v_CHECK_CLEAR=true
   
   if [[ $v_IS_CSF == true ]]; then
      if [[ $( csf -g "$v_IP_ADDRESS" | grep -c "DROP.*$v_IP_ADDRESS" ) -gt 0 ]]; then
         fn_text_out "* The IP address appears to currently be blocked in CSF. This will need to be manually removed." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $v_IS_CSF == true && $( grep -c "$v_IP_ADDRESS" /var/log/lfd.log ) -gt 0 ]]; then
         fn_text_out "* There are recent entries regarding this IP address in /var/log/lfd.log" "$v_RED"
         v_CHECK_CLEAR=false
      fi
   elif [[ $v_IS_APF == true ]]; then
      if [[ $( fn_check_ip $v_IP_ADDRESS | grep -c "BLOCKED: $v_IP_ADDRESS" ) -gt 0 ]]; then
         fn_text_out "* The IP address appears to currently be blocked in APF. This will need to be manually removed." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $( fn_check_ip $v_IP_ADDRESS | egrep -c "BLOCKED: [0-9]+.[0-9]+.[0-9]+.[0-9]+/[0-9]+" ) -gt 0 ]]; then
         fn_text_out "* A range containing the IP address appears to currently be blocked in APF. This will need to be manually removed." "$v_RED"
         v_CHECK_CLEAR=false
      elif [[ $v_IS_APF == true && $( grep -c "$v_IP_ADDRESS" /var/log/bfd_log ) -gt 0 ]]; then
         fn_text_out "* There are recent entries regarding this IP address in /var/log/bfd_log" "$v_RED"
         v_CHECK_CLEAR=false
      fi
   fi

   if [[ $( ps aux | grep -i cphulk | grep -civ "grep" ) -gt 0 ]]; then
   ### cphulk is active
      if [[ $( egrep -c "\[Remote IP Address\]=\[$v_IP_ADDRESS\]" /usr/local/cpanel/logs/cphulkd.log ) -gt 0 ]]; then
         fn_text_out "* There are recent entries regarding this IP address in the cphulk logs." "$v_RED"
         v_CHECK_CLEAR=false
      fi
   fi
   ### Check the hosts.allow file for ranges
   v_HOSTS_ALLOW_RANGE=0
   for v_RANGE in $( fn_check_ip_range "$v_IP_ADDRESS" /etc/hosts.allow /dev/stdout ); do 
      v_HOSTS_ALLOW_RANGE=$(( $( grep $v_RANGE /etc/hosts.allow | grep -ci deny ) + $v_HOSTS_ALLOW_RANGE ))
   done
   if [[ $v_HOSTS_ALLOW_RANGE -gt 0 ]]; then
      fn_text_out "* There is a range being denied in /etc/hosts.allow that includes this IP address." "$v_RED"
      v_CHECK_CLEAR=false
   fi
   ### Check the hosts.deny file for ranges
   v_HOSTS_DENY_RANGE=0
   for v_RANGE in $( fn_check_ip_range "$v_IP_ADDRESS" /etc/hosts.deny /dev/stdout ); do 
      v_HOSTS_DENY_RANGE=$(( $( grep $v_RANGE /etc/hosts.allow | grep -ci deny ) + $v_HOSTS_DENY_RANGE ))
   done
   if [[ $v_HOSTS_DENY_RANGE -gt 0 ]]; then
      fn_text_out "* There is a range being denied in /etc/hosts.deny that includes this IP address." "$v_RED"
      v_CHECK_CLEAR=false
   fi
   ### Check both files for the IP address itself.
   if [[ $( cat /etc/hosts.deny /etc/hosts.allow | grep -ic "$v_IP_ADDRESS.*deny" ) -gt 0 ]]; then
      fn_text_out "* This IP address is being denied in either /etc/hosts.deny or /etc/hosts.allow." "$v_RED"
      v_CHECK_CLEAR=false
   fi

   if [[ $v_CHECK_CLEAR == true ]]; then
      fn_text_out "...did not detect any issues." "$v_BLUE"
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

fn_text_out
fn_text_out "Server OS: $( cat /etc/redhat-release )"
fn_text_out "Openssl version: $( openssl version )"
if [[ -n $v_HOMEDIR ]]; then
   fn_text_out "Domain $v_DOMAIN has the following homedir: $v_HOMEDIR"
fi
fn_text_out
fn_text_out
fn_text_out "Other things to investigate:"
fn_text_out "* Check if the server has an active Storm firewall."
fn_text_out "* Check if the server is behind a physical firewall or other network device."
if [[ $v_CERT_CHECK != true ]]; then
   ### If there were any issues with the automated digicert checks, prompt the user to do them manually.
   fn_text_out "* Navigate to the following URL's to check SSL's:"
   if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $( grep -c "local_name $v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
      fn_text_out "   * https://www.digicert.com/help/ (and search for \"$v_DOMAIN:993\")"
      fn_text_out "   * https://www.digicert.com/help/ (and search for \"$v_DOMAIN:995\")"
   fi
   if [[ -n $v_DOMAIN && $v_IS_DOVECOT == true && $( grep -c "local_name mail.$v_DOMAIN {" /etc/dovecot/sni.conf ) -gt 0 ]]; then
      fn_text_out "   * https://www.digicert.com/help/ (and search for \"mail.$v_DOMAIN:993\")"
      fn_text_out "   * https://www.digicert.com/help/ (and search for \"mail.$v_DOMAIN:995\")"
   fi
   fn_text_out "   * https://www.digicert.com/help/ (and search for \"$( hostname ):993\")"
   fn_text_out "   * https://www.digicert.com/help/ (and search for \"$( hostname ):995\")"
   fn_text_out "* At the above URL's, verify the following:"
   fn_text_out "   * Is the SSL self-signed?"
   fn_text_out "   * Is the SSL revoked?"
   fn_text_out "   * Does the SSL's common name or SANs match the hostname specified?"
   fn_text_out "   * Does the chain complete?"
   fn_text_out "   * Are there are any other errors?"
fi
fn_text_out "* In WHM > Service Configuration > Mailserver Configuration, is SSLv3 listed as a protocol?"
fn_text_out
fn_send_results

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

### End of Script
