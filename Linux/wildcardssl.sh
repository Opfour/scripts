#!/bin/bash
# Script to install wildcard SSL on a single IP for each subdomain
# usage: <scriptname> <domain>
# ThecPanelAdmin.com 11/24/2010

if [ $# -ne 1 ]
then
	echo "Usage: `basename $0` <parent domain>"
	exit 1
else
	domain=$1
fi

sslfile="/etc/ssl/certs/$domain.crt"
cafile="/etc/ssl/certs/$domain.cabundle"

if [[ ! -s $sslfile ]] || [[ ! -s $cafile ]];then
	echo "Missing or empty SSL or CA  bundle file"
	exit 1;
fi

user=$(/scripts/whoowns $domain)
ip=$(cat /etc/domainips | grep $domain |awk '{print $1}' |cut -d: -f1)
olddocroot=$(cat $sslfile |grep documentroot |awk '{print $2}' | head -1)

if [ ! -f $sslfile ]; then
	echo "SSL template file does not exist"
	exit 1
elif ! grep $domain /etc/trueuserdomains >/dev/null; then
	echo "Domain provided is not a primary domain"
	exit 1
fi


sublist=$(cat /etc/userdomains | grep $domain | awk '{print $1}' | cut -d: -f1 | sed "/^\$domain$/d")

for sub in $sublist
do

	userdata="/var/cpanel/userdata/$user/$sub"
	userdatassl="/var/cpanel/userdata/$user/${sub}_SSL"

	if [ ! -f $userdata ];then
		echo "Userdata file missing for $sub"
	else
		docroot=$(cat $userdata |grep documentroot |awk '{print $2}' | head -1)

		scp -p $sslfile $userdatassl
		replace USER $user -- $userdatassl
                replace SUB $sub -- $userdatassl
                replace DOMAIN $domain -- $userdatassl
                replace DOCROOT $docroot -- $userdatassl
                replace IP $ip -- $userdatassl
		#cat $sslfile | awk -F: -v OFS=: '/^documentroot/{$2 = "'" $docroot"'"}1' $userdatassl
		#replace "documentroot: $olddocroot" "documentroot: $docroot" -- $userdatassl		
	fi
done

/scripts/rebuildhttpdconf

