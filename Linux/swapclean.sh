#!/bin/bash
#Swap Cleaner
#Watches swap usage
#If there is swapping going on and there is enough free (+cache) ram, then turn swap off and back on.
#Created by James Dooley
#Feature / Bug requests jdooley@lw
 
#User Assigned Variables
 
swapthresh=0	#Swap threshold for clearing swap. Will not clear until this value is hit. Good for servers that normally allocates small amounts of swap for some reason.
freethresh=0	#Real free (free+cached) - current swap threshold. Ensures that atleast x bytes are free before clearing. 
loadthresh=0	#Load threshold, will not clear if above this value (unless 0)
logrotate=1000	#Max number of lines in the log file
####
 
function plog {
	echo "[ `date` ][ $curswap; $curfree; $realload ] $1" >> /var/log/swapclean
	if [ "`wc -l /var/log/swapclean | awk '{print $1}'`" -gt "$logrotate" ]
	then
		sed -i -e "1d" /var/log/swapclean
	fi
	return
}

function clearswap {
	plog "Clearing swap"
	touch /var/run/.swapoff
	echo $$ > /var/run/.swapoff
	/sbin/swapoff -a && /sbin/swapon -a
	rm -f /var/run/.swapoff
	plog "Swap Cleared"
	return
}
 
function checkswap {
 
	curswap=`free | fgrep "Swap:" | awk '{print $3}'`
	curfree=`free | fgrep "buffers/cache:" | awk '{print $4}'`
	realload=`cat /proc/loadavg | awk '{print $1}'`
	curload=`echo "$realload * 100" | bc | sed 's/[.].*//'`
	loadthresh=`echo "$loadthresh *100" | bc | sed 's/[.].*//'`
	swapdif=`expr $curfree - $curswap`
 
	if [ "$swapthresh" -lt "$curswap" ]
	then
		#Server has swapped and is above its threshold
		if [ "$freethresh" -lt "$swapdif" ]
		then
			#Free - Swap is greater then freethresh
			if [ "$curload" -lt "$loadthresh" -o "$loadthresh" -eq 0 ]
			then
				#Load is below threshold
				if [ ! -e "/var/run/.swapoff" ] 
				then
					clearswap
				else	
					plog "Lock file found, swap may be already clearing"
					opid=`cat /var/run/.swapoff`
					if [ ! "`ps ax | grep $opid | grep ${0##*/}`" ]
					then
						plog "PID not active or not owned by swapclean, clearing pid file"
						rm -f /var/run/.swapoff
						clearswap
					else
						plog "Swap already being cleared, PID active"
					fi
				fi
			else
				plog "High load, waiting to clear swap"
			fi
		else
			plog "Not enough free memory, waiting to clear swap"
		fi
	fi
	return
}

function enablecron {
	if [ -e "/etc/cron.d/swapclean.sh" ]
	then
		echo "Cron already enabled, use change to set new time"
	else
		echo "What time would you like to set the cron to"
		echo "[IE: */10 * * * * ]"
		read crontime;
		if [ ! $crontime ] 
		then
			crontime="*/10 * * * *"
		fi
		echo "SHELL=/bin/bash" > /etc/cron.d/swapclean.sh
		echo "$crontime root $(readlink -f $0)" >> /etc/cron.d/swapclean.sh
		chmod 0644 /etc/cron.d/swapclean.sh
		echo "Cron enabled [$crontime root $(readlink -f $0)]"
		return
	fi
	return
}
 
function disablecron {
	if [ -e "/etc/cron.d/swapclean.sh" ]
	then
		rm -f /etc/cron.d/swapclean.sh
		echo "Cron disabled"
	else
		echo "Cron not enabled"
	fi
 	return
}
 
 
case $1 in
        --cron)
                case $2 in
			on)
				enablecron
				;;
			off)
				disablecron
				;;
			change)
				disablecron
				enablecron
				;;
		esac
                ;;
        --help)
                echo "Check swap usage:"
		echo " --cron [on, change, off]"
		echo "	on: Turns on cron job and asks for time"
		echo "	change: Changes the cron time"
		echo "	off: Turns off the cron job"
                ;;
        *)
                checkswap
                ;;
  esac
