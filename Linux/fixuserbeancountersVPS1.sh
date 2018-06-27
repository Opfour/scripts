echo "THIS ONLY IS USED FOR VPS1 INSTANCES!!"
echo "This WILL restart the instance, make sure the customer is aware!"
echo "Which instance (VEID) would you like to fix?"
vzlist -a
read VEID

vzctl set $VEID --kmemsize 2147483647 --save
vzctl set $VEID --lockedpages 2147483647 --save
vzctl set $VEID --privvmpages 2147483647 --save
vzctl set $VEID --shmpages 2147483647 --save
vzctl set $VEID --numproc 2147483647 --save
vzctl set $VEID --physpages 2147483647 --save
vzctl set $VEID --vmguarpages 2147483647 --save
vzctl set $VEID --oomguarpages 2147483647 --save
vzctl set $VEID --numtcpsock 2147483647 --save
vzctl set $VEID --numflock 2147483647 --save
vzctl set $VEID --numpty 2147483647 --save
vzctl set $VEID --numsiginfo 2147483647 --save
vzctl set $VEID --tcpsndbuf 2147483647 --save
vzctl set $VEID --tcprcvbuf 2147483647 --save
vzctl set $VEID --othersockbuf 2147483647 --save
vzctl set $VEID --dgramrcvbuf 2147483647 --save
vzctl set $VEID --numothersock 2147483647 --save
vzctl set $VEID --dcachesize 2147483647 --save
vzctl set $VEID --numfile 2147483647 --save
vzctl set $VEID --numfile 2147483647 --save

vzctl restart $VEID

echo "The instance has been reset."

