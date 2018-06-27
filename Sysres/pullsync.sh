#!/bin/bash
# pullsync.sh
# abrevick@liquidweb.com
# do some cpanel migrations!
# date: Apr 07 2014

#Works like the old initialsync but run it from the destination server instead of the source.  One big difference is that it creates its own ssh key to use, and deletes it when it finishes.  So, you will get asked for the password once each time you use it.  This way we are not leaving access open between servers. 

version="1.0"

# variables
# these could be changed:
badusers="system|root|HASH" #excluded users when selecting all users.  filtered out by egrep -v. add more like this "system|root|alan|eric" 
rsync_excludes='--exclude="error_log" --exclude="backup-*.tar.gz"' # filter out stuff like error_log, backup-*.tar.gz, only for homedir syncs.
#rsynced over from old server to the $dir
filelist="/etc/apf
/etc/cpbackup.conf
/etc/cron*
/etc/csf
/etc/exim.conf
/etc/passwd
/etc/sysconfig/network-scripts
/etc/userdomains
/etc/userdatadomains
/etc/wwwacct.conf
/root/.my.cnf
/usr/local/apache/conf
/usr/local/cpanel/version
/usr/local/lib/php.ini
/usr/share/ssl
/var/cpanel/databases
/var/cpanel/useclusteringdns
/var/lib/named/chroot/var/named/master
/var/named
/var/spool/cron
/var/ssl
"

# vars that should not chnage
scriptname=`basename $0 .sh`
starttime=`date +%F.%T`
dir="/home/temp/pullsync"
log="${dir}/$scriptname.log"
rsyncargs="-aqH"
userlistfile="/root/userlist.txt"
domainlistfile="/root/domainlist.txt"
remote_tempdir="/home/temp/pullsynctmp.$starttime" # cpmove files are created here on remote server
hostsfile="/usr/local/apache/htdocs/hosts.txt"
hostsfile_alt="/usr/local/apache/htdocs/hostsfile.txt"
sshargs="-o GSSAPIAuthentication=no" #disable "POSSIBLE BREAKIN ATTEMPT" messages
[ ! -f /etc/wwwacct.conf ] && echo "/etc/wwwacct.conf not found! Not a cpanel server?" && exit 99
cpanel_main_ip=`cat /etc/wwwacct.conf|grep ADDR|cut -d ' ' -f2`
proglist="ffmpeg
imagick
memcache
java
upcp
mysqlup
ea
postgres"

#colors
nocolor="\E[0m"
black="\033[0;30m"
grey="\033[1;30m"
red="\033[0;31m"
lightRed="\033[1;31m"
green="\033[0;32m"
lightGreen="\033[1;32m"
brown="\033[0;33m"
yellow="\033[1;33m"
blue="\033[0;34m"
lightBlue="\033[1;34m"
purple="\033[0;35m"
lightPurple="\033[1;35m"
cyan="\033[0;36m"
lightCyan="\033[1;36m"
white="\033[1;37m" # bold white
greyBg="\033[1;37;40m"

# check for previous directory so we can load variables from it for finalsync
# could get vars from an older migration by moving /home/temp/pullsync.xxxx to /home/temp/pullsync
if [ -d "$dir" ]; then 
	oldstarttime=`cat $dir/starttime.txt` ;
	olddir="$dir.$oldstarttime" ; 
	[ -f $olddir/ip.txt ] && oldip=`cat $olddir/ip.txt`
	[ -f $olddir/port.txt ] && oldport=`cat $olddir/port.txt`
	[ -f $olddir/userlist.txt ] && oldusercount=`cat $olddir/userlist.txt |wc -w` && someoldusers=`cat $olddir/userlist.txt | tr '\n' ' '| cut -d' ' -f1-6`
	rm -rf $dir
fi

# initalize working directory. $dir is a symlink to $dir.$starttime from last migration
mkdir -p "$dir.$starttime"
ln -s "$dir.$starttime" "$dir"
echo "$starttime" > $dir/starttime.txt
[ $olddir ] && echo "$olddir" > $dir/olddir.txt

# quit if something went wrong 
[ ! -d "$dir" ] && echo "ERROR: could not find $dir!"  && exit 1

yesNo() { #generic yesNo function
	#repeat if yes or no option not valid
	while true; do
		# $* read every parameter given to the yesNo function which will be the message
		echo -ne "${yellow}${*}${white} (Y/N)?${nocolor} " 
		#junk holds the extra parameters yn holds the first parameters
		read yn junk
		case $yn in
			yes|Yes|YES|y|Y)
				return 0  ;;
			no|No|n|N|NO)
				return 1  ;;
			*) 
				ec lightRed "Please enter y or n." 
		esac
	done    
#usage:
#if yesNo 'do you want to continue?' ; then
#    echo 'You choose to continue'
#else
#    echo 'You choose not to continue'
#fi
}

ec() { # `echo` in a color function
	# Usage: ec $color "text"
	ecolor=${!1} #get the color
	shift #  $1 is removed here
	echo -e ${ecolor}"${*}"${nocolor} #echo the rest
}


main() {

	mainloop=0
	while [ $mainloop == 0 ] ; do
		clear
		# menu
		echo "$scriptname
version: $version
Started at $starttime
"
		ec yellow: "Choose your Destiny:"
		ec white "		1) Single cpanel account
		2) List of cpanel users from /root/userlist.txt
		3) List of domains from /root/domains.txt
		4) All users

		9) Final Sync

		0) Quit
		"
		[[ ! "${STY}" ]] && ec lightRed "Warning! You are not in a screen session!" 
		echo -n "Input Choice: "
		read choice
		case $choice in 
			1) 
				synctype="single"
				mainloop=1 ;;
			2) 
				synctype="list"
				mainloop=1 ;;
			3)
				synctype="domainlist"
				mainloop=1 ;;
			4) 	
				synctype="all"
				mainloop=1 ;;
			9) 	
				synctype="final"
				mainloop=1 ;;
			0) 
				echo "Bye..."; exitcleanup ; exit 10 ;;
			*)  
			   ec lightRed "Not a valid choice. Try again!"; sleep 3; clear
		esac	
	done
	# all types
	oldmigrationcheck #also gets ips 
	getuserlist
	lower_ttls
	getversions
### initial syncs
	if [ "$synctype" == "single" ] || [ "$synctype" == "list" ] || [ "$synctype" == "domainlist" ] || [ "$synctype" == "all" ];then
		#get versions/version matching
		if  [ "$synctype" == "list" ] || [ "$synctype" == "domainlist" ] || [ "$synctype" == "all" ];then # no single
			ec lightGreen "Here is what we found to install:"
			for prog in $proglist; do 
				[ "${!prog}" ] && echo "$prog"
			done
			# version matching run here.
			if yesNo "Run version matching?"; then
				do_installs=1
				upcp_check
				mysqlversion
				phpversion
				postgres_install_check
				modsec_rules_check
			fi
			rsync $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/packages $ip:/var/cpanel/features /var/cpanel/
			dedipcheck
		fi
		# back to syncing data
		ec lightCyan "Ready to do the initial sync! Please press enter to continue."
		read
		[ $do_installs ] && installs
		
		package_accounts # runs rsync_homedir, hosts_file in tandem
		
		# final checks!
		[ "$mysqlupcheck" = "1" ] && ec yellow "Mysql was updated, remember to run EA!" && read
		echo

		# exim ports
		remote_exim_ports=`grep ^daemon_smtp_ports $dir/etc/exim.conf`
		local_exim_ports=`grep ^daemon_smtp_ports /etc/exim.conf`
		if [ "$remote_exim_ports" != "$local_exim_ports" ]; then
			ec lightRed "Alternate exim ports found!"
			echo $remote_exim_ports
			ec yellow "Please set them up in WHM > Service Manager"
		fi

		if [ -f $dir/did_not_restore.txt ]; then
			ec lightRed "Found users that did not restore."
			cat $dir/did_not_restore.txt
			ec yellow "Press enter to continue."
			read
		fi

		ec yellow "Hosts file entries:"
		if [ -f "$hostsfile" ];then
			cat "$hostsfile"
			echo
			echo "I've generated a hosts file for you at http://$cpanel_main_ip/hosts.txt"
			echo "I've generated a hosts file for you with one line per domain at http://$cpanel_main_ip/hostsfile.txt"
		fi
### final sync stuff ##		
	elif [ "$synctype" == "final" ]; then
		if yesNo "Stop services for final sync?";then
			stopservices=1
			 if yesNo 'Restart services after sync?'; then
  				restartservices=1
 			fi
		fi
		#rsyncupdate
		if yesNo 'Use --update flag for final rsync? If files were updated on the destination server they wont be overwritten'; then
	 		rsync_update="--update"
		fi
		# named 
		if yesNo 'Copy /var/named/*.db back to old server? Will backup current directory. Dont do this unless migrating all users!' ;then 
			if [ $domainlist ]; then
				copydns=1
			else
				ec red "Warning: Domainlist not found. cannot copy dns back to old server!"
			fi
		fi
		#pull the trigger...
		ec blue "Press enter to begin final sync..."

		if [ $stopservices ]; then
		  ec yellow "Stopping Services..." 
		  ssh $sshargs $ip "[ -s /etc/init.d/chkservd ] && /etc/init.d/chkservd stop"
		  ssh $sshargs $ip  "/usr/local/cpanel/bin/tailwatchd --disable=Cpanel::TailWatch::ChkServd"
		  ssh $sshargs $ip "/etc/init.d/httpd stop"
		  ssh $sshargs $ip "/etc/init.d/exim stop"
		  ssh $sshargs $ip "/etc/init.d/cpanel stop"
		else
		 ec yellow "Not stopping services." 
		fi
		# copy dns back to old server
		if [ $copydns ]; then 
			ec yellow "Backing up /var/named to $remote_tempdir on remote server..."
		 	ssh $sshargs $ip "rsync -avqR /var/named $remote_tempdir/"
		 	ec yellow "Copying zone files back to old server..."
		 	for domain in $domainlist; do 
	 			sed -i -e 's/^\$TTL.*/$TTL 300/g' -e 's/[0-9]\{10\}/'`date +%Y%m%d%H`'/g' /var/named/*.db
		 		rsync $rsyncargs -e "ssh $sshargs" /var/named/$domain.db $ip:/var/named/
		 	done
		 	ssh $sshargs "rndc reload "
		 	#for the one time i encountered NSD
		 	nsdcheck=`ssh $sshargs $ip "ps aux |grep nsd |grep -v grep"`
		 	if [ "$nsdcheck" ]; then
		  		echo "Nsd found, reloading" 
		  		ssh $sshargs $ip "nsdc rebuild"
				ssh $sshargs $ip "nsdc reload"
		 	fi
		fi

		# actual data copying functions:
		mysql_dbsync
		user_count=1
		user_total=`echo $userlist |wc -w`
		for user in $userlist; do
			progress="$user_count/$user_total | $user:"
			rsync_homedir #needs to run in a userlist loop
			user_count=$(( $user_count+1 ))
		done
		mailman_copy

		#restart services
		if [ $restartservices ]; then
			ec yellow "Restarting Services..." 
			ssh $sshargs $ip "[ -s /etc/init.d/chkservd ] && /etc/init.d/chkservd start"
			ssh $sshargs $ip  "/usr/local/cpanel/bin/tailwatchd --enable=Cpanel::TailWatch::ChkServd"
			ssh $sshargs $ip "/etc/init.d/httpd start"
			ssh $sshargs $ip "/etc/init.d/exim start"
			ssh $sshargs $ip "/etc/init.d/cpanel start"
		else
		 ec yellow "Skipping restart of services." 
		fi
		#give cpanel time to spam to screen
		sleep 10

		ec yellow "== Actions Taken =="
		[ $stopservices ] && ec white "Stopped services."
		[ $restartservices ] && ec white "Restarted services."
		[ $copydns ] && ec white "Copied zone files back to old server."
	fi
	#mailperm
	echo "Fixing mail permissions..."
	screen -S mailperm -d -m /scripts/mailperm &
	#fix quotas
	echo "Fixing cpanel quotas..."
	screen -S fixquotas -d -m /scripts/fixquotas &


}


oldmigrationcheck() { #always run, to get old ip/port if needed.
	ec white "Checking for previous migration..."
	# if olddir is defined, there was a previous migration, or at least, the script ran once before.
	if [ $oldip ]; then
		ec yellow "Files from old migration found, dated $oldstarttime !"
		[ $oldip ] && ec yellow "Old IP: $oldip"
		[ $oldport ] && ec yellow "Old Port: $oldport"
		[ "$oldusercount" ] && ec yellow "Old User count: $oldusercount"
		[ "$someoldusers" ] && ec yellow "Some old users (not all): $someoldusers"
		if yesNo "Is $oldip the server you want? " ;then
		    echo "Ok, continuing with $oldip" 
		    ip=$oldip
		    echo $ip > $dir/ip.txt
		    getport
		else
		    getip 
		fi
	else
		echo "No previous migration found." #maybe list /home/temp/pullsync dirs?
		getip
	fi
}

getip() {
	echo
	echo -n 'Source IP: '; 
	read ip 
	echo $ip > $dir/ip.txt
	getport
	
}

getport() {
	if [ $oldport ]; then
		if yesNo "Use old Ssh port $oldport?"; then
			port=$oldport
		fi
	fi
	[ -z $port ] && echo -n "SSH Port [22]: " && read port
	if [ -z $port ]; then
		echo "No port given, assuming 22"
		port=22
	fi
	echo $port > $dir/port.txt
	sshargs="$sshargs -p$port"
	sshkeygen
}

sshkeygen() { 
	mkdir -p /root/.ssh
	# we're just going to ask for the password everytime, remove the key if it it was cancelled midway for some reason though.
	if [ -f /root/.ssh/pullsync.pub ]; then 
		rm -rf /root/.ssh/pullsync*
	fi
	ec yellow "Generating SSH key /root/.ssh/pullsync ..." 
	ssh-keygen -q -N "" -t rsa -f /root/.ssh/pullsync
	ec yellow "Copying Key to remote server..." 	
	# since we are using our own sshkey, we don't need to worry about overwriting others. we can just delete it when done. 
	ssh-copy-id -i ~/.ssh/pullsync.pub " -p $port $ip"
	#append our key pullsync.pub to sshargs
	sshargs="$sshargs -i /root/.ssh/pullsync"
	# now test the ssh connection 
	ec yellow "Testing ssh connection..."
	if ! ssh $sshargs $ip "true" ; then
		ec lightRed "Error: Ssh connection to $ip failed."
		ec lightCyan "Add pubkey from ~/.ssh/pullsync.pub to remote server, and press enter to retry"
		cat ~/.ssh/pullsync.pub
		read
		#fail here
		if ! ssh $sshargs $ip "true"; then
		  ec lightRed "Error: Ssh connection to $ip failed, please check connection before retrying!" |tee -a $dir/error.log
		  exitcleanup
		  # quit
		  exit 3
		fi
	fi
	ec lightGreen "Ssh connection to $ip succeded!"
	# command to remove the 'stdin: is not a tty' error that is annoying. append a bit to the top of /root/.bashrc on the source server. don't add more entries if it exists. '[ -z $PS1 ] && return'
	stdin_cmd="if ! grep -q '\[ -z "'$PS1'" \] && return' /root/.bashrc; then sed -i '1s/^/[ -z "'$PS1'" ] \&\& return\n/' /root/.bashrc ;fi"	
	ssh $sshargs $ip "$stdin_cmd"
	ssh $sshargs $ip "mkdir -p $remote_tempdir/"

}

getuserlist() { # get user list for different sync types
	ec yellow "Transferring some config files over from old server to $dir"
	# we need /etc/userdomains for the domainlist conversion, might as well get things now.
	rsync -R $rsyncargs -e "ssh $sshargs" $ip:"`echo $filelist`" $dir/ 2> /dev/null
	ssh $sshargs $ip "mkdir -p $remote_tempdir/"
	# a list of users
	if [ "$synctype" == "list" ];then 
		# list is stored locally
		if [ -f "$userlistfile" ];then
			userlist=`cat $userlistfile`
			for user in $userlist; do
					rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users/$user $dir/
			done
			getdomainlist
		else
			ec lightRed "Did not find $userlistfile!"
			exitcleanup
			exit 4
		fi
	# a list of domains
	elif  [ "$synctype" == "domainlist" ] ; then 
		if [ -f "$domainlistfile" ]; then
			cp -rp $domainlistfile $dir/
			#get users from a domainlist, $dir/etc/userdomains needs to exist already
			userlist=$(for domain in `cat $domainlistfile`; do 
		  		grep ^$domain $dir/etc/userdomains |cut -d\  -f2 
			done |sort |uniq )
			for user in $userlist; do
					rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users/$user $dir/
			done
			#generate domain list in $dir ( each domain in an acount may not have been given )
			getdomainlist
		else
			ec lightRed "Did not find /root/domainlist.txt!"
			exitcleanup
			exit 5
		fi
	#all users
	elif [ "$synctype" == "all" ] ; then 
		rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users $dir/
		userlist=`/bin/ls -A $dir/var/cpanel/users/ | egrep -v "^${badusers}$"`
		getdomainlist
	# single user
	elif [ "$synctype" == "single" ] ; then 
		rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users/$userlist $dir/
		ec yellow "What is the user you would like to migrate?"
		read userlist
		if ! [ -f "$dir/var/cpanel/users/$userlist" ];then 
			ec lightRed "User not found!"
			exitcleanup
			exit 6 
		fi
		getdomainlist
		if yesNo "Restore to dedicated ip?"; then
			single_dedip="yes"
		else
			single_dedip="no"
		fi

	elif [ "$synctype" == "final" ] ; then
		if [ -f $olddir/userlist.txt ] && [ $oldusercount -gt 0 ]; then
			ec lightGreen "Previous sync from ip $oldip at $oldstarttime found in $olddir/userlist.txt."
			ec yellow "Count of old users: $oldusercount"
			ec yellow "First 6 old users: $someoldusers"
			if yesNo "Are these users correct?"; then
				userlist=`cat $olddir/userlist.txt`
				rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users/$user $dir/
			fi
		fi
		[ -f /root/userlist.txt ] && userlist_count=`cat /root/userlist.txt |wc -w`
		if [ $userlist_count -gt 0 ] && [ ! $userlist ]; then
			ec lightGreen "Userlist found in /root/userlist.txt."
			userlist_some=`cat /root/userlist.txt | tr '\n' ' '| cut -d' ' -f1-6`
			ec yellow "Counted $userlist_count users."
			ec yellow "First 6 users found: $userlist_some"
			if yesNo "Are these users correct?"; then
				userlist=`cat /root/userlist.txt`
				rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users/$user $dir/
			fi
		fi
		if [ ! $userlist ]; then
			# no previous sync found, ask for all users?
			if yesNo "No userlist found, final sync all users?";then 
				rsync -R $rsyncargs -e "ssh $sshargs" $ip:/var/cpanel/users $dir/
				userlist=`/bin/ls -A $dir/var/cpanel/users/ | egrep -v "^${badusers}$" `
			else
				ec lightRed "Error: No userlist was defined, quitting."
				exitcleanup
				exit 1
			fi
		fi
		getdomainlist
	fi 
	echo $userlist > "$dir/userlist.txt"
	echo $userlist > /root/userlist.txt
	#check for conflicts 
	ec yellow "Checking for account conflicts..." 
	for user in $userlist ; do
		if [ -f "/var/cpanel/users/$user" ] && [ ! $synctype == "final" ]; then # if the user exists for an initial sync, fail out.
			ec lightRed  "Error: $user already exists on this server" | tee -a $dir/error.log
			exitcleanup
			exit 7
		elif [ ! -f "/var/cpanel/users/$user" ] && [ $synctype == "final" ]; then #if the user does not exist for a final sync, exit
			ec lightRed "Error: $user was selected for a final sync, but does not exist on this server!" |tee -a $dir/error.log
			exitcleanup
			exit 8
		fi
	done

}

getdomainlist() { #called as needed by getuserlist
	# get a domain list (for 'userlist', 'final', 'all')	
	domainlist=$(for user in $userlist; do
		grep ^DNS.*= $dir/var/cpanel/users/$user | cut -d= -f2
	done)
	echo $domainlist > $dir/domainlist.txt
}

dedipcheck() { # check for available/needed dedicated ip amount
	ec yellow "Checking for dedicated IPs..."
	source_ip_usage=`ip_usage $dir/`
	ip_count=`cat /etc/ips| wc -w` 
	ip_usage=`ip_usage /` # calling ip_usage function on /
	ips_free=$(( $ip_count-$ip_usage ))
	ec yellow "
	Dedicated ips in use for selected users on remote server: $source_ip_usage 
	Dedicated Ips in use on this Server:$ip_usage
	Total dedicated IPs on this server: $ip_count
	There are $ips_free available IPs on this server." 
	if [[ $source_ip_usage -lt $ips_free ]];then
	  ec lightGreen "There seems to be enough IPs on this server for the migration."
	else
	  ec lightRed "This server does not seem to have enough dedicated IPs." 
	fi
	if yesNo "Restore accounts to dedicated Ips?
no  = Restore accounts to the Main Shared Ip." ;then
	  ec lightGreen "Restoring accounts to dedicated IPs."
	  ded_ip_check=1
	else
	  ec lightGreen "Restoring accounts to the main shared Ip."
	  ded_ip_check=0
	fi
}

ip_usage() {
	ipcheckpath=$1
	main_ip=`cat ${ipcheckpath}etc/wwwacct.conf|grep ADDR|cut -d ' ' -f2`
	dedicated_ips=""
	if [ $ipcheckpath = "/" ];then
		ipcheck_userlist=`/bin/ls -A /var/cpanel/users/` # checking for free ips on this server
	else
		ipcheck_userlist=$userlist #checking for ips in use on remote server (from users selected to migrate)
	fi
	for user in $ipcheck_userlist ; do
		dedicated_ips="$dedicated_ips `grep ^IP= ${ipcheckpath}var/cpanel/users/$user |grep -v $main_ip | cut -d= -f2`"
	done 
	dedicated_ip_count=`echo $dedicated_ips |tr ' ' '\n' |sort |uniq |wc -w`
	echo $dedicated_ip_count
}

lower_ttls() { # should have a domainlist at this point, from getuserlist()
	ec yellow "Lowering TTLs for selected users..."
	# back up /var/named on remote server!
	ssh $sshargs $ip "rsync -aqH /var/named $remote_tempdir/"
	# we have /var/named from source server, run our seds locally to make things easier, then copy them back to original server.
	if [ -f $dir/domainlist.txt ]; then
		domainlist=`cat $dir/domainlist.txt`
		for domain in $domainlist; do
			if [ -f $dir/var/named/$domain.db ]; then
				sed -i -e 's/^\$TTL.*/\$TTL 300/g' $dir/var/named/$domain.db
				sed -i -e 's/[0-9]{10}/'`date +%Y%m%d%H`'/g' $dir/var/named/$domain.db
				#jwarrens A record reducer:
				sed -i -e 's/^\([\w.\-]+[^\S\n]+\)[0-9]+\([^\S\n]+IN[^\S\n]+A[^\S\n]+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*$\)/\1\Q300\E\2/g' $dir/var/named/$domain.db
				rsync $rsyncargs -e "ssh $sshargs" $dir/var/named/$domain.db $ip:/var/named/
			else
				ec red "Warning: Domain $domain not found while lowering TTLs, checked for $dir/var/named/$domain.db!" |tee -a $dir/error.log
			fi
		done
	else
		ec lightRed "Error: Domainlist not found $dir/domainlist.txt!" |tee -a $dir/error.log
	fi
	# reload rndc on remote server to lower ttls
	ssh $sshargs $ip "rndc reload ; [ `which nsdc 2>/dev/null` ] && nsdc rebuild && nsdc reload"
}

# ask if version matching will be needed. maybe check for version on remote server first

# check versions of local/remote software
getversions() {
	ec yellow "Running version detection"
	# store functions, couldn't find a better way to do this... 
	phpcmd='php -v |head -n1 | awk '\''{print $2}'\'' '
	mysqlcmd='mysqladmin ver |grep '\''^Server version'\'' |awk '\''{print $3}'\'' |cut -d. -f1-2 '
	httpcmd='httpd -v |grep version | awk '\''{print $3}'\'' |cut -d/ -f2'
	phphandlercmd='/usr/local/cpanel/bin/rebuild_phpconf --current |grep PHP5 |cut -d" " -f3'
	modsec_cmd='rpm -qa "*modsec*" '
	os_cmd='cat /etc/redhat-release'
	echo "Versions on local server `hostname`, $cpanel_main_ip:" |tee -a $dir/versionsLocal.txt
	# run the commands, load into variables
	localhttp=`eval $httpcmd`
	localmysql=`eval $mysqlcmd`
	localphp=` eval $phpcmd`
	localphphandler=` eval $phphandlercmd`
	localcpanel=`cat /usr/local/cpanel/version`
	localmodsec=`eval $modsec_cmd`
	local_os=`eval $os_cmd`
	#display:
	echo "	Local Http      : $localhttp
	Local Php       : $localphp
	Local Phphandler: $localphphandler
	Local Mysql     : $localmysql
	Local Cpanel    : $localcpanel
	Local Modsec    : $localmodsec
	Local OS        : $local_os
	" | tee -a $dir/versionsLocal.txt

	#for a remote server:
	remotehostname=`ssh $sshargs $ip "hostname"`
	echo "Versions on $remotehostname $ip:" |tee -a $dir/versionsRemote.txt
	remotehttp=`ssh $sshargs $ip "eval $httpcmd"`
	remotemysql=`ssh $sshargs $ip "eval $mysqlcmd"`
	remotephp=`ssh $sshargs $ip "eval $phpcmd"`
	remotephphandler=`ssh $sshargs $ip "eval $phphandlercmd"`
	remotecpanel=`cat $dir/usr/local/cpanel/version`
	remotemodsec=`ssh $sshargs $ip "eval $modsec_cmd"`
	remote_os=`ssh $sshargs $ip "eval $os_cmd"`
	echo "	Remote Http      : $remotehttp
	Remote Php       : $remotephp
	Remote Phphandler: $remotephphandler
	Remote Mysql     : $remotemysql
	Remote Cpanel    : $remotecpanel
	Remote Modsec    : $remotemodsec
	Remote OS        : $remote_os
	" | tee -a $dir/versionsRemote.txt
	ec yellow "Please press enter to continue."
	read

	ec yellow "Checking for 3rd party apps..." 
	# Check for stuff we can install
	ffmpeg=`ssh $sshargs $ip "which ffmpeg"`
	imagick=`ssh $sshargs $ip "which convert"`
	memcache=`ssh $sshargs $ip "ps aux | grep -e 'memcache' | grep -v grep | tail -n1 "`
	java=`ssh $sshargs $ip "which java 2>1 /dev/null"`
	postgres=`ssh $sshargs $ip "ps aux |grep -e 'postgres' |grep -v grep |tail -n1"`
	#other stuff , probably a better way to do this
	xcache=`ssh $sshargs $ip "ps aux | grep -e 'xcache' | grep -v grep | tail -n1"`
	eaccel=`ssh $sshargs $ip "ps aux | grep -e 'eaccelerator' | grep -v grep |tail -n1"`
	nginx=`ssh $sshargs $ip "ps aux | grep  -e 'nginx' |grep -v grep| tail -n1"`
	lsws=`ssh $sshargs $ip "ps aux | grep  -e 'lsws' | grep -v grep | tail -n1"`	
	if [ "${xcachefound}${eaccelfound}${nginxfound}${lswsfound}" ]; then
		ec yellow '3rd party stuff found on the old server!'  
		[ "$xcachefound" ] && echo "Xcache: $xcachefound" 
		[ "$eaccelfound" ] && echo "Eaccelerator: $eaccelfound" 
		[ "$nginxfound" ] && echo "Nginx: $nginxfound" 
		[ "$lswsfound" ] && echo "Litespeed: $lswsfound"
		ec yellow 'It is up to you to install these. Press enter to continue.'
		read
	fi

	# Dns check
	ec yellow "Checking Current dns..." 
	if [ -f $olddir/dns.txt ]; then
	 echo "Found $olddir/dns.txt" 
	 cp $olddir/dns.txt $dir/
	 cat $dir/dns.txt | sort -n +3 -2 | more
	else
	  	for domain in $domainlist; do 
	  		echo $domain\ `dig @8.8.8.8 NS +short $domain |sed 's/\.$//g'`\ `dig @8.8.8.8 +short $domain` ;
	  	done | grep -v \ \ | column -t > $dir/dns.txt
	  cat $dir/dns.txt | sort -n +3 -2 | more
	fi
	ec yellow "Press enter to continue."
	read

	# nameserver check 
	ec yellow "Old servers nameserver settings:"
	grep ^NS[\ 0-9] $dir/etc/wwwacct.conf
	ec yellow "Current nameserver settings:"
	grep ^NS[\ 0-9] /etc/wwwacct.conf
	if yesNo "Set old nameservers to this server?"; then
		sed -i -e '/^NS[\ 0-9]/d' /etc/wwwacct.conf
		grep ^NS[\ 0-9]  $dir/etc/wwwacct.conf >> /etc/wwwacct.conf
	fi

	# SSL cert checking.
	ec yellow "Checking for SSL Certificates in apache conf..." 
	if grep -q SSLCertificateFile $dir/usr/local/apache/conf/httpd.conf ; then
		ec yellow "SSL Certificates detected." 
		for domain in $domainlist; do 		
			# sed -n "/VirtualHost.*\:443/,/\/Virtualhost/ { /ServerName.*rebcky.com/,/\/VirtualHost/  { s/.*SSLCertificateFile \(.*.crt\)/\1/p } }" /home/temp/pullsync/usr/local/apache/conf/httpd.conf
			for crt in `grep SSLCertificateFile.*/$domain.crt $dir/usr/local/apache/conf/httpd.conf |awk '{print $2}'`; do
				echo $dir/$crt; openssl x509 -noout -in $crt -issuer  -subject  -dates 
				ec yellow "Press enter to continue."
				read
		 	done
		 done
	else
		echo "No SSL Certificates found in httpd.conf." 
	fi

	# check for dnsclustering
	ec yellow "Checking for DNS clustering..." 
	if [ -f $dir/var/cpanel/useclusteringdns ]; then
		ec yellow 'Remote DNS Clustering found! Press enter to continue.' 
	 	read 
	fi
	if [ -f /var/cpanel/useclusteringdns ]; then
		 ec lightRed "DNS cluster on the local server is detected, you shouldn't continue since restoring accounts has the potential to automatically update DNS for them in the cluster. Probably will be better to remove or disable clustering before continuing." 
		echo 'Press enter to continue.' 
	 	read 
	else
	 	ec yellow "No Local DNS clustering found."
	fi

	# space check
	ec yellow "Comparing free space to used space of old server."
	ssh $sshargs $ip "df /home/ | tail -n1" > $dir/df.txt # Filesystem            Size  Used Avail Use% Mounted on
	remote_used_space=`cat $dir/df.txt | awk '{print $3} '` #convert to gb? since we could potentially be shown TB or other.
	local_free_space=`df /home |tail -n1 | awk '{print $4}'`
	if [[ $remote_used_space -gt $local_free_space ]] ; then 
		ec lightRed 'There does not appear to be enough free space on this server when comparing the home partitions! '
		ec yellow "Press enter to continue." 
		read
	fi

	# cpbackup check
	if [ ! "$synctype" = "shared" ]; then
		backup_acct=`grep ^BACKUPACCTS /etc/cpbackup.conf | awk '{print $2}' `
		backup_enable=`grep ^BACKUPENABLE /etc/cpbackup.conf | awk '{print $2}'`
		if [ $backup_enable = "yes" ] && [ $backup_acct = "yes" ]; then
			ec yellow "Cpanel backups are enabled."
		else
			ec yellow "Cpanel backups are disabled." 
			if yesNo "Do you want to enable cpanel backups?"; then
			    sed -i.syncbak -e 's/^\(BACKUPACCTS\).*/\1 yes/g' -e 's/^\(BACKUPENABLE\).*/\1 yes/g' /etc/cpbackup.conf
			fi
		fi
	fi

	# cloudlinux
	if echo $remote_os | grep -q -i cloud ; then
		ec lightRed "Cloud linux detected on remote server. Press enter to continue."
		read
	fi

}

installs() {
	ec yellow "Downloading lwbake and plbake..."
	wget -q -O /scripts/lwbake http://layer3.liquidweb.com/scripts/lwbake
	chmod 700 /scripts/lwbake
	wget -q -O /scripts/plbake http://layer3.liquidweb.com/scripts/plBake/plBake
	chmod 700 /scripts/plbake
	#upcp
	if [ $upcp ]; then
		ec yellow "Running Upcp..."
		"/scripts/upcp"
	fi
	#java
	if [ "$java" ];then
		ec yellow "Installing Java..."
		screen -S java -d -m /scripts/plbake java
	fi
	#postgres
	if [ "$postgres" ]; then
	 	ec yellow "Installing Postgresql..."
		#use expect to install since it asks for input
		cp -rp /var/lib/pgsql{,.bak.$starttime}
	 	expect -c "spawn /scripts/installpostgres
		expect \"Are you sure you wish to proceed? \"
		send \"yes\r\"
		expect eof"
		rsync $rsyncargs -e "ssh $sshargs" $ip:/var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/
		/scripts/restartsrv_postgres
	fi
	#mysql
	if [ $mysqlup ]; then
		ec yellow "Reinstalling mysql..."
		sed -i.bak /mysql-version/d /var/cpanel/cpanel.config
		echo mysql-version=$newmysqlver >> /var/cpanel/cpanel.config
		cp -rp /etc/my.cnf{,.bak.$starttime}
		if [ $newmysqlver > 5 ]; then
			sed -i -e /safe-show-database/d -e /skip-locking/d /etc/my.cnf
		fi
		cp -rp /var/lib/mysql{,.bak.$starttime}
		if [ $localcpanel > 11.36.0 ]; then
			/usr/local/cpanel/scripts/check_cpanel_rpms --targets=MySQL50,MySQL51,MySQL55 --fix
		else
			/scripts/mysqlup --force
		fi
		ec yellow "Verifying mysql is started..."
		if service mysql status ;then
			ec lightRed "Mysql failed to start, ensure it starts before restoring accounts!"
		else
			echo "Mysql update completed, EA will need to be ran."
			mysqlupcheck=1
		fi
	fi
	#ea
	if [ $ea ]; then
		ec yellow "Running EA..."
		#copy the EA config
		rsync $rsyncargs -e "ssh -p$port" $ip:/var/cpanel/easy/apache/ /var/cpanel/easy/apache/
		/scripts/easyapache --build
	 	unset mysqlupcheck
	fi
	phpextras
	# ffmpeg
	if [ "$ffmpeg" ] ; then
		ec yellow "Installing ffmpeg..." 
		# fork it off into a screen since it takes a while
 		screen -S ffmpeg -d -m /scripts/lwbake ffmpeg-php 
	fi
	#imagick
	if [ $imagick ] ; then
		echo "Installing imagemagick..." 
		/scripts/lwbake imagemagick
		/scripts/lwbake imagick
		/scripts/lwbake magickwand
	fi
	#memcache
	if [ "$memcache" ]; then
		ec yellow "Installing memcache..." 
		wget -O /scripts/confmemcached.pl http://layer3.liquidweb.com/scripts/confMemcached/confmemcached.pl
		chmod +x /scripts/confmemcached.pl
		/scripts/confmemcached.pl --memcached-full
		service httpd restart
	fi

	# pear
	ec yellow "Matching PEAR packages..."
	ssh $sshargs $ip "pear list" | egrep [0-9]{1}.[0-9]{1} | awk '{print $1}' > $dir/pearlist.txt
	cat $dir/pearlist.txt |xargs pear install $pear

	# ruby gems
	ec yellow "Matching ruby gems..."
	ssh $sshargs $ip "gem list" | tail -n+4 | awk '{print $1}' > $dir/gemlist.txt
	cat $dir/gemlist.txt | xargs gem install



}
# nameserver comparison in /etc/wwwacct.conf
# apache extra file check
# cpanel backup check

# package/copy accounts/sync/final sync
package_accounts() { #for initialsyncs
	ec yellow "Packaging cpanel accounts externally and restoring on local server..." 
	> $hostsfile
	> $hostsfile_alt
	old_main_ip=`grep ADDR $dir/etc/wwwacct.conf | awk '{print $2}'`
	mkdir -p $dir/tmp/
	user_count=1
	user_total=`echo $userlist |wc -w`
	for user in $userlist; do
		restorepkg_args=""
		progress="$user_count/$user_total | $user:"
		old_user_ip=`grep ^IP= $dir/var/cpanel/users/$user|cut -d '=' -f2`
		ec lightBlue "${progress} Packaging $user" | tee -a $dir/pkgacct.log
		ssh $sshargs $ip "/scripts/pkgacct --skiphomedir $user $remote_tempdir " >> $dir/pkgacct.log
		cpmovefile=`ssh $sshargs $ip "find $remote_tempdir/ -maxdepth 1 -name cpmove-$user.tar.gz -mtime -1 |head -n1"`
		# verify a package was found
		if [ $cpmovefile ]; then
			ec lightPurple "$progress Rsyncing cpmove $cpmovefile"
			rsync $rsyncargs -e "ssh $sshargs" $ip:$cpmovefile $dir/tmp/
			if ([[ $old_user_ip != $old_main_ip ]] && [ "$ded_ip_check" = "1" ]) || [ "$single_dedip" = "yes" ]; then
				restorepkg_args="--ip=y"
			fi
			ec lightCyan "$progress Restoring $cpmovefile" | tee -a $dir/restorepkg.log
			/scripts/restorepkg $restorepkg_args $dir/tmp/cpmove-$user.tar.gz 2>&1 >> $dir/restorepkg.log
			mv $dir/tmp/cpmove-$user.tar.gz $dir/
			rsync_homedir
			hosts_file $user
		else
			# cpmove file was not found
			ec lightRed "Error: Did not find backup file for user $user!" |tee -a $dir/error.log
			echo $user >> $dir/did_not_restore.txt
		fi
		user_count=$(( $user_count+1 ))
	done
}

rsync_homedir() { # ran in a user in $userlist loop, for initial/final syncs.  package_accounts() 
	userhome_remote=`grep ^$user: $dir/etc/passwd | tail -n1 |cut -d: -f6`
	userhome_local=`grep ^$user: /etc/passwd | tail -n1 |cut -d: -f6`
	# check if cpanel user exists
	if [ -f $dir/var/cpanel/users/$user ] && [ -f /var/cpanel/users/$user ] && [ -d $userhome_local ]; then
		ec lightGreen "$progress Rsyncing homedir from ${ip}:${userhome_remote} to $userhome_local."
		rsync $rsyncargs $rsync_update $rsync_excludes -e "ssh $sshargs" $ip:$userhome_remote/ $userhome_local/
	else
		ec red "Warning: Cpanel user $user not found! Not rsycing homedir." |tee -a $dir/error.log
		ec yellow "Running \`tail $dir/restorepkg.log\`, check for errors!"
		tail $dir/restorepkg.log
	fi
}

mysql_dbsync(){ #for final syncs
	ec yellow "Dumping databases..."
	if [ "$userlist" ]; then
		dblist_restore="" # use for storing all db names to restore later.
		for user in $userlist; do
			echo "Dumping dbs for $user..."
			ssh $sshargs $ip "mkdir -p $remote_tempdir/dbdumps"
			# get list of dbs for user
			if [ -f $dir/var/cpanel/databases/$user.yaml ]; then
				# get from yaml file if it exists with this goofy sed. will grab dbs that are not obviously owned by user.  
				dblist=`sed -e '/MYSQL:/,/dbusers:/!d' $dir/var/cpanel/databases/$user.yaml |tail -n +3 |head -n -1 |cut -d: -f1 |tr -d ' '`
			else
				# var/cpanel/databases, may not exist in really old vps, fall back to old way.
				dblist=`ssh $sshargs $ip "mysql -e 'show databases'| grep ^$user\_ "`
			fi

			echo "Found dbs: $dblist"
			dblist_restore="$dblist_restore $dblist"
			mysqldumpver=`ssh $sshargs $ip 'mysqldump --version |cut -d" " -f6 |cut -d, -f1'`
			for db in $dblist; do 
				if [[ $mysqldumpver > 5.0.42 ]]; then
					mysqldumpopts="--opt --routines --force --log-error=$remote_tempdir/dbdumps/dump.log"
				else
					mysqldumpopts="--opt -Q"
				fi
				if ! ssh $sshargs $ip "service mysql status" ; then
					ec lightRed "Mysql does not seem to be running on remote server, please fix and press enter to continue!"
					read
				fi
				echo "Dumping $db on remote server..."
				ssh $sshargs $ip "mysqldump $mysqldumpopts $db > $remote_tempdir/dbdumps/$db.sql"
			done
		done
		echo "Rsyncing dbs over..."
		rsync $rsyncargs -e "ssh $sshargs" $ip:$remote_tempdir/dbdumps $dir/
		mkdir -p $dir/pre_dbdumps
		for db in $dblist_restore; do
			echo "Backing up $db to $dir/pre_dbdumps..."
			mysqldump --opt --routines $db > $dir/pre_dbdumps/$db.sql
			echo "Restoring $db..."
			mysql $db < $dir/dbdumps/$db.sql
		done
	else
		echo "Userlist not found for mysql sync!?"
	fi
}

hosts_file() {
	user=$1
	ec yellow "Generating hosts file entries for $user"
	if [ -f /var/cpanel/users/$user ]; then
		user_IP=`grep IP /var/cpanel/users/$user |cut -d= -f2`
		user_domains=`grep ^DNS /var/cpanel/users/$user |cut -d= -f2 `
		#per user way
		echo "# $user" |tee -a $hostsfile
		echo -n "$user_IP " | tee -a $hostsfile
		echo $user_domains | while read DOMAIN ; do
			echo -n "$DOMAIN www.$DOMAIN "
	  	done | tee -a $hostsfile
	  	echo "" | tee -a $hostsfile
		#one line per domain
		for domain in $user_domains; do
			echo "$user_IP $domain www.$domain" >> $hostsfile_alt
		done
	else
	  ec lightRed "Cpanel user file for $user not found, not generating hosts file entries!" |tee -a $dir/error.log
	fi
}
mysqlversion() {
	ec yellow "Remote Mysql 	   : $remotemysql"
	ec yellow "Current local Mysql : $localmysql"
	#check major.minor version of mysql
	if [ $localmysql == $remotemysql ];then
		ec green "Mysql versions match!"
	else
		ec red "Mysql versions do not match."
	fi
	if yesNo "Change local Mysql version?"; then
		mysqlverloop=0
		while [ $mysqlverloop == 0 ]; do 
		    ec lightBlue "Available mysql versions:"
		    ec white " 5.1"
			ec white " 5.5"
		    echo -e "Please input desired mysql version, or x to cancel: " # older than 5.1 isn't supported in 11.40+
		    read newmysqlver
		    case $newmysqlver in 
		    	5.1|5.5)
					ec green "Mysql will be changed to $newmysqlver"
					mysqlup=1
					mysqlverloop=1;;
				x)
					ec yellow "Mysql version will not be changed."
					mysqlverloop=1;;
				*) 
					ec lightRed "Incorrect input, try again." ;;
			esac
		done
	fi


}
phpversion () {
	if [ $remotephp ] && [ $localphp ]; then
		# store versions in an array #{ea_php_versions[0]}
		ea_php_versions=(`/scripts/easyapache --latest-versions |grep PHP -A1 |tail -n1 |sed 's/,//g'`)
		count=0
		# generate menu
		phpversion_loop=0
		while [ $phpversion_loop == 0 ]; do 
			ec yellow "Remote php        : $remotephp"
			ec yellow "Current local php : $localphp"
			ec lightBlue "Select your desired php version from the following list:"
			while [ $count -lt ${#ea_php_versions[@]} ] ; do
				phpver=${ea_php_versions[$count]}
				count=$(( $count + 1 )) # add here, so we offset the array by +1, so we get options starting at 1
				ec white "$count) $phpver"
			done
			# offer php 5.2?
			# ec white "5.2) 5.2.17 (Custom Cpanel Module)"
			ec white "x) No change (EA may put you to the newest version)"
			echo -n "Choose: "
			read phpversion_choice
			# test if choice was valid, goofy bash regex here. 
			if [[ $phpversion_choice =~ [1-${#ea_php_versions[@]}] ]] || [ "$phpversion_choice" = "x" ] ;then # || [ $phpversion_choice = "5.2" ];then
				phpversion_loop=1
			else
				ec red "Invalid choice."
				count=0
			fi
		done
		if [ ! $phpversion_choice = "x" ]; then
			# subtract 1 from the choice to get the proper array reference
			phpversion_choice=$(( $phpversion_choice-1 ))
			ec lightGreen "Selected ${ea_php_versions[$phpversion_choice]}" 
			major=$(echo ${ea_php_versions[$phpversion_choice]} | cut -d. -f1)
			minor=$(echo ${ea_php_versions[$phpversion_choice]} | cut -d. -f2)
			patch=$(echo ${ea_php_versions[$phpversion_choice]} | cut -d. -f3)
			newline="Cpanel::Easy::PHP${major}::${minor}_${patch}:"
			#echo "Selected PHP version=${newline}" 
			# back up existing _main.yaml
			cp -rp /var/cpanel/easy/apache/profile/_main.yaml $dir/
			# This will make all current versions 0's.
			sed -i -e 's/\(Cpanel::Easy::PHP[0-9]::[0-9]\+_[0-9]\+\:\ \)/\10/g' /var/cpanel/easy/apache/profile/_main.yaml
			# add the desired version to the _main.yaml
			if grep -q ${newline} /var/cpanel/easy/apache/profile/_main.yaml; then
				sed -i "s/${newline} 0/${newline} 1/" /var/cpanel/easy/apache/profile/_main.yaml
			else
				echo "${newline} 1" >> /var/cpanel/easy/apache/profile/_main.yaml
			fi 
		else
			ec lightGreen "Skipped php version change."
		fi
	else
		ec lightRed "Local or remote php version not detected! Skipping version change. Press Enter to continue."
		read
	fi
}
postgres_install_check() {
	# check to install posgres
	if [ "$postgres" ]; then
		if [ -d /var/lib/pgsql ]; then
			ec yellow "Postgres found on this server already!"
			unset postgres
		else
			if yesNo "Postgres detected on old server, install postgres locally?";then 
				ec lightGreen "Postgres selected for installation."
			else
				ec lightGreen "Postgres will not be installed."
				unset postgres
			fi
		fi
	fi
}

phpextras () { # run after EA
	# phphandler
	ec yellow "Matching php handler..." 
	# we pretty much only care about the php5 handler.  php 4 is no more as far as we are concerned. never seen suexec disabled eitehr.
	/usr/local/cpanel/bin/rebuild_phpconf 5 none $remotephphandler 1 > /dev/null
	phphandler_check=`/usr/local/cpanel/bin/rebuild_phpconf --current |grep PHP5\ SAPI: |cut -d" " -f3`
	if [ ! "$remotephphandler" = "$phphandler_check" ]; then
		ec lightRed "Warning: Phphandler not set to $remotephphandler, please double check!" | tee -a $dir/error.log
	fi
	# Memory limit
	remotephp_memory_limit=`sed -n 's/^memory_limit.*=\ \?\([0-9]\+[A-Z]\?\)\ \+;.*/\1/p' $dir/usr/local/lib/php.ini`
	ec yellow "Setting php memory_limit to $remotephp_memory_limit"
	sed -i "s/^\(memory_limit\ =\ \)[0-9]\+[A-Z]\?/\1$remotephp_memory_limit/" /usr/local/lib/php.ini
	# max execution time
	remotephp_max_execution_time=`sed -n 's/^max_execution_time.*=\ \?\([0-9]\+[A-Z]\?\)\ \+;.*/\1/p' $dir/usr/local/lib/php.ini`
	ec yellow "Setting php max_execution_time to $remotephp_max_execution_time"

	sed -i "s/^\(max_execution_time\ =\ \)[0-9]\+[A-Z]\?/\1$remotephp_max_execution_time/" /usr/local/lib/php.ini
}

upcp_check() { #
	echo "Checking Cpanel versions..." 
	#upcp if local version is higher than remote
	if  [[ $localcpanel > $remotecpanel ]]; then
		echo "This server has $localcpanel" 
		echo "Remote server has $remotecpanel" 
		if yesNo "Run Upcp on this server?" ; then
			echo "Upcp will be ran when the sync begins." 
			upcp=1
		fi
	else
	    echo "Found a higher version of cpanel on remote server, continuing."
	fi
}

modsec_rules_check(){
	# we check for modsec rpm versions back in getversions
	if [ "$localmodsec" != "$remotemodsec" ]; then
		ec yellow "Remote modsec version $remotemodsec different from local version $localmodsec. Please press enter to continue."
		read 
	else
		# copy over if modsec2 (apache 1 no longer supported by ea) if whitelist file is not empty on this server.
		if [[ "$localmodsec" =~ "lp-modsec2-rules" ]];then
			if [ ! -s "/usr/local/apache/conf/modsec2/whitelist.conf" ]; then #whitelist.conf is not a non-zero size
				cat $dir/usr/local/apache/conf/modsec2/whitelist.conf >> /usr/local/apache/conf/modsec2/whitelist.conf
			else
				ec yellow "Existing content found in /usr/local/apache/conf/modsec2/whitelist.conf, not importing."		
			fi
		fi
	fi
}

mailman_copy() {
	# will come over with initial sync, just needed in final sync.
	[ ! $userlist ] && return;
	for user in $userlist; do 
		# found list data in /var/cpanel/datastore/$user/mailman-list-usage, just reference the data for the user already restored. may not exist on old cp versions. 
		if [ -f "/var/cpanel/datastore/$user/mailman-list-usage" ]; then
			mailinglists=`cat /var/cpanel/datastore/$user/mailman-list-usage |cut -d: -f1`
			for list in mailinglists; do 
				# list data is in /usr/local/cpanel/3rdparty/mailman/lists/$list
				rsync $rsyncargs -e "ssh $sshargs" $ip:/usr/local/cpanel/3rdparty/mailman/lists/$list /usr/local/cpanel/3rdparty/mailman/lists/
				# archive data is in /usr/local/cpanel/3rdparty/mailman/archives/private/$list{,.mbox}
				rsync $rsyncargs -e "ssh $sshargs" $ip:"/usr/local/cpanel/3rdparty/mailman/archives/private/$list{,.mbox}" /usr/local/cpanel/3rdparty/mailman/archives/private/
			done
		fi
	done
}

# check for failed restores

# logging function
logit() { 
	tee -a $log; 
}

exitcleanup() {
	rm -rf ~/.ssh/pullsync*
}

control_c() {
  #if user hits control-c 
  echo
  echo "Control-C pushed, exiting..." | tee -a $dir/error.log
  exitcleanup
  exit 200
}

trap control_c SIGINT
# start the script after functions are defined.

main | logit

exitcleanup

echo
ec lightGreen "Done!"
