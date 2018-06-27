#!/bin/bash
cd /root; wget http://cptechs.info/system-snapshot/sys-snap.sh 
chmod +x sys-snap.sh
nohup sh sys-snap.sh &

#The logs will be kept here:
#/root/system-snapshot

#You can view and edit the code to tweak it as any other shell script.

#To stop it, you must kill the process:
#kill `ps aux|grep sys-sna[p]|awk '{print $2}'`

#The script does not use noticeable resources, but if you need to find the PID and kill it, this will:

#kill `ps aux|grep sys-sna[p]|awk '{print $2}'`
