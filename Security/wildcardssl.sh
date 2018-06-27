#Wildcard SSL Installation Script - Us administrators eventually come to the realization that when you have a wildcard SSL certificate for 40 subdomains, you can’t practically have separate IPs and cPanel accounts for all of them. If you have a wildcard SSL certificate for all your subdomains, you can easily install the certificate on a single IP address for all the subdomains. For this particular scenario to work:

#All subdomains must be on the same IP and cPanel account
#You must have a wildcard SSL qualifying for *.tld.com

#Keep in mind that for a wildcard SSL to work, it really does have to be installed for each subdomain. You can’t install it once and have it automatically work in the fly like wildcard DNS does – Apache just doesn’t work that way.  

#Luckily, we’ve scripted an easy solution for you.

#Create the following files:

#/etc/ssl/certs/tld.crt

#This file will contain the actual certificate, and should be named off of your top-level domain. For example, if the certificate is for *.mydomain.com, name the file mydomain.com.crt

#/etc/ssl/certs/tld.cabundle

#This file will be the CA bundle for your wildcard certificate, if you have one.  If the certificate is for *.mydomain.com, name the file mydomain.com.cabundle

#Now download the install script from here.

#!/bin/bash
# Script to install wildcard SSL on a single IP for each subdomain
# usage: <scriptname> <domain>

if [ $# -ne 1 ]
then
        echo “Usage: `basename $0` <parent domain>”
        exit 1
else
        domain=$1
fi

sslfile=”/etc/ssl/certs/$domain.crt”
cafile=”/etc/ssl/certs/$domain.cabundle”

if [[ ! -s $sslfile ]] || [[ ! -s $cafile ]];then
        echo “Missing or empty SSL or CA  bundle file”
        exit 1;
fi

user=$(/scripts/whoowns $domain)
ip=$(cat /etc/domainips | grep $domain |awk ‘{print $1}’ |cut -d: -f1)
olddocroot=$(cat /var/cpanel/userdata/$user/{$domain}_SSL |grep documentroot |awk ‘{print $2}’ | head -1)

if [ ! -f $sslfile ]; then
        echo “SSL template file does not exist”
        exit 1
elif ! grep $domain /etc/trueuserdomains >/dev/null; then
        echo “Domain provided is not a primary domain”
        exit 1
fi


sublist=$(cat /etc/userdomains | grep $domain | awk ‘{print $1}’ | cut -d: -f1 | sed “/^\$domain$/d”)

for sub in $sublist
do

        userdata=”/var/cpanel/userdata/$user/$sub”
        userdatassl=”/var/cpanel/userdata/$user/${sub}_SSL”

        if [ ! -f $userdata ];then
                echo “Userdata file missing for $sub”
        else
                docroot=$(cat $userdata |grep documentroot |awk ‘{print $2}’ | head -1)

                scp -p /var/cpanel/userdata/$user/{$domain}_SSL $userdatassl
                replace USER $user — $userdatassl
                replace SUB $sub — $userdatassl
                replace DOMAIN $domain — $userdatassl
                replace DOCROOT $docroot — $userdatassl
                replace IP $ip — $userdatassl
                #cat $sslfile | awk -F: -v OFS=: ‘/^documentroot/{$2 = “‘” $docroot”‘”}1’ $userdatassl
                #replace “documentroot: $olddocroot” “documentroot: $docroot” — $userdatassl
        fi
done
echo “rebuilding httpdconf”
sleep 1
/scripts/rebuildhttpdconf
sleep1
echo “httpdconf rebuilded”

#Please make a copy of /var/cpanel/userdata before running the script for the first time, until you’ve verified that it works on your setup.

#This is basically just a bash script that you can use to install a wildcard SSL for a domain. Running it will install the certificate on all subdomains of the domain passed to the script:

#chmod 755 wildcardssl.sh
#./wildcardssl.sh $domain

#After it runs, all you need to do is restart Apache.   Please note that this script would need to be run again if more subdomains are added later on.
