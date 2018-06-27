#							   +----+----+----+----+
# 							   |    |    |    |    |
# Author: Mark David Scott Cunningham			   | M  | D  | S  | C  |
# 							   +----+----+----+----+
# Created: 2014-02-08
# Updated: 2017-05-23
#
#
#!/bin/bash

# http://doc.coker.com.au/internet/how-to-debug-smtp-with-tlsssl-and-auth/	(SMTP-ssl)
# http://www.anta.net/misc/telnet-troubleshooting/smtp.shtml			(SMTP-telnet)
# http://www.anta.net/misc/telnet-troubleshooting/imap.shtml			(IMAP-ssl)
# http://www.anta.net/misc/telnet-troubleshooting/pop.shtml			(POP3-ssl)

showcerts="-quiet"
tlsopts=''
secure=''

# Define help function for use later
_help(){
echo -e "\n Usage: $(basename $0) [options] [hostname] [email-address] [password]\n
    -i | --imap ..... Test IMAP
    -p | --pop3 ..... Test POP3
    -s | --smtp ..... Test SMTP
    -S | --ssl ...... Use SSL connection
    -T | --tls ...... Use StartTLS connection
    -P | --port ..... Set alternate port
    -v | --verbose .. Show full SSL Cert output

 Examples:
    SMTP with TLS
    $(basename $0) -s -T [host] [email] [pass]

    IMAP with SSL
    $(basename $0) -i -S [host] [email] [pass]

    POP3 with SSL
    $(basename $0) -p -S [host] [email] [pass]

    SMTP with alternate port
    $(basename $0) -s -P 26 [host] [email] [pass]\n"; exit 0
}

# Execute Getopt for argument parsing
OPTIONS=$(getopt -o "hipP:sSTv" --long "help,smtp,imap,pop3,ssl,tls,port:,verbose" -- "$@")

# Check for bad arguments
if [ $? -ne 0 ] ; then _help; fi

eval set -- "$OPTIONS" # Magic
while true; do # Evaluate the options for their options
 case "$1" in
  -h|--help) _help ;;

  -i|--imap) method=imap; port=143 ;;

  -p|--pop3) method=pop3; port=110 ;;

  -s|--smtp) method=smtp; port=25 ;;

  -S|--ssl)
    case $method in
      smtp) port=465 ;;
      imap) port=993 ;;
      pop3) port=995 ;;
    esac; secure=1;
    ;;

  -T|--tls)
    case $method in
      smtp) port=587; tlsopts="-starttls smtp" ;;
      imap) tlsopts="-starttls imap" ;;
      pop3) tlsopts="-starttls pop3" ;;
    esac; secure=1;
    ;;

  -P|--port)
    if [[ $2 =~ [0-9]{2,5} ]]; then
      port=$2; shift;
    else
      echo -e "\n  The port option requires a valid parameter."
    fi ;;

  -v|--verbose) showcerts='' ;;

  --) # More Magic
    shift; break;;

  *) _help ;;
 esac; shift
done

# If the host, user, pass are not specified at run time prompt for them
if [[ -n $1 ]]; then
  if [[ -z $1 ]]; then read -p "Hostname: " host; else host=$1; fi
  if [[ -z $2 ]]; then read -p "Email Address: " emailaddr; else emailaddr=$2; fi
  if [[ -z $3 ]]; then read -sp "Password: " emailpass; else emailpass=$3; fi
fi

# Check if expect is installed
if [[ ! -x $(which expect 2>/dev/null) ]]; then
  echo -e "\nThis script requires the expect package.\n"
  echo -e "Try one of the following:\n  sudo yum install expect\n  sudo apt-get install expect\n"; exit 2;
fi

# Set the connection method for ssl/tls if selected
if [[ $secure ]]; then
  domain=$(echo $emailaddr | cut -d@ -f2)

  # Check if local version of OpenSSL has SNI support
  if [[ $(openssl version | awk '{print $2}') =~ ^1\. ]]; then SNI="-servername $domain"; else SNI=''; fi

  # Check the DH-Key strength
  echo; echo | openssl s_client -nbio $tlsopts $SNI -connect $host:$port -cipher "EDH" 2>/dev/null | grep "Server Temp Key";

  connect="openssl s_client $tlsopts -crlf $SNI -connect $host:$port $showcerts"
else
  # Check the utility to use for non-ssl connections 
  if [[ -x $(which nc 2>/dev/null) ]]; then
    connect="nc -C $host $port"
  elif [[ -x $(which ncat 2>/dev/null) ]]; then
    connect="ncat -C $host $port"
  elif [[ -x $(which netcat 2>/dev/null) ]]; then
    connect="netcat -C $host $port"
  elif [[ -x $(which telnet 2>/dev/null) ]]; then
    connect="telnet $host $port"
  else
    echo -e "\nThis script requires telnet or netcat for insecure connections.\n"
    echo -e "Try one of the following:\n  sudo yum install netcat\n  sudo yum install telnet\n  sudo apt-get install netcat\n  sudo apt-get install telnet\n"; exit 2;
  fi
fi

echo
case $method in
  imap )
	#echo -e "\n  1) [tag] LOGIN <address> <password>\n  2) [tag] LIST \"\" \"*\"\n  3) [tag] SELECT INBOX\n  4) [tag] FETCH 1 BODY[]\n  5) [tag] LOGOUT\n"
	expect -c "
          spawn $connect
	expect OK
	  send \"tag LOGIN ${emailaddr} ${emailpass}\r\"
	expect OK
	  send \"tag SELECT INBOX\r\"
	expect OK
	  send \"tag FETCH 1 BODY\[\]\r\"
	expect completed
	  send \"tag LOGOUT\r\"
	interact
        " 2> /dev/null ;;

  pop3 )
	#echo -e "\n  1) USER <address>\n  2) PASS <password>\n  3) STAT\n  4) LIST\n  5) RETR 1\n  6) QUIT\n";
	expect -c "
	  spawn $connect
	expect OK
	  send \"USER ${emailaddr}\r\"
	expect OK
	  send \"PASS ${emailpass}\r\"
        expect OK
          send \"STAT\r\"
	expect OK
	  send \"RETR 1\r\"
        expect .
          send \"QUIT\r\"
	interact
        " 2> /dev/null ;;

  smtp )
	#echo -e "\n  1) HELO $host\n  2) MAIL FROM:<address>\n  3) RCPT TO:<address>\n  4) DATA\n  5) .\n  6) QUIT\n";
	newuser=$(echo -n $emailaddr | base64)
	newpass=$(echo -n $emailpass | base64)
	expect -c "
	  spawn $connect
	expect -re (250|220)
	  send \"EHLO $(hostname)\r\"
	expect 250
	  send \"AUTH LOGIN\r\"
	expect 334
	  send \"$newuser\r\"
	expect 334
	  send \"$newpass\r\"
	expect 235
	  send \"QUIT\r\"
	interact
	" 2> /dev/null ;;

esac
echo
