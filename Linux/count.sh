#!/bin/bash

#if [ -e "script.lock" ]; then
#echo "Lock file detected, euthanizing self."
#exit
#fi

#touch script.lock

echo "Waiting 10 seconds:"
for x in {1..10}; do 
	echo -n $x.. && sleep 1
done

echo
echo "Now clear ARP and run the following command:"
echo "xm create -c /etc/xen/auto/$HOSTNAME.cfg"

exit 0
