#!/bin/bash
#							   +----+----+----+----+
# 							   |    |    |    |    |
# Author: Mark David Scott Cunningham			   | M  | D  | S  | C  |
# 							   +----+----+----+----+
# Created: 2015-04-23
# Updated: 2017-05-07
#
# Purpose: Automate the process of analyzing exim_mainlog and queue, to locate
#          the usual suspects related to a server sending outbound spam mail.
#

## Exim Cheetsheet
# http://bradthemad.org/tech/notes/exim_cheatsheet.php

# Inspiration from previous work by: mwineland
# With php_maillog functions assisted by: mcarmack

## Exim command line flags and usage
# http://www.exim.org/exim-html-4.50/doc/html/spec_5.html#IX199

## Exim Utilities (help and usage info)
# http://www.exim.org/exim-html-4.50/doc/html/spec_49.html#IX2895

## Exim Log Files (flags and delimiters)
# http://www.exim.org/exim-html-current/doc/html/spec_html/ch-log_files.html

#-----------------------------------------------------------------------------#
## Because /moar/ regex is always better
shopt -s extglob

#-----------------------------------------------------------------------------#
## Workaround for exim logs with binary garbage in them
shopt -s expand_aliases
alias grep='grep -a'

#-----------------------------------------------------------------------------#
## Utility functions, because prettier is better
dash(){ for ((i=1;i<=$1;i++)); do printf $2; done; }
section_header(){ echo -e "\n$1\n$(dash 40 -)"; }

#-----------------------------------------------------------------------------#
## Initializations
LOGFILE="/var/log/exim_mainlog"
PHPCONF=$(php -i | awk '/php.ini$/ {print $NF}' | head -1);
if [[ -n $PHPCONF ]]; then PHPLOG=$(awk '/mail.log/ {print $NF}' $PHPCONF | tail -1 | tr -d \"\'); fi
QUEUEFILE="/tmp/exim_queue_$(date +%Y.%m.%d_%H.%M)"
l=1; p=0; q=0; full_log=0; fast_mode='';
LINECOUNT='1000000'
RESULTCOUNT='10'
DAYS=''; VERBOSE=0; OUT_LIST=''
L_OUT='LDir LAcct LAuth L-IP LFail LSpoof LBulk LSubj LBnce'
Q_OUT='QSum QAuth QLoc QSpoof QSubj QScript QSend QBnce QFrzn'

#-----------------------------------------------------------------------------#
# Menus for the un-initiated
#-----------------------------------------------------------------------------#
## MAIN MENU BEGIN
main_menu(){
PS3="Enter selection: "; clear
echo -e "$(dash 80 =)\nCurrent Queue: $(exim -bpc)\n$(dash 40 -)\n\nWhat would you like to do?\n$(dash 40 -)"
select OPTION in "Analyze Exim Logs (RUN THIS FIRST)" "Analyze PHP Logs" "Analyze Exim Queue" "Quit"; do
  case $OPTION in

    "Analyze Exim Logs (RUN THIS FIRST)")
      log_select_menu "/var/log/exim_mainlog"
      if [[ $l != '0' && -f $LOGFILE && ! $(file -b $LOGFILE) =~ zip ]]; then line_count_menu; fi
      results_prompt $l; break ;;

    "Analyze PHP Logs")
      l=0; p=1; q=0; log_select_menu ${PHPLOG};
      if [[ $p != '0' && -f $PHPLOG && ! $(file -b $PHPLOG) =~ zip ]]; then line_count_menu; fi
      results_prompt $p; break;;

    "Analyze Exim Queue")
      l=0; q=1; p=0; line_count_menu;
      results_prompt $q; break ;;

    "Quit") l=0; q=0; p=0; break ;;

    *) echo -e "\nPlease enter a valid option.\n" ;;

  esac;
done; clear
}
## MAIN MENU END

#-----------------------------------------------------------------------------#
## Select a log file from what's on the server
log_select_menu(){
  if [[ -f $1 ]]; then
    echo -e "\nWhich file?\n$(dash 40 -)\n$(du -sh ${1}* 2> /dev/null)\n"
    select LOGS in ${1}* "Quit"; do
      case $LOGS in
        "Quit") l=0; q=0; p=0; break ;;
        *) if [[ -f $LOGS ]]; then LOGFILE=$LOGS; PHPLOG=$LOGS; break;
           elif [[ -f ${REPLY} ]]; then LOGFILE=${REPLY}; PHPLOG=${REPLY}; break;
           else echo -e "\nPlease enter a valid option.\n"; fi ;;
      esac
    done;
  else
    echo -e "\nNo logs found. Quitting.\n"; l=0; q=0; p=0;
    read -p "Press [Enter] to continue ..." pause;
  fi
}

#-----------------------------------------------------------------------------#
## Lines to read from the log file
line_count_menu(){
  PS3="Enter selection or linecount: "
  echo -e "\nHow many lines to analyze?\n$(dash 40 -)"
  select LINES in "Last 10,000 lines" "Last 100,000 lines" "Last 1,000,000 lines" "All of it" "Quit"; do
    case $LINES in
      "Quit") l=0; q=0; p=0; break ;;
      "All of it") full_log=1; break ;;
      "Last 10,000 lines") LINECOUNT=10000; break ;;
      "Last 100,000 lines") LINECOUNT=100000; break ;;
      "Last 1,000,000 lines") LINECOUNT=1000000; break ;;
      *) if [[ ${REPLY} =~ [0-9] ]]; then LINECOUNT=${REPLY}; break;
         else echo "Invalid input, using defaults."; break; fi ;;
    esac
  done
}

#-----------------------------------------------------------------------------#
# How many results to show
results_prompt(){
  if [[ $1 != '0' ]]; then
    echo; read -p "How many results do you want? [10]: " NEWCOUNT;
    if [[ -n $NEWCOUNT && $NEWCOUNT =~ [0-9] ]]; then RESULTCOUNT=$NEWCOUNT;
      elif [[ -z $NEWCOUNT ]]; then echo "Continuing with defaults.";
      else echo "Invalid input, using defaults."; fi;
  fi
}

#-----------------------------------------------------------------------------#
# Calculate lines to read if start date is set (-d flag).
date_lookup(){
  if [[ $l == 1 ]]; then DATE=$(date --date="-$DAYS days" +%Y-%m-%d);
    elif [[ $p == 1 ]]; then DATE=$(date --date="-$DAYS days" +"%e %b %Y"); fi

  if [[ -n $DAYS ]]; then
    echo -ne "Searching for date: $DATE\r"
    FIRSTLINE=$(grep -n "$DATE" $1 | head -1 | cut -d: -f1)

    if [[ -n $FIRSTLINE ]]; then
      LINECOUNT="+${FIRSTLINE}"
    else
      echo "Could not find the desired date in the log, using default 1,000,000 lines."
    fi
  fi
}

#-----------------------------------------------------------------------------#
# Setup how much of the log file to read and how.
set_decomp(){
  # Servername and Current time of Analysis, and exim version
  echo -e "Hostname: $(hostname)\nCur.Date: $(date +'%A, %B %d, %Y -- %Y.%m.%d')\nExim Ver: $(/usr/sbin/exim --version 2>/dev/null | head -n1)\n"

  # Compressed file -- decompress and read whole log
  if [[ $(file -b $1) =~ zip ]]; then
    DECOMP="zcat -f";
    du -sh $1 | awk '{print "Using Log File: "$2,"("$1")"}'
    if [[ $l == 1 ]]; then
      $DECOMP $1 | head -n 1 | awk '{print "First date in log: "$1,$2}'
    elif [[ $p == 1 ]]; then
      $DECOMP $1 | head -n 1000 | perl -pe 's/.*(Date:.*?)\ Ret.*/\1/g' | awk '/Date:/ {print "First date in log: "$2,$3,$4,$5,$6}' | head -1
    fi

  # Read full log (uncompressed)
  elif [[ $full_log == 1 ]]; then
    DECOMP="cat";
    du -sh $1 | awk '{print "Using Log File: "$2,"("$1")"}'
    if [[ $l == 1 ]]; then
      head -1 $1 | awk '{print "First date in log: "$1,$2}';
    elif [[ $p == 1 ]]; then
      grep "Date:" $1 | head -1 | perl -pe 's/.*(Date:.*?)\ Ret.*/\1/g' | awk '/Date:/ {print "First date in log: "$2,$3,$4,$5,$6}';
    fi

  # Minimize impact on initial scan, using last LINECOUNT lines
  # Search for first date at the start of the LINECOUNT
  elif [[ -z $DAYS ]]; then
    DECOMP="tail -n $LINECOUNT";
    du -sh $1 | awk -v LINES="$LINECOUNT" '{print "Last",LINES,"lines of: "$2,"("$1")"}';
    echo -ne "Searching for first date  . . . \r"
    if [[ $l == 1 ]]; then
      tac $1 | head -n $LINECOUNT | tail -n 1 | awk '{print "First date found: "$1,$2}'
    elif [[ $p == 1 ]]; then
      tac $1 | head -n $LINECOUNT | tail -n 1000 | perl -pe 's/.*(Date:.*?)\ Ret.*/\1/g' | awk '/^Date:/ {print "First date found: "$2,$3,$4,$5,$6}' | tail -1
    fi

  # Use speficied date as starting point
  elif [[ -n $DAYS ]]; then
    DECOMP="tail -n $LINECOUNT";
    du -sh $1 | awk -v LINES="$LINECOUNT" '{print "Last",LINES,"lines of: "$2,"("$1")"}';
    echo "Starting with specified date: $DATE"
  fi

  # If log is not compressed, read the last date from the file
  if [[ ! $(file -b $1) =~ zip ]]; then
    if [[ $l == 1 ]]; then
      tail -n 1 $1 | awk '{print "Last date in log: "$1,$2}'
    elif [[ $p == 1 ]]; then
      tail -n 1000 $1 | perl -pe 's/.*(Date:.*?)\ Ret.*/\1/g' | awk '/Date:/ {print "Last date in log: "$2,$3,$4,$5,$6}' | tail -1
    fi
  fi
}

#-----------------------------------------------------------------------------#
# Process commandline flags
arg_parse(){
  local OPTIND;
  while getopts ac:d:f:Fhn:o:pqv OPTIONS; do
    case "${OPTIONS}" in
      a) full_log=1 ;;
      c) LINECOUNT=${OPTARG} ;;
      d) DAYS=${OPTARG} ;;
      f) LOGFILE=${OPTARG}; QUEUEFILE=${OPTARG}; PHPLOG=${OPTARG} ;; # Specify a log/queue file
      F) fast_mode=1 ;;
      n) RESULTCOUNT=${OPTARG} ;;
      o) OUT_LIST=$(echo ${OPTARG} | sed 's/,/ /g') ;;
      p) l=0; p=1; q=0 ;; # PHP log
      q) l=0; q=1; p=0 ;; # Analyze queue instead of log
      v) VERBOSE=1 ;; # Debugging Output
      h) l=0; q=0; p=0;
         echo -e "\nUsage: $0 [OPTIONS]\n
    -a ... Read full log (instead of last 1M lines)
    -c ... <#lines> to read from the end of the log
    -d ... <#days> back to read in the log (calculates linecount)
    -f ... </path/to/logfile> to use instead of default
    -F ... FastMode (skip dumping exim queue to log)
    -n ... <#results> to show from analysis
    -o ... Output only selected section(s) of mail analysis
             provided as comma separated list [LDir,LAcct,LAuth...]
           ----------------------------------------
           LDir .... Directories
           LAcct ... Accounts/Domain
           LAuth ... Authenticated Users
           L-IP .... IP-Address / Auth-Users
           LFail ... Failed Login IPs
           LSpoof .. Spoofed Senders
           LBulk ... Bulk Senders
           LSubj ... Subjects (Non-Bounceback)
           LBnce ... Bouncebacks (address)
           ----------------------------------------
           QSum .... Queue Summary
           QAuth ... Authenticated Users
           QLoc .... Authenticated Local Users
           QSpoof .. Spoofed Senders
           QSubj ... Subjects
           QScript . X-PHP-Scripts
           QSend ... Senders
           QBnce ... Bouncebacks (count)
           QFrzn ... Frozen (count)
           ----------------------------------------
    -p ... Look for 'X-PHP-Script' in the php mail log
    -q ... Create a queue logfile and analyze the queue
    -v ... Verbose (debugging output)\n
    -h ... Print this help and quit\n";
         return 0 ;; # Print help and quit
    esac
  done
}

#-----------------------------------------------------------------------------#
## Setup the log file analysis methods
mail_logs(){
# This will run a basic analysis of the exim_mainlog, and hopefully will also do the first few
# steps of finding any malware/scripts that are sending mail and their origins

date_lookup $LOGFILE
echo; set_decomp $LOGFILE;

if [[ $OUT_LIST ]]; then L_OUT=$OUT_LIST; fi
for opt in $L_OUT; do
  case $opt in

LDir) ## Count of messages sent by scripts
section_header "Directories"
$DECOMP $LOGFILE | grep 'cwd=' | grep -Eiv 'spool|error|exim' | perl -pe 's/.*cwd=(\/.*?)\ [0-9]\ args:.*/\1/g'\
 | awk '{freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT ;;

LAcct) # Count of messages per "Account/Domains"
section_header "Accounts/Domains"
$DECOMP $LOGFILE | grep -o '<=\ [^<>].*\ U=.*\ P=' | perl -pe 's/.*@(.*?)\ U=(.*?)\ P=/\2 \1/g'\
 | awk '{freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT | awk '{printf "%8s %-10s %s\n",$1,$2,$3}' ;;

LAuth) # Count of messages per Auth-Users
section_header "Auth-Users"
$DECOMP $LOGFILE | grep -Eo 'A=.*in:.*\ S=' | perl -pe 's/.*:(.*?)\ S=/\1/g'\
 | awk '{freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT ;;

L-IP) # Count of IPs per Auth-Users
section_header "IP-Addresses/Auth-Users"
$DECOMP $LOGFILE | grep 'A=.*in:.*\ S=' | perl -pe 's/.*[^I=]\[(.*?)\].*A=.*in:(.*?)\ S=.*$/\1 \2/g'\
 | awk '{freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT | awk '{printf "%8s %-15s %s\n",$1,$2,$3}' ;;

LFail) # Count of IPs that failed login
section_header "Failed Login IPs"
$DECOMP $LOGFILE | grep 'authenticator failed' | perl -pe 's/.*\ \[(.*?)\]:.*/\1/g'\
 | awk '{freq[$1]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT ;;

LSpoof) # Spoofed Sender Addresses
section_header "Spoofed Senders"
FMT="%8s %-35s %s\n"
printf "$FMT" "Count " " Auth-User" " Spoofed-User"
printf "$FMT" "--------" "$(dash 35 -)" "$(dash 35 -)"
$DECOMP $LOGFILE | grep 'A=.*in:.*\ S=' | perl -pe 's/.*<=\ (.*?)\ .*A=.*in:(.*?)\ .*/\2 \1/g'\
 | awk '{ if ($1 != $2) freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT | awk -v FMT="$FMT" '{printf FMT,$1" ",$2,$3}'
printf "$FMT" "--------" "$(dash 35 -)" "$(dash 35 -)" ;;

LBulk) # Show sent messages with the most recipients
section_header "Bulk Senders"
FMT="%8s %-16s %s\n"
printf "$FMT" "RCPTs " " MessageID" " Auth-User"
printf "$FMT" "--------" "$(dash 16 -)" "$(dash 40 -)"
$DECOMP $LOGFILE | grep "<=.*A=.*in:.*\ for\ "\
 | perl -pe 's/.*\ (.*?)\ <=\ .*A=.*in:(.*)\ S=.*\ for\ (.*)//g; print $count = scalar(split(" ",$3))," ",$1," ",$2;'\
 | sort -rn | head -n $RESULTCOUNT | awk -v FMT="$FMT" '{printf FMT,$1" ",$2,$3}'
printf "$FMT" "--------" "$(dash 16 -)" "$(dash 40 -)" ;;

LSubj) # Count of Messages by Subject
section_header "Subjects (Non-Bounceback)"
$DECOMP $LOGFILE | grep '<=.*T=' | perl -pe 's/.*T=\"(.*?)\".*/\1/g'\
 | awk '!/failed: |deferred: / {freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT ;;

LBnce) # Count of Bouncebacks by address
section_header "Bouncebacks (address)"
$DECOMP $LOGFILE | grep '<= <>.*\ for\ ' | perl -pe 's/.*\".*for\ (.*$)/\1/g'\
 | awk '{freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT ;;

*) echo "$opt is not a valid output option." ;;

  esac
done; echo
}

#-----------------------------------------------------------------------------#
## Setup the queue/file analysis methods
mail_queue(){
# This will run a basic summary of the mail queue, using both exim -bpr and /var/spool/exim/input/*

# Limit the queue scan to keep things fast
if [[ $full_log == 1 ]]; then READLIMIT="cat"; LOGLIMIT="cat"
  else READLIMIT="head -n $LINECOUNT"; LOGLIMIT="head -n $(( $LINECOUNT * 3 ))"; fi

## Generate Header File List
HEADER_LIST=$(find /var/spool/exim/input/ -type f -name "*-H" -print 2>/dev/null | $READLIMIT)

if [[ $OUT_LIST ]]; then Q_OUT=$OUT_LIST; fi

for opt in $Q_OUT; do
  case $opt in

QSum) ## Queue Summary
## Current Queue Dump
if [[ -f $QUEUEFILE ]]; then
  echo -e "\nFound existing queue dump ( $QUEUEFILE ).\n"
elif [[ ! $fast_mode ]]; then
  echo -e "\nCreating Queue Dump ($QUEUEFILE) to speed up analysis\n ... Thank you for your patience"
  /usr/sbin/exim -bpr | $LOGLIMIT > $QUEUEFILE
fi

# Read full log (uncompressed)
if [[ $full_log == 1 ]]; then
  DECOMP="cat";
  du -sh $QUEUEFILE | awk '{print "Using Queue Dump: "$2,"("$1")"}'
# Minimize impact on initial scan, using last 1,000,000 lines
elif [[ ! $fast_mode ]]; then
  DECOMP="tail -n $LINECOUNT";
  du -sh $QUEUEFILE | awk -v LINES="$LINECOUNT" '{print "Last",LINES,"lines of: "$2,"("$1")"}';
fi

if [[ -s $QUEUEFILE && ! $fast_mode ]]; then
section_header "Queue: Summary"
$DECOMP $QUEUEFILE | /usr/sbin/exiqsumm | head -3 | tail -2;
cat $QUEUEFILE | /usr/sbin/exiqsumm | sort -rnk1 | grep -v "TOTAL$" | head -n $RESULTCOUNT
fi ;;

QAuth) ## Queue Auth Users
section_header "Queue: Auth Users"
echo $HEADER_LIST | xargs grep --no-filename 'auth_id' 2>/dev/null\
 | sed 's/-auth_id //g' | sort | uniq -c | sort -rn | head -n $RESULTCOUNT ;;

QLoc) ## Queue Auth  Local Users
section_header "Queue: Auth Local Users"
echo $HEADER_LIST | xargs grep --no-filename -A1 'authenticated_local_user' 2>/dev/null\
 | grep -v 'authenticated_local_user' | sort | uniq -c | sort -rn | head -n $RESULTCOUNT ;;

QSpoof) ## Queue Spoofed Senders
section_header "Queue: Spoofed Senders"
FMT="%8s %-35s %s\n"
printf "$FMT" "Count " " Auth-User" " Spoofed-User"
printf "$FMT" "--------" "$(dash 35 -)" "$(dash 35 -)"
echo $HEADER_LIST | xargs awk '/auth_id/{printf $2" "};/envelope-from/{print $2}' | tr -d '<>)'\
 | awk '{ if ($1 != $2) freq[$0]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}'\
 | sort -rn | head -n $RESULTCOUNT | awk -v FMT="$FMT" '{printf FMT,$1" ",$2,$3}'
printf "$FMT" "--------" "$(dash 35 -)" "$(dash 35 -)" ;;

QSubj) ## Queue Subjects
section_header "Queue: Subjects"
echo $HEADER_LIST | xargs grep --no-filename "Subject: " 2>/dev/null\
 | sed 's/.*Subject: //g' | sort | uniq -c | sort -rn | head -n $RESULTCOUNT ;;

QScript) ## Queue Scripts
section_header "Queue: X-PHP-Scripts"
echo $HEADER_LIST | xargs grep --no-filename "X-PHP.*-Script:" 2>/dev/null\
 | sed 's/^.*X-PHP.*-Script: //g;s/\ for\ .*$//g' | sort | uniq -c | sort -rn | head -n $RESULTCOUNT ;;

QSend) ## Count of (non-bounceback) Sending Addresses in queue
section_header "Queue: Senders"
echo $HEADER_LIST | xargs grep --no-filename '^<[^>]' 2>/dev/null\
 | awk '{freq[$1]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}' | sort -rn | tr -d '<>' | head -n $RESULTCOUNT ;;

QBnce) ## Count of Bouncebacks in the queue
section_header "Queue: Bouncebacks (count)"
echo $HEADER_LIST | xargs grep --no-filename '^<>' 2>/dev/null\
 | awk '{freq[$1]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}' | sort -rn | head -n $RESULTCOUNT ;;

QFrzn) ## Count of 'frozen' messages by user
section_header "Queue: Frozen (count)"
echo $HEADER_LIST | xargs grep --no-filename '\-frozen' 2>/dev/null\
 | awk '($2 ~ /[0-9]/) {freq[$1]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}' | sort -rn | head -n $RESULTCOUNT ;;

*) echo "$opt is not a valid output option" ;;

  esac
done; echo
}

# Check that X_Header is turned on and process the php_maillog
mail_php(){
echo -e "\n$(php -v | head -1)\n"
date_lookup $PHPLOG

if [[ -f $PHPCONF && -n $(grep -Ei 'mail.add_x_header.*(on|1)' $PHPCONF) ]]; then
  echo "php.ini : $PHPCONF"
  echo "mail.log: $PHPLOG ($(du -sh $PHPLOG | awk '{print $1}'))"
  echo -e "X_Header: Enabled\n"

  set_decomp $PHPLOG;

  # Look for mailer scripts in the php_maillog
  section_header "PHP Mailer Scripts"
  $DECOMP $PHPLOG | perl -pe 's/.*\[(\/home.*?)\]/\1/g'\
   | awk -F: '{freq[$1]++} END {for (x in freq) {printf "%8s %s\n",freq[x],x}}' | sort -rn | head -n $RESULTCOUNT

  echo
elif [[ ! -f $PHPCONF ]]; then
  echo "Could not find php.ini file."
else
  echo "X_Header: Disabled"

  ## Prompt and configure php_maillog if confirmed.
  read -p "Would you like to enable add_x_header and the php_maillog? " yn;
  case $yn in
    y|Y|yes|Yes|YES)
      if [[ "$(php -v | grep -oP 'PHP 5.[^12]')" != '' ]]; then
        if [[ -z $(egrep '(^mail.add_x_header|^mail.log)' $PHPCONF) ]]; then
          cp -a $PHPCONF{,.pre_php_mail_log_addition};
          perl -n -i -e 'print; print "mail.add_x_header = On\nmail.log = /var/log/php_maillog\n" if /(\[mail function\])/' $PHPCONF;
          echo -e "\nVariables Added to [mail function]:\n";
          egrep '(^mail.add_x_header = On|^mail.log = /var/log/php_maillog)' $PHPCONF;

          touch /var/log/php_maillog && chmod 666 /var/log/php_maillog; echo -e "\nLog File Created:";
          ls -l /var/log/php_maillog | awk '{print $1,$NF}';

          echo -e "/var/log/php_maillog {\n\tcompress\n\tcreate\n\tweekly\n\tmissingok\n\trotate 4\n\tpostrotate\n\t/usr/sbin/httpd graceful\n\tendscript\n}" > /etc/logrotate.d/php_maillog
          echo -e "\nLogrotate configured for/var/log/php_maillog"

          echo -e "\nRestarting httpd Service"
          if [[ -d /etc/systemd ]]; then systemctl restart httpd 2>/dev/null; else /etc/init.d/httpd restart 2>/dev/null; fi
        else
          echo -e "\nNothing Done.\nCheck /usr/local/lib/php.ini:\n";
          egrep -n '(mail.add_x_header|mail.log)' $PHPCONF;
        fi;
      else
        echo -e "\nNothing Done.\nThis only works with 5.3 or higher";
      fi ;;
    *) echo "Okay, quitting for now." ;;
  esac
fi
}

#-----------------------------------------------------------------------------#
# Call menus or parse cli flags
if [[ -z $@ ]]; then main_menu; else arg_parse "$@"; fi

#-----------------------------------------------------------------------------#
## Run either logs() or queue() function
if [[ $l == 1 ]]; then mail_logs
elif [[ $q == 1 ]]; then mail_queue
elif [[ $p == 1 ]]; then mail_php; fi

if [[ $VERBOSE == 1 ]]; then
  dash 80 =; section_header "Debugging Information"
  echo -e "    LOGFILE : $LOGFILE
  QUEUEFILE : $QUEUEFILE
     PHPLOG : $PHPLOG
    PHPCONF : $PHPCONF
   full_log : $full_log
  LINECOUNT : $LINECOUNT
RESULTCOUNT : $RESULTCOUNT
   OUT_LIST : ${OUT_LIST:-Unset}
      L_OUT : $L_OUT
      Q_OUT : $Q_OUT
       DAYS : ${DAYS:-Unset}
       DATE : ${DATE:-Unset}\n"
fi

unset LOGFILE QUEUEFILE PHPCONF PHPLOG full_log LINECOUNT RESULTCOUNT DAYS DATE VERBOSE READLIMIT LOGLIMIT
#~Fin~
