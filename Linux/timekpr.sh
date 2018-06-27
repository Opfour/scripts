#!/bin/bash
###
# timekpr.sh - simple 
# watches gnome sessions and logs them out once the user has exceeded a set, per day limit
# /var/lib/timekpr/$username.time hold a count of seconds user has had a gnome session
# /var/lib/timekpr/$username hold the daily allowed seconds for the user
#
# you may need to install notify-send with: $apt-get install libnotify-bin
#
# Copyright 2008 Chris Jackson <chris@91courtstreet.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# See <http://www.gnu.org/licenses/>. 
#
#install
#mv timekpr.txt timekpr.sh
#chmod 755 timekpr.sh
#sudo mv timekpr.sh /usr/local/bin
#Next make a directory for the time tracking files and limits:
#sudo mkdir /var/lib/timekpr
#I added a line to /etc/rc.local
#/usr/local/bin/timekpr &
#to start the script after a re-boot.
#to limit someone’s per day usage, just add the number of seconds they will be allowed to a file in /var/lib/timekpr
#sudo echo 7200 > /var/lib/timekpr/username
#where username is the account you want to time limit.
#


default_limit=87000 #all day
grace_period=450
poll_time=20

#Ubuntu uses alternatives so we look for x-session-manager instead of gnome-session
SESSION_MANAGER=x-session-manager

# get the usernames and PIDs of sessions

while(true); do
    sleep $poll_time
    pidlists=$( ps --no-heading -fC $SESSION_MANAGER | awk 'BEGIN{ FS=" " } { print $1 "," $2 }' )
    for pidlist in $pidlists; do
        # split username and pid - FIXME - I bet this would be faster with bash arrays and substitution 
        username=$( echo $pidlist | awk 'BEGIN{ FS=","} { print $1}' )
        pid=$( echo $pidlist | awk 'BEGIN{ FS=","} { print $2}' )
        if [[ ! -e "/var/lib/timekpr/$username" ]]
        then 
            echo $default_limit > /var/lib/timekpr/$username
        fi
        
        # if the time file is missing or was last touched yesterday, start over
        if [[ -e "/var/lib/timekpr/$username.time" && `( stat -c '%z' /var/lib/timekpr/$username.time|cut -c9,10 )` == `date +%d` ]]
        then 
            #add $poll_time seconds to it
            timekpr=$(( `cat /var/lib/timekpr/$username.time` + $poll_time ))
            echo $timekpr > /var/lib/timekpr/$username.time
        else
        	timekpr=$poll_time
            echo $timekpr > /var/lib/timekpr/$username.time
        fi

        echo $username, $pid, $timekpr
        
        if [[ $timekpr -gt `cat /var/lib/timekpr/$username` ]]
        then
            ## get the display and xauthority used by out session manager
            UDISPLAY=`grep -z DISPLAY \
                /proc/$pid/environ | sed -e 's/DISPLAY=//'`
            XAUTHORITY=`grep -z XAUTHORITY \
                /proc/$pid/environ | sed -e 's/XAUTHORITY=//'`
            
            # find DBUS session bus for this session
            DBUS_SESSION_BUS_ADDRESS=`grep -z DBUS_SESSION_BUS_ADDRESS \
                /proc/$pid/environ | sed -e 's/DBUS_SESSION_BUS_ADDRESS=//'`
            # use it - give a warning, then another one 1/2 way through grace_period
            XAUTHORITY="$XAUTHORITY" DISPLAY="$UDISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
                notify-send --icon=gtk-dialog-warning --urgency=critical -t 30000 "Daily Time Limit" "Your session time is about to expire! You have $grace_period sec. to save your work and logout."
            sleep $(($grace_period/2))   # FIXME: this gives other sessions a free grace_period added to their accounting

            XAUTHORITY="$XAUTHORITY" DISPLAY="$UDISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
                notify-send --icon=gtk-dialog-warning --urgency=critical -t 30000 "Daily Time Limit" "Your session time is about to expire! You have $(($grace_period/2)) sec. to save your work and logout."
            sleep $(($grace_period/2))   # FIXME: this gives other sessions a free grace_period added to their accounting

            XAUTHORITY="$XAUTHORITY" DISPLAY="$UDISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
                notify-send --icon=gtk-dialog-warning --urgency=critical -t 10000 "Shutting Down" "Shutting down session ($pid) now!" 
            # FIXME - should really check to see if user has logged out yet 
            sleep 10
            kill -HUP $pid    #this is a pretty bad way of killing a gnome-session, but we warned 'em
            
            ## uncomment the following to brutally kill all of the users processes
            sleep 10
            pkill -u $username  
            
            ## killing gnome-session should be more like:
            #DISPLAY=":0" XAUTHORITY="/tmp/.gdmEQ0V5T" SESSION_MANAGER="local/wretched:/tmp/.ICE-unix/$pid" su -c 'gnome-session-save --kill --silent' $username
            ## but this can still leave processes to cleanup - plus it's not easy to get SESSION_MANAGER
        fi
    done
done
