#!/bin/bash
# written by benjamin cathey 20090214

# script for changing DNS on ALL zone files on a server to use the same nameserver pair

dns1="ns1.exampledomain.com"
dns2="ns2.exampledomain.com"

####################################################################

cdate=$(date +%Y%m%d)
records=$(find /var/named -maxdepth 1 -name "*.db" | sort)
count=0
tcount=$(echo $records | wc -w)

for record in $records
do
   zone=$(basename $record | sed 's/\.db//')
   count=$(( $count + 1 ))
   echo "changing $zone ($count/$tcount)"
   linnum=$(sed -n '/IN\ *\t*NS/ =' $record)
   linnum=$(echo $linnum | awk '{print $1}')

# replace all NS records in the zone file with $dns1 and $dns2
   sed -i "/IN\ *\t*NS/d" $record
   sed -i "$linnum i $zone\.\ 14400\ IN\ NS\ $dns1\." $record
   sed -i "$(( $linnum + 1 )) i $zone\.\ 14400\ IN\ NS\ $dns2\." $record

# fix SOA line

   sed -i "/SOA/s/\(.*\)ns[0-9]*\.[^\ ]*\.[^\ ]*\.\(.*\)/\1$dns1.\2/" $record

# reserialize

   sed -i "/[sS]erial/s/[0-9]\{10\}/"$cdate"25/" $record
   rndc reload $zone
done
