#/bin/bash

cat /etc/trueuserdomains | sort -t" " -k2 > LIST.txt
exec 7<> LIST.txt
for i in `cat /etc/trueuserdomains | awk '{ print $2 }' | sort`; do
read <&7
DAT=$(date +%S%H%M%S)
NAM=`echo $i | awk '{ print substr($1,3) }'`
/scripts/chpass $i "#"$NAM$DAT
echo $REPLY "#"$NAM$DAT >> pass
sleep 1
done
/scripts/ftpupdate
