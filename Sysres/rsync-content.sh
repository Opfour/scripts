#!/bin/bash
# written by benjaminC 20110520
# rsync /home/$user/public_html content from one server 
# to a set of primary hosts with --primary or -p 
# and --secondary or -s to sync also to secondary hosts
#
# generally sec_hosts servers are either a dev environ
# or an offsite hot copy or disaster recovery setup

# primary hosts private IPs in a space separated list
# these are the hosts this server will be syncing to
# ex: pri_hosts="192.168.0.1 192.168.0.2"
pri_hosts=""

# secondary hosts private IPs in a space separated list
# these are the other hosts this server will be syncing
# to - normally a dev environment
# ex: sec_hosts="192.168.0.10 192.168.0.20"
sec_hosts=""

# email to notify in case of rsync failure
email="rsync-monitor@picard.ent.liquidweb.com"

########################################################

# set trap for cleanup
trap control_c SIGINT SIGTERM SIGKILL

# setup OIFS so that we can fix rsync logging later
OIFS=$IFS

# program name
prog=$(basename $0)

# lockfile
lock_file="/var/run/$prog"
# run log
run_log="/var/log/$prog.log"
# capture PID of script
pid=$$

# get account_link
if [ -e "/usr/local/lp/etc/lp-UID" ]; then
	lpuid=$(cat /usr/local/lp/etc/lp-UID)
	account_link="https://billing.int.liquidweb.com/mysql/content/admin/search.mhtml?search_input=${lpuid}&search_submit=Search"
fi

function control_c() {
  rlog " ** $prog :: caught trap :: exiting ** "
  cleanup
  exit 1
}

function rlog() {
	string="[`date +%Y%m%d_%H%M%S`] :: ($pid) :: $1"
	echo "$string" >> $run_log
	echo "$string"
	# keep log size small
	if [ "`wc -l $run_log | awk '{print $1}'`" -gt "10000" ]; then
		sed -i -e "1d" $run_log
	fi
}


function check_running(){
	if [ -e "$lock_file" ]; then
		old_pid=$(cat $lock_file)
		if [ "`ps axo pid | grep "$old_pid" | grep -v grep`" ]; then
			rlog "$prog :: still running (pid:$old_pid) :: exiting"
			exit 1
		else
			rlog "$prog :: stale lock file (pid:$old_pid) :: removing"
			rm -f $lock_file
		fi
	fi
	echo $pid > $lock_file
}

function get_users(){
	users=( `cat /etc/domainusers | cut -d':' -f1 | sort` )
	user_count="${#users[@]}"
}

function run_sync(){
	if [ "$1" = "primary" ]; then
		rlog "$prog :: run_sync primary"
		hosts="$pri_hosts"
	else
		rlog "$prog :: run_sync secondary"
		hosts="$sec_hosts"
	fi
	rlog "  total users: $user_count"
	count=1
	for user in ${users[@]}
	do
		rlog "    [$count/$user_count] $user"
		for host in $hosts
		do
			rlog "     * rsync to $host"
			IFS=$'\n'
			rsync_lines=$(eval rsync --quiet --delete-after -avHl /home/$user/public_html/ root@$host:/home/$user/public_html/ 2>&1)
			exit_status="$?"
			for line in $(echo "$rsync_lines" | grep -v "stdin: is not a tty")
			do
				rlog "         $line"
			done
			if [ "$exit_status" -ne "0" ] && [ "$email" ]; then
				rlog "$prog :: rsync failed :: notifying $email"
				echo -e "Account: $account_link\nHost: $host\nUser: $user\n\n$rsync_lines" | mail -s "`hostname` :: $prog failed :: user: $user, host: $host" $email
			fi
			IFS=$OIFS
		done
		let count=$count+1
	done
}

function cleanup(){
	rlog "$prog :: completed"
	rm -f $lock_file
	IFS=$OIFS
}

function help(){
	echo "usage: $prog [-p|--primary] [-s|--secondary]"
	echo
	echo "  -p, --primary     performs sync to primary hosts"
	echo "  -s, --secondary   performs sync to secondary hosts"
	echo
}


if [ $# -eq 0 ]; then
	rlog "$prog :: no arguments passed :: exiting"
	echo
	help
	exit 1
fi

check_running
get_users


while [ $# -gt 0 ]
do
	case "$1" in
	-p|--primary)
		run_sync primary
		shift 1
	;;

	-s|--secondary)
		run_sync secondary
		shift 1
	;;
	-ps)
		run_sync primary
		run_sync secondary
		shift 1
	;;
		*)
		help
		shift 1
	;;
	esac
done

cleanup
