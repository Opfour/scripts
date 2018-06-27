#!/bin/bash
#This script will monitor system processes, and once finds a process using more then allowed cpu resources, it will automatically invoke "cpulimit" to renice the process.

#Requirements:
#bash, cpulimit http://dl.sourceforge.net/sourceforge/cpulimit/cpulimit-1.1.tar.gz
#(http://aur.archlinux.org/packages.php?d … amp;SeB=nd),
#top(procps), grep, cut(coreutils)
#Code:

THRESHOLD=90
LIMIT=60
TIMEOUT=8

IFS="
"

while true; do
        top_out=$(top -b -n 1 -i | grep "^\s\+[0-9]")
        
        for i in $top_out; do
                cpu_usage=$(echo -n "$i" | cut -b 42-43)
                
                if [ "$cpu_usage" -gt "$THRESHOLD" ]; then
                        pid=$(echo -n "$i" | cut -b 1-6)
                        cpulimit -p "$pid" -l "$LIMIT" -z >& /dev/null &
                        echo " cpulimit pid=$pid (current cpu usage=$cpu_usage)"
                fi
        done
        
        sleep $TIMEOUT
done

# for
# get top process using cpu resource more then THRESHOLD
# xor with WHITE_LIST
#WHITE_LIST="" # not implement
# xor with BLACK_LIST
#BLACK_LIST="" # not suitable if we limit by PID
# cpulimit it & add to BLACKLIST
# sleep TIMEOUT (default = 15)
# loop

#ps. you can put this in /etc/rc.local
#     (remember to add a "&" to put it in to the background, or you will not be able to finish booting)

#ps2. cpulimit is better executed with root permission, or it will make some problems.

#Hope this helps,

 
