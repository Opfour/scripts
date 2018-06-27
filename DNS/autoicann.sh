#!/bin/bash
#AutoICANN v0.2.7
#By nseltenright

DEBUG=0
#Colors-------------------------
WHITE="\033[1m"
LIGHTRED="\033[1;31m"
RED="\033[31m"
YELLOW="\033[1;33m"
BLUE="\033[34m"
BLUEB="\033[1;34m"
GREEN="\033[32m"
GREENB="\033[1;32m"
ENDCOLOR="\033[0m"
#-------------------------------
#Variables-----------------------
VERSION=0.2.7
#-------------------------------
#Functions----------------------

#Manages the domain list provided by a text file or by zen_grab_domains
function get_domain {
	if [ "$_scan" = 1 ]; then
		if [ "$_scan_rate" = 1 ]; then
			head -$_number /tmp/domains.txt \
			| grep -v "end_domains" \
			> /tmp/rate_domains.txt
			tail -1 /tmp/domains.txt \
			>> /tmp/rate_domains.txt
			cat /tmp/rate_domains.txt \
			> /tmp/domains.txt
			_scan_rate=0
		fi
		__domain=$(head -1 /tmp/domains.txt \
		| awk -F ":" '{print $1}')
		__ticket=$(head -1 /tmp/domains.txt \
		| awk -F ":" '{print $2}')
	else
		__domain=$(head -1 /tmp/domains.txt)
	fi
	__total=$(cat /tmp/domains.txt \
	| wc -l)
	head -1 /tmp/domains.txt \
	>> /tmp/out.txt
	__domain_check=$(whois "$__domain" \
	| grep -o "No ")
	sed -i '1d' /tmp/domains.txt
	__total_out=$(cat /tmp/out.txt \
	| wc -l)
}

#Prompts for the desired Billing username and password
function login_set {
	clear
	echo --------------------------------------------
	echo Please provide your LW Username and Password
	echo --------------------------------------------
	echo -e -n $GREEN"Username: "$ENDCOLOR
	read _user
	echo -e -n $GREEN"Password: "$ENDCOLOR

	_charcount=0
	while IFS= read -p "$_prompt" -r -s -n 1 _char
	do
	    if [[ $_char == $'\0' ]]; then
		break
	    fi
	    if [[ $_char == $'\177' ]]; then
		if [ $_charcount -gt 0 ]; then
		    _charcount=$((_charcount-1))
		    _prompt=$'\b \b'
		    _password="${_password%?}"
		else
		    _prompt=''
		fi
		else
		_charcount=$((_charcount+1))
		_prompt='*'
		_password+="$_char"
		fi
	done
}

#Will login to Billing using the user and password provided by login_set and save the session to a cookie
function login {
	echo && echo
	echo -e -n "[+] Logging into Billing as $_user..."

	curl -s -A "Mozilla/4.73 [en] (X11; U; Linux 2.2.15 i686)" \
	--cookie /tmp/cookie.txt --cookie-jar /tmp/cookie.txt \
	--data "login_username=$_user" \
	--data "login_password=$_password" \
	--data "login=login" \
	--location "https://billing.int.liquidweb.com/mysql/content/auth/login.html" \
	> /tmp/login.txt

	#Checking if login was successful
	_failed_login=$(cat /tmp/login.txt | grep -o "Billing Admin")
	if ! [ "$_failed_login" = "Billing Admin" ]; then
		echo -e $RED" Failed Login"$ENDCOLOR
		cleanup
		exit
	fi

	echo -e $GREEN" OK"$ENDCOLOR

	#Login to Zendesk
	zen_login
}

#Should only be called after the login command completed successfully
function zen_login {

	#Login to Zendesk and get auth token for ticket deletion
	echo -e -n "[+] Logging into Zendesk as $_user..."
	__token=$(curl -s \
	--cookie /tmp/cookie.txt \
	--cookie-jar /tmp/cookie.txt \
	--location "https://billing.int.liquidweb.com/mysql/content/admin/zendesk/sso.mhtml" \
	| grep "name=\"csrf-token\"" \
	| awk -F "\"" '{print $2}' \
	| sed 's/^/X-CSRF-Token: /g')

	#Check if login was successful
	if [ "${#__token}" = "58" ]; then
		echo -e $GREEN" OK"$ENDCOLOR
	else
		echo -e $RED" Failed Login"$ENDCOLOR
		cleanup
		exit
	fi
}

#Will grab the full list of tickets in the Suspended queue, then sort out the ICANN domains
function zen_grab_domains {

	#Get ICANN tickets from the suspended queue and put them in /tmp/domains.txt
	curl -s \
	--cookie /tmp/cookie.txt \
	"https://liquidweb.zendesk.com/api/v2/suspended_tickets" \
	| sed 's/,"id"/\n,"id"/g' \
	| grep ",\"id\"" \
	| grep "Domain Name Link" \
	| sed 's/,"author".*Domain Name Link//' \
	| sed 's/\\n/:/g' \
	| awk -F ":" '{print $3":"$2}' \
	> /tmp/domains.txt
}

#Sets the canned response for the ICANN email
function email_set {
	_body=$(echo "Hello,

We are contacting you regarding the whois information for $__domain
ICANN requires that whois information is accurate. Please verify the whois information provided in the link below. If everything is correct, please let us know if we can close this ticket. If you notice anything incorrect, please respond with the correct information so that I can update it for you.

http://whois.icann.org/en/lookup?name=$__domain
")
	_sub=$(echo "ICANN notice for $__domain")
}

#Grabs the account number for a domain out of the associated Billing page's <title>
function get_account {
	clear
	echo -n "Preparing ICANN $__total_out/$_complete for " && echo -e $YELLOW"$__domain"$ENDCOLOR && echo
	echo -e -n "[+] Grabbing Account Number..."

	#Checking if domain is valid
	if [ "$__domain_check" = "No " ]; then
		echo -e $RED" Invalid domain"$ENDCOLOR
		__bad_domain=1
	else
		curl -s -A "Mozilla/4.73 [en] (X11; U; Linux 2.2.15 i686)" \
		--cookie /tmp/cookie.txt \
		--location "https://billing.int.liquidweb.com/mysql/content/admin/search.mhtml?search_input=$__domain&search_submit=Search" \
		> /tmp/tmp.txt

		#Check if the domain exists with us.
		__not_lwdomain=$(cat /tmp/tmp.txt \
		| grep -o "No accounts were found")

		if [ "$__not_lwdomain" = "No accounts were found" ]; then
			echo -e $RED" Not an LW domain"$ENDCOLOR
			__bad_domain=1
		else
			#Check if multiple accounts were found and direct as needed
			cat /tmp/tmp.txt \
			| grep "<td class=\"sumdata\|<option>" \
			| sed -e 's/<[^<>]*>//g' \
			| tr -d '\040\011\015' \
			| sed '/^$/d' \
			| sed '/^[0-9][0-9]*$/ i -net-' \
			| sed -e "\$a-net-" \
			> /tmp/account_check.txt

			if [ -s /tmp/account_check.txt ]; then
				multi_account
			else
				_accnumb=$(cat /tmp/tmp.txt | grep "LW \[" | awk '{print $2}' | sed 's/[^0-9]*//g')
			fi

			#Check for internal account
			__internal=$(curl -s -A "Mozilla/4.73 [en] (X11; U; Linux 2.2.15 i686)" \
			--cookie /tmp/cookie.txt \
			--location "https://billing.int.liquidweb.com/mysql/content/admin/account/contact/?accnt=$_accnumb" \
			| grep -o "INTERNAL")

			if [ "$__internal" = INTERNAL ]; then
				echo -e $RED" Internal Account"$ENDCOLOR
				__internal_domain=1
			else
				if [ -z $_accnumb ]; then
					echo -e $RED" Not an LW domain"$ENDCOLOR
					__bad_domain=1
				else
					echo -e $GREEN" OK"$ENDCOLOR
					echo -e -n "[+] Obtained account: $_accnumb" && echo
				fi
			fi
		fi
	fi
}

#Grabs the email associated with a domain from its Contact Billing page
function email_get {
	echo -e -n "[+] Grabbing email..."
	curl -s -A "Mozilla/4.73 [en] (X11; U; Linux 2.2.15 i686)" \
	--cookie /tmp/cookie.txt \
	--location "https://billing.int.liquidweb.com/mysql/content/admin/account/contact/?accnt=$_accnumb" \
	> /tmp/tmp.txt

	_email=$(cat /tmp/tmp.txt \
	| grep "<i>main</i>" \
	| awk '{print $1}')

	echo -e $GREEN" OK"$ENDCOLOR
}

#Sends the ICANN email using the gathered information
function send_icann {
	echo -e -n "[+] Sending ICANN..." && echo
	curl -s -A "Mozilla/4.73 [en] (X11; U; Linux 2.2.15 i686)" \
	--cookie /tmp/cookie.txt \
	--cookie-jar /tmp/cookie.txt \
	--data-urlencode "handler=$_user" \
	--data-urlencode "to=$_email" \
	--data-urlencode "subject=$_sub" \
	--data-urlencode "email_message=$_body" \
	--data-urlencode "type=support" \
	--data-urlencode "status=solved" \
	--data-urlencode "autoclose=1" \
	--data-urlencode "mode=create_hd_ticket" \
	--data-urlencode "send_message=Create Ticket and Send Email" \
	--location "https://billing.int.liquidweb.com/mysql/content/admin/account/support/?accnt=$_accnumb" \
	> /dev/null
}

#Remove temporary files
function cleanup {
	rm /tmp/tmp.txt &> /dev/null
	rm /tmp/cookie.txt &> /dev/null
	rm /tmp/out.txt &> /dev/null
	rm /tmp/domains.txt &> /dev/null
	rm /tmp/account_check.txt &> /dev/null
	rm /tmp/clear_term.txt &> /dev/null&> /dev/null
	rm /tmp/login.txt &> /dev/null
}

#If called something very bad happened
function abort {
	cleanup >> /tmp/error_log
	clear
	cat /tmp/error_log
	exit
}

#Handle multiple accounts associated with one ICANN domain
function multi_account {

	#Excluding Terminated accounts
	cat /tmp/account_check.txt \
	| tac \
	| sed -n -e '/terminated/{' -e 'p' -e ':a' -e 'N' -e '/-net-/!ba' -e 's/.*\n//' -e '}' -e 'p' \
	| sed '/terminated/,+1d' \
	| tac \
	> /tmp/clear_term.txt

	#Grab the correct account
	_accnumb=$(cat /tmp/clear_term.txt \
	| tac \
	| sed -n "/^$__domain::DREG$/,/^-net-$/p" \
	| tac \
	| sed -n '2p')
}

#Scan the suspended tickets queue for domains to send ICANNs for
function scan {

	#Grab ICANN domains from /tmp/domains.txt
	zen_grab_domains
	if [ -s /tmp/domains.txt ]; then
		echo "end_domains" >> /tmp/domains.txt
		sed -i '/^$/d' /tmp/domains.txt
		get_domain
	else
		echo -e $RED"No ICANNS were found in the queue"$ENDCOLOR
		cleanup
		exit
	fi
}

#Delete ticket after ICANN is sent
function delete_ticket {

	echo -n "[+] Deleting ticket: $__ticket..."

	#Delete ticket
	curl -s \
	--cookie /tmp/cookie.txt \
	-H "$__token" \
	"https://liquidweb.zendesk.com/api/v2/suspended_tickets/destroy_many.json?ids=$__ticket" \
	-X DELETE

	echo -e $GREEN" OK"$ENDCOLOR
}
#-------------------------------
#Grab Domain Source---------------------------------------------
#Cleanup--------------------------------------------------------
cleanup
#---------------------------------------------------------------
if [[ "$1" = *.txt ]]; then
	if [ -s "$1" ]; then
		#txt file-----------------------------
		cp $1 /tmp/domains.txt
		echo "end_domains" >> /tmp/domains.txt
		sed -i '/^$/d' /tmp/domains.txt
		get_domain
		#--------------------------------------
	else
		#txt does not exist--------------------
		echo -e $RED"File does not exist"$ENDCOLOR
		exit
		#--------------------------------------
	fi
else
	case $1 in
		--scan | -s)
			_scan=1
			if [[ \"$2\" = \"-n=*\" ]] || [[ \"$2\" = \"--number=*\" ]]; then
				_number=$(echo "$2" | sed 's/-n=//g; s/--number=//g')
				if ! [ -z "$_number" ]; then
					_scan_rate=1
				fi
			fi
		;;
		--clean | -c)
			cleanup
			echo -e $GREEN"All Cache Cleared!"$ENDCOLOR
			exit
		;;
		--help | -h)
			echo -e $BLUEB"AutoICANN v$VERSION"$ENDCOLOR
			echo
			echo -e $BLUE"Usage: autoicann [options] [arguments]"$ENDCOLOR
			echo
			echo
			echo -e $BLUE"Arguments:"$ENDCOLOR
			echo -e $BLUE"  Location of a domain list txt file"$ENDCOLOR
			echo -e $BLUE"  Domains separated by a space"$ENDCOLOR
			echo
			echo -e $BLUE"--scan         -s        Scan suspended tickets for a list of domains"$ENDCOLOR
			echo -e $BLUE"--number       -n        Used with --scan to limit ICANNs processed"$ENDCOLOR
			echo -e $BLUE"--help         -h        Display AutoICANN usage info"$ENDCOLOR
			echo -e $BLUE"--version      -v        Display AutoICANN version info"$ENDCOLOR
			echo
			echo -e $GREEN"Report any issues to: nseltenright@liquidweb.com"$ENDCOLOR
			exit
		;;
		--version | -v)
			echo -e $BLUEB"$VERSION"$ENDCOLOR
			exit
		;;
		-*)
			echo -e $RED"Please use a valid option for this command"$ENDCOLOR
			echo -e $BLUE"Usage: autoicann [options] [arguments]"$ENDCOLOR
			echo
			echo -e $BLUE"Try 'autoicann --help' for a full list of options."$ENDCOLOR
			exit
		;;
	esac
	if [ -s "$1" ]; then
		#File is not a txt-------------
		echo -e $RED"Only .txt files can be used"$ENDCOLOR
		exit
		#------------------------------
	else
		if ! [[ "$1" = -* ]]; then
			#A domain has been called--------
			echo "$*" | sed -e 's/\s\+/\n/g' > /tmp/domains.txt
			echo "end_domains" >> /tmp/domains.txt
			sed -i '/^$/d' /tmp/domains.txt
			get_domain
			#--------------------------------
		fi
		if [ -z "$1" ]; then
			echo -e $RED"Please use a valid option for this command"$ENDCOLOR
			echo -e $BLUE"Usage: autoicann [options] [arguments]"$ENDCOLOR
			echo
			echo -e $BLUE"Try 'autoicann --help' for a full list of options."$ENDCOLOR
			exit
		fi
	fi
fi
#---------------------------------------------------------------

#Login Credentials----------------------------------------------
login_set
#---------------------------------------------------------------
#Login----------------------------------------------------------
login
#---------------------------------------------------------------
#If Scan mode
if [ $_scan = 1 ]; then
	scan
fi

_complete=$(echo "$(($__total-1))")
while ! [ "$__domain" = end_domains ]; do
	#Set Email------------------------------------------------------
	email_set
	#---------------------------------------------------------------

	#Grab Account---------------------------------------------------
	get_account
	#---------------------------------------------------------------
	if ! [ "$__bad_domain" = 1 ]; then
		if ! [ "$__internal_domain" = 1 ]; then
			#Grab Email-----------------------------------------------------
			email_get
			#---------------------------------------------------------------

			#Send ICANN email-----------------------------------------------
			if [ "$DEBUG" = 1 ]; then
				echo -e $RED"ICANN would have been sent!"$ENDCOLOR
			else
				send_icann
			fi
			#---------------------------------------------------------------
		fi
		#Delete ticket
		if [ "$_scan" = 1 ]; then
			if [ "$DEBUG" = 1 ]; then
				echo -e $RED"Ticket would be deleted!"$ENDCOLOR
			else
				delete_ticket
			fi
		fi
	fi
	__bad_domain=0
	__internal_domain=0

	#Grab Next Domain-----------------------------------------------
	get_domain
	#---------------------------------------------------------------
done
#Finished-------------------------------------------------------
clear
echo -e $GREEN"Completed on $_complete domain(s)"$ENDCOLOR

#Removing temporary files---------------------------------------
cleanup
exit
#---------------------------------------------------------------
