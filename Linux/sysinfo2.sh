#System Information Checker
#Displays Server Info
#Created By: Mark Benedict
#!/bin/bash

csfinstalled=$(csf -v|awk '{print $1}'|tr -d ':')
apfinstalled=$(apf -v |head -1|awk '{print $1}')


function csfcheck {
               if [[ $csfinstalled -eq csf ]];
                  then
			echo Up To Date
		else
			echo -e "$(tput setaf 1) Version Outdated! Latest - $wpcurrver $(tput sgr0)"
		fi
           }

function apfcheck {
               if [[ $apfinstalled -eq apf ]];
                  then
			APF is Installed
		else
			echo -e "$(tput setaf 1) Version Outdated! Latest - $wpcurrver $(tput sgr0)"
		fi
           }


function firewallcheck {
               if [[ $apfinstalled -eq apf ]];
                  then
	          echo APF is Installed
		elif [[ $csfinstalled -eq csf ]];
                  then
                  echo CSF is installed
			echo -e "$(tput setaf 1) No Firewall Detected! $(tput sgr0)"
		fi
           }




clear
echo "System Information Checker - v0.1"
echo "Mark Benedict"
echo "------------------------------------------"
echo "Server Name - `hostname`"
echo "Server Time - `date`"
echo "------------------------------------------"
echo "Basic Hardware -"
echo "CPU/s Availible: `lscpu |grep "CPU(s):" |awk '{ print $2 }' |egrep -v '[a-z]|[A-Z]'|awk '{s+=$1} END {print s}'`@ `cat /proc/cpuinfo |grep @ | awk '{ print $9 }'`"
echo "RAM  Availible: `free -m |sed -n '2p' |awk '{ print $2 }'`MB"
echo "Harddrive: `df -h |sed -n '1p'| awk '{ print $2,$3,$4,$5 }'` "
echo "             `df -h |sed -n '2p'| awk '{ print $2, $3,$4,$5 }'` "
echo ""
echo "Cpanel Details -"
echo "Cpanel Version: `/usr/local/cpanel/cpanel -V`"
echo "Domains/Subdomains: `cat /etc/userdomains | awk '{print $1}' | wc -l`"
echo ""
echo "Linux Details -"
echo "OS Version:  `cat /etc/*release |head -1`"
echo "Kernel Version: `uname -r`"
echo ""
echo "Apache Details -"
echo "Apache Version: `httpd -v |awk '{ print $3 }' |head -1`"
echo ""
echo "Mysql Details -"
echo "Mysql Version: `mysql -V |awk '{ print $5 }'`"
echo ""
echo "PHP Details -"
echo "PHP Version: `php -v |grep "(built:" |awk '{ print $2 }'`"
echo "PHP Handler: `/usr/local/cpanel/bin/rebuild_phpconf --current |grep "PHP5 SAPI:" |awk '{ print $3 }'`"
echo "memory_limit: `php -i |grep memory_limit |awk '{ print $5 }'`"
echo "upload_max_filesize: `php -i |grep upload_max_filesize |awk '{ print $5 }'`"
echo ""
echo "Perl Details -"
echo "Perl Version: `perl -v |grep "This is perl," |awk '{ print $4 }'`"
echo ""
echo "Python Details -"
echo "`python --version` "
