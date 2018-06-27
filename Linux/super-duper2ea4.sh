#!/bin/bash

#Global Variables

#Sets conf locations for variables used to reference the right location when using EA4 or EA3
HOST=`hostname`
	if [ -f /etc/cpanel/ea4/is_ea4 ]; then
		DOMLOGDIR='/var/log/apache2/domlogs'
                HTTPD='/etc/apache2/conf/httpd.conf'
                APACHEINCLUDE='/etc/apache2/conf.d/includes'
                ERRORLOG='/var/log/apache2'
	else
		DOMLOGDIR='/home/domlogs'
                HTTPD='/usr/local/apache/conf/httpd.conf'
                APACHEINCLUDE='/usr/local/apache/conf/includes'
                ERRORLOG='/usr/local/apache/logs'  
      fi

PHP=`php -i | grep php.ini | grep "Configuration" | cut -d ">" -f2 | cut -c 2- | tail -n 1`
MYSQL='/etc/my.cnf'
DATE=$(date +%d/%b/%Y)
#Creates variable for the Plesk Apache configuration
HTTPDP='/etc/httpd/conf/httpd.conf'



###Colors
#Creates variable for red color
Red='\e[0;31m'
#Creates variable for bold red color
RedBold='\e[1;31m'
#Creates variable for green color
Green='\e[0;32m'
#Creates variable for yellow color
Yellow='\e[1;33m'
#Creates variable for purple color
Purple='\e[1;35m'
#Creates variable for no color
NoColor='\e[0m'
#End Global Variables


#Main Menus

function welcome_screen
{
    echo "     _______. __    __  .______    _______ .______          _______   __    __  .______    _______ .______                          "
    echo "    /       ||  |  |  | |   _  \  |   ____||   _  \        |       \ |  |  |  | |   _  \  |   ____||   _  \                         "
    echo "   |   (---- |  |  |  | |  |_)  | |  |__   |  |_)  |       |  .--.  ||  |  |  | |  |_)  | |  |__   |  |_)  |                        "
    echo "    \   \    |  |  |  | |   ___/  |   __|  |      /        |  |  |  ||  |  |  | |   ___/  |   __|  |      /                         "
    echo ".----)   |   |  ---'  | |  |      |  |____ |  |\  \----.   |  '--'  ||  ---'  | |  |      |  |____ |  |\  \----.                    "
    echo "|_______/     \______/  | _|      |_______|| _| \._____|   |_______/  \______/  | _|      |_______|| _| \._____|                    "
    echo "                                                                                                                                    "
    echo "     _______. _______ .______     ____    ____  _______ .______              _______.___________.    ___   .___________.    _______."
    echo "    /       ||   ____||   _  \    \   \  /   / |   ____||   _  \            /       |           |   /   \  |           |   /       |"
    echo "   |   (-----|  |__   |  |_)  |    \   \/   /  |  |__   |  |_)  |          |   (--------|  |-----  /  ^  \ ----|  |-----  |   (-----"
    echo "    \   \    |   __|  |      /      \      /   |   __|  |      /            \   \       |  |      /  /_\  \    |  |        \   \    "
    echo ".----)   |   |  |____ |  |\  \----.  \    /    |  |____ |  |\  \----.   .----)   |      |  |     /  _____  \   |  |    .----)   |   "
    echo "|_______/    |_______|| _| \______|   \__/     |_______|| _| \______|   |_______/       |__|    /__/     \__\  |__|    |________/   "
    echo ""
    echo "                                                By Joel Parks (JWeezy)                               "
    echo "                                                                                                     "
    echo ""      
    echo ""                                  
    echo ""
    echo ""
    echo ""
    echo -e "$Red@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@@                                                                                        @@"
    echo "@@ It is possible to increase load on your server by running                              @@"
    echo "@@ certain portions of this script, in particular the exim queue check                    @@"
    echo "@@ as well as any domlog diving (basically anything below the safe option).               @@"
    echo "@@                                                                                        @@"
    echo "@@ Please email jparks@liquidweb for comments and suggestions.                            @@"
    echo "@@                                                                                        @@"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$NoColor"
    echo ""
    echo "Please choose which type of server that you are currenlty  logged into from the options below."
    echo ""
    echo " (1) I am using a Cpanel Server"
    echo " (2) I am using a Plesk Server"
    echo " (3) Exit"
    read welcome_menu_option


case $welcome_menu_option in
	1)
		clear
		cpanel_menu
		;;
	2)
		clear
		plesk_menu
		;;
	3)
		clear
		echo "Have a nice day!"
		exit
		;;
	*)
		clear
		echo "Ah ah ah, thats not an option"
		sleep 3
		welcome_screen
		;;
esac

}

function cpanel_menu
{
	while :
	do
    
    echo ""
    echo "Currently your load is:"
    echo ""     
	w
    echo ""
    echo "What would you like to see?:"
    echo ""
    echo " (1) All Cpanel Stats"
    echo " (2) Load Safe Cpanel Stats"
    echo " (3) Crawler and Bot Check"
    echo " (4) Wordpress Brute Force"
    echo " (5) Joomla Brute Force"
    echo " (6) Domain Traffic"
    echo " (7) Exim Info"
    echo " (8) MySQL Info"
    echo " (9) Exit"
    echo -n "Select option: "
    read cpanel_menu_option

    if ! [ $cpanel_menu_option -ge 1 -a  $cpanel_menu_option -le 9 ];then
        echo "Ah ah ah, thats not an option"
    sleep 3    
    clear
	cpanel_menu
	read null
    fi

    if [ $cpanel_menu_option = "1" ]; then
        clear
	cpanel_all
    fi

    if [ $cpanel_menu_option = "2" ]; then
        clear
	cpanel_safe
    fi

    if [ $cpanel_menu_option = "3" ]; then
        clear
	cpanel_bot
    fi

    if [ $cpanel_menu_option = "4" ]; then
        clear
	cpanel_wordpress
    fi

    if [ $cpanel_menu_option = "5" ]; then
        clear
	cpanel_joomla
    fi

    if [ $cpanel_menu_option = "6" ]; then
        clear
	cpanel_domlogs
    fi

    if [ $cpanel_menu_option = "7" ]; then
        clear
	cpanel_exim
    fi
    
    if [ $cpanel_menu_option = "8" ]; then
	clear
	cpanel_mysql
    fi
    if [ $cpanel_menu_option = "9" ]; then
        clear
	echo "Have a nice day!"
        sleep 2
	clear
	exit
    fi
done
}



function plesk_menu
{



	while :
	do
    echo " Currently Your load is:"
    echo ""
    echo ""
            w
    echo ""
    echo ""
    echo " What would you like to see?:"
    echo ""
    echo ""
    echo " (1) All Plesk Stats"
    echo " (2) Load Safe Plesk Stats"
    echo " (3) Crawler and Bot Check"
    echo " (4) Wordpress Brute Force"
    echo " (5) Joomla Brute Force"
    echo " (6) Domain Traffic"
    echo " (7) Mail Queue"
    echo " (8) Exit"
    echo -n "Select option: "
    read plesk_menu_option

    if ! [ $plesk_menu_option -ge 1 -a  $plesk_menu_option -le 8 ];then
        echo ""
	echo ""
	echo ""
	echo "Ah ah ah, thats not an option"
        sleep 3
	clear
	plesk_menu
    fi

    if [ $plesk_menu_option = "1" ]; then
        clear
	plesk_all
    fi

    if [ $plesk_menu_option = "2" ]; then
        clear
	plesk_safe
    fi

    if [ $plesk_menu_option = "3" ]; then
        clear	
	plesk_bot
    fi

    if [ $plesk_menu_option = "4" ]; then
        clear
	plesk_wordpress
    fi

    if [ $plesk_menu_option = "5" ]; then
        clear
	plesk_joomla
    fi

    if [ $plesk_menu_option = "6" ]; then
        clear
	plesk_domlogs
    fi

    if [ $plesk_menu_option = "7" ]; then
        clear
	plesk_mail
    fi
    
    if [ $plesk_menu_option = "8" ]; then
        clear
	echo "Have a nice day!"
        exit
    fi
done



}



#END MAIN MENUS


# The following are the called functions for Cpanel

function cpanel_all
{

	#Prints test title
	echo -e "\n$Red=== Version Info ===$NoColor\n"

	#Prints hostname
	echo -e "Hostname: $HOST"

	#Prints OS version of the server
	if [ -f /etc/redhat-release ]
	   then echo "OS Version: `cat /etc/redhat-release`"
	elif [ -f /etc/lsb-release ]
	   then echo "OS Version: `cat /etc/lsb-release | sed -n 4p | awk -F\= '{print $2}' | sed 's/"//g'`"
	else echo -e "Neither CentOS or Ubuntu Dectected"
	fi


	#Creates variable for kernel version
	KERVER=`uname --kernel-release`
	#Creates variable for kernel architecture
	KERARCH=`uname --hardware-platform`

	#Prints kernel Information
	echo "Kernel Version: $KERVER $KERARCH"

	#Prints cPanel version
	echo "cPanel Version: `/usr/local/cpanel/cpanel -V | awk '{print $1}'`"

	#Prints Apache version
	echo "Apache Version: `httpd -v`"

	#Prints PHP version
	echo "PHP Version: `/usr/local/bin/php --version | grep --color=never cli | awk '{print $2}'`"

	#Prints MySQL version
	echo "MySQL Version: `mysqladmin version | grep --color=never "Server version" | awk '{print $3}' | sed 's/-cll//'`"
         
                #prints current mail queue
        echo -e "\n\e[0;32m=== Current Mail in Queue ===\e[0m\n"
        exim -bpc



	echo -e "\n$Green=== Disk Space Usage ===$NoColor\n"

	#Prints the current disk space
	df --human-readable

	echo -e "\n$Yellow=== Current Memory Usage ===$NoColor\n"

	#Prints the current disk usage
	free -m
	
	echo -e "\n$Purple=== Number of Processors ===$NoColor\n"

	#Prints the number of CPU cores
	grep --count proc /proc/cpuinfo

	echo -e "\n$Red=== PHP Info ===$NoColor\n"

	#Prints common PHP settings values
	for each in memory_limit max_execution_time max_input_time post_max_size upload_max_filesize max_file_upload; do egrep $each $PHP; done | sed -e 's/;.*//' -e '/^\s*$/d'

	echo -e "\n$RedBold=== PHP Handler ===$NoColor\n"

	#Prints current PHP handler
	/usr/local/cpanel/bin/rebuild_phpconf --current

	echo -e "\n$Green=== Number of PHP Processes ===$NoColor\n"

	#Prints the currently running PHP processes
	ps faux | grep php -c | grep --invert-match grep

	echo -e "\n$Red=== Apache Configuration ===$NoColor\n"

	#Prints the current Apache Multi-Processing Module
	echo -e "`httpd -V | grep --color=never MPM | grep --invert-match DIR`\n"

	#Checks for common Apache settings and their values in the httpd.conf and prints them
	grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $HTTPD

        PREMAIN=$(grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $APACHEINCLUDE/pre_main_global.conf); if [[ $? == 0  ]]; then echo -e "pre_main_global.conf:\n$PREMAIN\n"; fi


        PREVHOST=$(grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $APACHEINCLUDE/pre_virtualhost_global.conf); if [[ $? == 0  ]]; then echo -e "pre_virtualhost_global.conf:\n$PREVHOST\n"; fi


        POSTVHOST=$(grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $APACHEINCLUDE/post_virtualhost_global.conf); if [[ $? == 0  ]]; then echo -e "post_virtualhost_global.conf:\n$POSTVHOST\n"; fi


	echo -e "\n\e[1;31m=== MaxClients Hits ===\e[0m\n"
	grep MaxClients $ERRORLOG/error_log |tail

	echo -e "\n$Green=== Last Ten Graceful Restarts ==$NoColor\n"

	#Prints the last ten graceful restarts
	grep Graceful $ERRORLOG/error_log | tail

	echo -e "\n$Yellow=== Number of SYN connections ===$NoColor\n"

	#Prints the number of syn connections currently active
	netstat --numeric --all --program | grep SYN | wc --lines

	echo -e "\n$Purple=== Top 10 SYN Connections by IP ===$NoColor\n"

	#Prints the top ten syn flood connections
	netstat --tcp --numeric 2>/dev/null | grep SYN | awk '{print $5}' | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//'


	#Prints top ten apache connections
	echo -e "\n\e[0;31m=== Top 10 Connections to Apache (Port 80) ===\e[0m\n"
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | head | sed 's/^ *//'

	#Prints Incoming port 80 connections
	echo -e "\n\e[1;31m=== Port 80 Connections ===\e[0m\n"
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") c=c+1}END{print c}' # grep :80 | wc -l

	#Prints number of IPs connected
	echo -e "\n\e[0;32m=== Number of IPs Connected ===\e[0m\n"
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | wc -l

	#Prints WP-login post attempts by domain
	echo -e "\n\e[1;33m=== WordPress Brute Force ===\e[0m\n"
	grep -s wp-login.php $DOMLOGDIR/* | grep POST | grep "$(date +"%d/%b/%Y")" | cut -d: -f1 | sort| uniq -c | sort -nr | head | sed 's/^ *//g'
	
	#Prints Joomla Brite Force post attempts
	echo -e "\n\e[1;31m=== Joomla Brute Force ===$NoColor\n"
	 CMSC=`grep --extended-regexp --no-messages '/administrator/index.php' $DOMLOGDIR/* | grep POST | grep "$(date +"%d/%b/%Y")"`
        JMLCMSC=`echo "$CMSC" | grep --extended-regexp --color=never '/administrator/index.php' | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'`

        #Checks if any Joomla logins attempts were found, if so it continues
        if [[ -n "$JMLCMSC"  ]]
           #Prints results
           then echo -e "\e[4mJoomla\e[24m\n\n$JMLCMSC\n"
        	else echo "No Joomla Brute Forcing Detected"
	fi


	#Prints Mysql Connections
	echo -e "\n\e[1;35m=== Number of MySQL Connections ===\e[0m\n"
	netstat -nap | grep -i sql.sock | wc -l

	#Prints MySQL Queries
	echo -e "\n\e[0;31m=== MySQL Database Queries ===\e[0m\n"
	mysqladmin proc stat

	#Prints Top MySQL Databases
	echo -e "\n\e[1;31m=== MySQL Databases ===\e[0m\n"
	du --max-depth=1 /var/lib/mysql | sort -nr | cut -f2 | xargs du -sh 2>/dev/null | head | cut -d "/" -f1,5

	#Last 10 MySQL errors
	echo -e "\n\e[0;32m=== MySQL Errors ===\e[0m\n"
	cat /var/lib/mysql/${HOST}.err | tail

	#Prints current MySQL connections
	echo -e "\n\e[1;33m=== MySQL Connections ===\e[0m\n"
	mysql -e 'show status;' |grep --color=never connect

	#Prints important MySQL configuration variables
	echo -e "\n\e[1;35m=== MySQL Configuration ===\e[0m\n"
	egrep 'max_connections|max_heap_table_size|tmp_table_size|query_cache_size|timeout|table_cache|open_files|thread|innodb' $MYSQL
	

	#Prints MySQL Table types and sizes
        echo -e "\n\e[1;33m=== MySQL Table Types and Sizes ===\e[0m\n"; mysql -e "show engines;" | grep DEFAULT | awk '{print $2" MYSQL ENGINE = "$1}'; mysql -e "SELECT engine, count(*) tables, concat(round(sum(table_rows)/1000000,2),'M') rows, concat(round(sum(data_length)/(1024*1024*1024),2),'G') data, concat(round(sum(index_length)/(1024*1024*1024),2),'G') idx, concat(round(sum(data_length+index_length)/(1024*1024*1024),2),'G') total_size, round(sum(index_length)/sum(data_length),2) idxfrac FROM information_schema.TABLES GROUP BY engine ORDER BY sum(data_length+index_length) DESC LIMIT 10;";

	#Prints max cpu and piped log info from cpanel
	echo -e "\n\e[0;31m=== cPanel Settings ===\e[0m\n"
	egrep -i 'piped|extracpus' /var/cpanel/cpanel.config


	#Prints top fifteen bot and crawler hits using perl for speed



echo -e "\n\e[1;31m=== Potentially Naughty Bots (robots or crawlers) ===\e[0m\n"; find $DOMLOGDIR -type f | grep -vE '(_|-)log|\.gz' | xargs -n1 grep -H '' | perl -ne 'if (/$DATE/ && /$DOMLOGDIR.*\/(.*):(\d{1,3}(?:\.\d{1,3}){3}).*\((?:.*?;)*([^;]*(?:b(?:ot|ing)|crawl|yahoo|google|spider)[^;]*);/i) { print ("$1\t$2\t$3\n")}' | sort | uniq -c | sort -rn | awk '{print $1" "$3" "$4" "$2}' | column -t | head -n15

	#Setting local variables

 
	POST=`grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|grep POST|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n1 | awk '{print $2}'| cut -d '/' -f6`

	GET=`grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|grep GET|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n1 | awk '{print $2}'| cut -d '/' -f6`

	black='\e[0;30m'
	dgray='\e[1;30m'
	lgray='\e[0;37m'
	blue='\e[0;34m'
	lblue='\e[1;34m'
	green='\e[0;32m'
	lgreen='\e[1;32m'
	cyan='\e[0;36m'
	lcyan='\e[1;36m'
	red='\e[0;31m'
	lred='\e[1;31m'
	purple='\e[0;35m'
	lpurple='\e[1;35m'
	brown='\e[0;33m'
	yellow='\e[1;33m'
	white='\e[1;37m'
	nocolor='\e[0m'



	#End local variables

	###Most POST 
	echo -e "\n$lgreen === Top 10 Domains with the most POST requests (Today) ===$nocolor\n"
	LC_ALL=C fgrep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|LC_ALL=C fgrep POST|awk '{print $1}'|cut -d':' -f1| cut -d '/' -f6|sort|uniq -c|sort -nr|tail -n10

	###POST Folders/Files
	echo -e "\n$blue === ${POST}'s Most (POST) requested folders and files ===$nocolor\n"
	grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${POST}|grep POST|awk '{print $7}'|sort |uniq -c|sort -n|tail -n10

	###POST IPs 
	echo -e "\n$purple === ${POST}'s Top (POST) IP connections ===$nocolor\n"
	grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${POST}|grep POST|awk '{print $1}'|sort |uniq -c|sort -nr|tail -n10

	###Most GET
	echo -e "\n$green === Domains with the most GET requests (Today) ===$nocolor\n"
	LC_ALL=C fgrep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|LC_ALL=C fgrep GET|awk '{print $1}'|cut -d':' -f1| cut -d '/' -f6 |sort|uniq -c|sort -nr|tail -n10

        ###GET Folders/Files
        echo -e "\n$yellow === ${GET}'s Most (GET) requested folders and files ===$nocolor\n"
        grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${GET}|grep GET|awk '{print $7}'|sort |uniq -c|sort -n|tail -n10

        ###GET IPs
        echo -e "\n$white === ${GET}'s Top (GET) IP connections ===$nocolor\n"
        grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${GET}|grep GET|awk '{print $1}'|sort |uniq -c|sort -nr|tail -n10


}

 



function cpanel_safe

{

	#Prints title
	echo -e "\n$Red=== Version Info ===$NoColor\n"	

	#Prints hostname
	echo -e "Hostname: $HOST"

	#Prints OS version of the server
	if [ -f /etc/redhat-release ]
	   then echo "OS Version: `cat /etc/redhat-release`"
	elif [ -f /etc/lsb-release ]
	   then echo "OS Version: `cat /etc/lsb-release | sed -n 4p | awk -F\= '{print $2}' | sed 's/"//g'`"
	else echo -e "Neither CentOS or Ubuntu Dectected"
	fi

	#Creates variable for kernel version
	KERVER=`uname --kernel-release`

	#Creates variable for kernel architecture
	KERARCH=`uname --hardware-platform`
	#Prints kernel Information
	echo "Kernel Version: $KERVER $KERARCH"

	#Prints cPanel version
	echo "cPanel Version: `/usr/local/cpanel/cpanel -V | awk '{print $1}'`"

	#Prints Apache version
	echo "Apache Version: `httpd -v | grep --color=never nix | awk -F\/ '{print $2}' | awk '{print $1}'`"

	#Prints PHP version
	echo "PHP Version: `/usr/local/bin/php --version | grep --color=never cli | awk '{print $2}'`"

	#Prints MySQL version
	echo "MySQL Version: `mysqladmin version | grep --color=never "Server version" | awk '{print $3}' | sed 's/-cll//'`"

	echo -e "\n$Green=== Disk Space Usage ===$NoColor\n"

	#Prints the current disk space
	df --human-readable

	echo -e "\n$Yellow=== Current Memory Usage ===$NoColor\n"

	#Prints the current disk usage
	free -m

	echo -e "\n$Purple=== Number of Processors ===$NoColor\n"

	#Prints the number of CPU cores
	grep --count proc /proc/cpuinfo

	echo -e "\n$Red=== PHP Info ===$NoColor\n"

	#Prints common PHP settings values
	for each in memory_limit max_execution_time max_input_time post_max_size upload_max_filesize max_file_upload; do egrep $each $PHP; done | sed -e 's/;.*//' -e '/^\s*$/d'

	echo -e "\n$RedBold=== PHP Handler ===$NoColor\n"

	#Prints current PHP handler
	/usr/local/cpanel/bin/rebuild_phpconf --current

	echo -e "\n$Green=== Number of PHP Processes ===$NoColor\n"

	#Prints the currently running PHP processes
	ps faux | grep php -c | grep --invert-match grep

	echo -e "\n$Red=== Apache Configuration ===$NoColor\n"

	#Prints the current Apache Multi-Processing Module
	echo -e "`httpd -V | grep --color=never MPM | grep --invert-match DIR`\n"

	#Checks for common Apache settings and their values in the httpd.conf and prints them
	grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $HTTPD

	PREMAIN=$(grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $APACHEINCLUDE/pre_main_global.conf); if [[ $? == 0  ]]; then echo -e "pre_main_global.conf:\n$PREMAIN\n"; fi


        PREVHOST=$(grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $APACHEINCLUDE/pre_virtualhost_global.conf); if [[ $? == 0  ]]; then echo -e "pre_virtualhost_global.conf:\n$PREVHOST\n"; fi


        POSTVHOST=$(grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $APACHEINCLUDE/post_virtualhost_global.conf); if [[ $? == 0  ]]; then echo -e "post_virtualhost_global.conf:\n$POSTVHOST\n"; fi


	#Prints last ten Max Clients hits
	echo -e "\n\e[1;31m=== MaxClients Hits ===\e[0m\n"
	grep MaxClients $ERRORLOG/error_log |tail

	#Prints last ten graceful restarts
	echo -e "\n$Green=== Last Ten Graceful Restarts ==$NoColor\n"

	grep Graceful $ERRORLOG/error_log | tail

	echo -e "\n$Yellow=== Number of SYN connections ===$NoColor\n"

	#Prints the number of syn connections currently active
	netstat --numeric --all --program | grep SYN | wc --lines

	echo -e "\n$Purple=== Top 10 SYN Connections by IP ===$NoColor\n"

	#Prints the top ten syn flood connections
	netstat --tcp --numeric 2>/dev/null | grep SYN | awk '{print $5}' | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//'

	#Prints top ten apache connections

	echo -e "\n\e[0;31m=== Top 10 Connections to Apache (Port 80) ===\e[0m\n"
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | head | sed 's/^ *//'

	#Prints Incoming port 80 connections
	echo -e "\n\e[1;31m=== Port 80 Connections ===\e[0m\n"
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") c=c+1}END{print c}' # grep :80 | wc -l

	#Prints number of IPs connected
	echo -e "\n\e[0;32m=== Number of IPs Connected ===\e[0m\n"
	netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | wc -l

	#Prints number of IPs connected
	echo -e "\n\e[1;35m=== Number of MySQL Connections ===\e[0m\n"
	netstat -nap | grep -i sql.sock | wc -l

	#Prints MySQL Queries
	echo -e "\n\e[0;31m=== MySQL Database Queries ===\e[0m\n"
	mysqladmin proc stat

	#Prints Top MySQL Databases
	echo -e "\n\e[1;31m=== MySQL Databases ===\e[0m\n"
	du --max-depth=1 /var/lib/mysql | sort -nr | cut -f2 | xargs du -sh 2>/dev/null | head | cut -d "/" -f1,5	

	#Prints last 10 MySQL errors
	echo -e "\n\e[0;32m=== MySQL Errors ===\e[0m\n"
	cat /var/lib/mysql/${HOST}.err | tail

	#Prints current mysql connections
	echo -e "\n\e[1;33m=== MySQL Connections ===\e[0m\n"
	mysql -e 'show status;' |grep --color=never connect

	#Prints important MySQL variables
	echo -e "\n\e[1;35m=== MySQL Configuration ===\e[0m\n"
	egrep 'max_connections|max_heap_table_size|tmp_table_size|query_cache_size|timeout|table_cache|open_files|thread|innodb' $MYSQL

	#Prints important cpanel settigns
	echo -e "\n\e[0;31m=== cPanel Settings ===\e[0m\n"
	egrep -i 'piped|extracpus' /var/cpanel/cpanel.config

}


function cpanel_bot
{

	#Prints top ten hits to domains by crawlers and bots aloing with the IP and domain being hit uses perl for speed

echo -e "\n\e[1;31m=== Potentially Naughty Bots (robots or crawlers) ===\e[0m\n"; find $DOMLOGDIR -type f | grep -vE '(_|-)log|\.gz' | xargs -n1 grep -H '' | perl -ne 'if (/$DATE/ && /$DOMLOGDIR.*\/(.*):(\d{1,3}(?:\.\d{1,3}){3}).*\((?:.*?;)*([^;]*(?:b(?:ot|ing)|crawl|yahoo|google|spider)[^;]*);/i) { print ("$1\t$2\t$3\n")}' | sort | uniq -c | sort -rn | awk '{print $1" "$3" "$4" "$2}' | column -t | head -n15


}




function cpanel_wordpress
{

	#Prints top ten counts to hits on wp-login
	echo -e "\n\e[1;33m=== WordPress Brute Force ===\e[0m\n"
	grep -s wp-login.php $DOMLOGDIR/* | grep POST | grep "$(date +"%d/%b/%Y")" | cut -d: -f1 | sort| uniq -c | sort -nr | head | sed 's/^ *//g'



}


function cpanel_joomla

{

	CMSC=`grep --extended-regexp --no-messages '/administrator/index.php' $DOMLOGDIR/* | grep POST | grep "$(date +"%d/%b/%Y")"`
	JMLCMSC=`echo "$CMSC" | grep --extended-regexp --color=never '/administrator/index.php' | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'`
	
	#Checks if any Joomla logins attempts were found, if so it continues
	if [[ -n "$JMLCMSC"  ]]
	   #Prints results
	   then echo -e "\e[4mJoomla\e[24m\n\n$JMLCMSC\n"
	else echo "No Joomla Brute Forcing Detected"
	fi

}


function cpanel_exim

{

	#prints current mail queue
	echo -e "\n\e[0;32m=== Current amount of mail in queue ===\e[0m\n"
	exim -bpc


}



function cpanel_domlogs

{

        POST=`grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|grep POST|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n1 | awk '{print $2}'| cut -d '/' -f6`

        GET=`grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|grep GET|awk '{print $1}'|cut -d':' -f1|sort|uniq -c|sort -n|tail -n1 | awk '{print $2}'| cut -d '/' -f6`

        black='\e[0;30m'
        dgray='\e[1;30m'
        lgray='\e[0;37m'
        blue='\e[0;34m'
        lblue='\e[1;34m'
        green='\e[0;32m'
        lgreen='\e[1;32m'
        cyan='\e[0;36m'
        lcyan='\e[1;36m'
        red='\e[0;31m'
        lred='\e[1;31m'
        purple='\e[0;35m'
        lpurple='\e[1;35m'
        brown='\e[0;33m'
        yellow='\e[1;33m'
        white='\e[1;37m'
        nocolor='\e[0m'



        ###Most POST 
        echo -e "\n$lgreen === Top 10 Domains with the most POST requests (Today) ===$nocolor\n"
        LC_ALL=C fgrep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|LC_ALL=C fgrep POST|awk '{print $1}'|cut -d':' -f1| cut -d '/' -f6 |sort|uniq -c|sort -nr|tail -n10

        ###POST Folders/Files
        echo -e "\n$lblue === ${POST}'s Most (POST) requested folders and files ===$nocolor\n"
        grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${POST}|grep POST|awk '{print $7}'|sort |uniq -c|sort -n|tail -n10

        ###POST IPs 
        echo -e "\n$lpurple === ${POST}'s Top (POST) IP connections ===$nocolor\n"
        grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${POST}|grep POST|awk '{print $1}'|sort |uniq -c|sort -nr|tail -n10

        ###Most GET
        echo -e "\n$lgreen === Domains with the most GET requests (Today) ===$nocolor\n"
        LC_ALL=C fgrep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/*|LC_ALL=C fgrep GET|awk '{print $1}'|cut -d':' -f1| cut -d '/' -f6 |sort|uniq -c|sort -nr|tail -n10

        ###GET Folders/Files
        echo -e "\n$yellow === ${GET}'s Most (GET) requested folders and files ===$nocolor\n"
        grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${GET}|grep GET|awk '{print $7}'|sort |uniq -c|sort -n|tail -n10

        ###GET IPs
        echo -e "\n$white === ${GET}'s Top (GET) IP connections ===$nocolor\n"
        grep 2> /dev/null "$(date +"%d/%b/%Y")" $DOMLOGDIR/${GET}|grep GET|awk '{print $1}'|sort |uniq -c|sort -nr|tail -n10




}

 function cpanel_mysql

{
        #Prints Mysql Connections
        echo -e "\n\e[1;35m=== Number of MySQL Connections ===\e[0m\n"
        netstat -nap | grep -i sql.sock | wc -l

        #Prints MySQL Queries
        echo -e "\n\e[0;31m=== MySQL Database Queries ===\e[0m\n"
        mysqladmin proc stat

        #Prints Top MySQL Databases
        echo -e "\n\e[1;31m=== MySQL Databases ===\e[0m\n"
        du --max-depth=1 /var/lib/mysql | sort -nr | cut -f2 | xargs du -sh 2>/dev/null | head | cut -d "/" -f1,5

        #Last 10 MySQL errors
        echo -e "\n\e[0;32m=== MySQL Errors ===\e[0m\n"
        cat /var/lib/mysql/${HOST}.err | tail

        #Prints current MySQL connections
        echo -e "\n\e[1;33m=== MySQL Connections ===\e[0m\n"
        mysql -e 'show status;' |grep --color=never connect

        #Prints important MySQL configuration variables
        echo -e "\n\e[1;35m=== MySQL Configuration ===\e[0m\n"
        egrep 'max_connections|max_heap_table_size|tmp_table_size|query_cache_size|timeout|table_cache|open_files|thread|innodb' $MYSQL


        #Prints MySQL Table types and sizes
        echo -e "\n\e[1;33m=== MySQL Table Types and Sizes ===\e[0m\n"; mysql -e "show engines;" | grep DEFAULT | awk '{print $2" MYSQL ENGINE = "$1}'; mysql -e "SELECT engine, count(*) tables, concat(round(sum(table_rows)/1000000,2),'M') rows, concat(round(sum(data_length)/(1024*1024*1024),2),'G') data, concat(round(sum(index_length)/(1024*1024*1024),2),'G') idx, concat(round(sum(data_length+index_length)/(1024*1024*1024),2),'G') total_size, round(sum(index_length)/sum(data_length),2) idxfrac FROM information_schema.TABLES GROUP BY engine ORDER BY sum(data_length+index_length) DESC LIMIT 10;";



}




	#End called functions for Cpanel

	#Begin called functions for Plesk

function plesk_all
{
     
    #Prints test title
    echo -e "\n$Red=== Version Info ===$NoColor\n"
    #Prints hostname
    echo -e "Hostname: $HOST"
    #Prints OS version of the server
    if [ -f /etc/redhat-release ]
       then echo "OS Version: `cat /etc/redhat-release`"
    elif [ -f /etc/lsb-release ]
       then echo "OS Version: `cat /etc/lsb-release | sed -n 4p | awk -F\= '{print $2}' | sed 's/"//g'`"
    else echo -e "Neither CentOS or Ubuntu Dectected"
    fi
    #Creates variable for kernel version
    KERVER=`uname --kernel-release`
    #Creates variable for kernel architecture
    KERARCH=`uname --hardware-platform`
         #Prints kernel Information
         echo "Kernel Version: $KERVER $KERARCH"
    #Creates variable for Plesk version
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Prints Plesk version
    echo "Plesk Version: $PVER"
    #Prints Apache version
    echo "Apache Version: `httpd -v | grep --color=never nix | awk -F/ '{print $2}' | awk '{print $1}'`"
    #Prints PHP version
    echo "PHP Version: `/usr/bin/php --version | grep --color=never cli | awk '{print $2}'`"
    #Creates variable and then displays MySQL version
    PSAMYSQL=$(mysqladmin -uadmin -p`cat /etc/psa/.psa.shadow` version | grep --color=never "Server version" | sed 's/Server version/MySQL Version:/')
    #Prints MySQL version
    echo $PSAMYSQL
     
    echo -e "\n$Green=== Disk Space Usage ===$NoColor\n"
    #Prints the current disk space
    df --human-readable
     
    echo -e "\n$Yellow=== Current Memory Usage ===$NoColor\n"
    #Prints the current disk usage
    free -m
     
    echo -e "\n$Purple=== Number of Processors ===$NoColor\n"
    #Prints the number of CPU cores
    grep --count proc /proc/cpuinfo

    echo -e "\n$Red=== PHP Handlers ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`awk '{print $1}' /usr/local/psa/version`
    #Checks for Plesk version number and writes to a variable
    if [[ "1 2 3 4 5 6 7 8 9" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-9 is present, if so this check can't be used
       then echo -e "\nPHP Handler Check not supported by this version of Plesk.\n"
    elif [[ "10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then mysql -uadmin -p`cat /etc/psa/.psa.shadow` --execute="SELECT www_root, php_handler_type FROM psa.hosting;" | sed 's|\s\+|/|g' | cut --fields=5,7 --delimiter=/ | sed --expression='s|/|\t|g' --expression='s/module/dso/g' | column -t
       #If Plesk version 12+ is present the new access log path is used
       else mysql -uadmin -p`cat /etc/psa/.psa.shadow` --execute="SELECT www_root, php_handler_id FROM psa.hosting;" | sed 's|\s\+|/|g' | cut --fields=5,7 --delimiter=/ | sed --expression='s|/|\t|g' --expression='s/module/dso/g' | column -t
    fi
     
    echo -e "\n$RedBold=== Number of PHP Processes ===$NoColor\n"
    #Prints the currently running PHP processes
    ps faux | grep php -c | grep --invert-match grep
     
    echo -e "\n$Green=== Apache Configuration ===$NoColor\n"
    #Prints the current Apache Multi-Processing Module
    echo -e "`httpd -V | grep --color=never MPM | grep --invert-match DIR`\n"
    #Checks for common Apache settings and their values in the httpd.conf and prints them
    grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $HTTPDP | grep --invert-match ^#
     
    echo -e "\n$Yellow=== MaxClients Hits ===$NoColor\n"
    grep MaxClients /etc/httpd/logs/error_log |tail
     
    echo -e "\n$Purple=== Last Ten Graceful Restarts ==$NoColor\n"
    #Prints the last ten graceful restarts
    grep Graceful /etc/httpd/logs/error_log | tail
     
    echo -e "\n$Red=== Number of SYN connections ===$NoColor\n"
    #Prints the number of syn connections currently active
    netstat --numeric --all --program | grep SYN | wc --lines
     
    echo -e "\n$RedBold=== Top 10 SYN Connections by IP ===$NoColor\n"
    #Prints the top ten syn flood connections
    netstat --tcp --numeric 2>/dev/null | grep SYN | awk '{print $5}' | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//'
     
    echo -e "\n$Green=== Top 10 Connections to Apache ===$NoColor\n"
    netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | head | sed 's/^ *//'
     
    echo -e "\n$Yellow=== Port 80 Connections ===$NoColor\n"
    netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") c=c+1}END{print c}' # grep :80 | wc -l
     
    echo -e "\n$Purple=== Number of IPs Connected ===$NoColor\n"
    netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | wc -l
     
    echo -e "\n$Red=== WordPress Brute Force ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then grep --color=never 'wp-login.php' /var/www/vhosts/*/statistics/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
       #If Plesk version 12+ is present the new access log path is used
       else grep --color=never 'wp-login.php' /var/www/vhosts/*/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
    fi
     
    #Prints test title
    echo -e "\n$RedBold=== Joomla Brute Force ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then grep --color=never 'administrator/index.php' /var/www/vhosts/*/statistics/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
       #If Plesk version 12+ is present the new access log path is used
       else grep --color=never 'administrator/index.php' /var/www/vhosts/*/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
    fi
     
    echo -e "\n$Green=== Number of MySQL Connections ===$NoColor\n"
    netstat -nap | grep -i sql.sock | wc -l
     
    echo -e "\n$Yellow=== MySQL Database Queries ===$NoColor\n"
    mysqladmin -uadmin -p`cat /etc/psa/.psa.shadow` proc stat
     
    echo -e "\n$Purple=== MySQL Databases ===$NoColor\n"
    du --max-depth=1 /var/lib/mysql | sort -nr | cut -f2 | xargs du -sh 2>/dev/null | head | cut -d "/" -f1,5
     
    echo -e "\n$Red=== MySQL Errors ===$NoColor\n"
    cat /var/log/mysqld.log | tail
     
    echo -e "\n$RedBold=== MySQL Connections ===$NoColor\n"
    mysql -uadmin -p`cat /etc/psa/.psa.shadow` --execute='show status;' | grep --color=never connect
     
    echo -e "\n$Green=== MySQL Configuration ===$NoColor\n"
    egrep 'max_connections|max_heap_table_size|tmp_table_size|query_cache_size|timeout|table_cache|open_files|thread|innodb' $MYSQL
     
    echo -e "\n$Yellow== Bots (robots or crawlers) ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then find /var/www/vhosts/*/statistics/logs/access_log -type f | grep --invert-match --extended-regexp $'(_|-).processed' | xargs grep --with-filename "" | grep $(date +%d/%b/%Y) | grep --ignore-case --extended-regexp "crawl|bot|spider|yahoo|bing|google"| while read line ; do IP=$(echo $line | awk '{print $0}'); AGENT=$(echo $line | awk -F\" '{print $6}' | grep --ignore-case --only-matching --perl-regexp '[^ ]*(bot|spider|crawl)[^ ]*' | grep --invert-match http); echo -e "$IP\t-- $AGENT"; done | sort | uniq --count | sort --reverse --numeric-sort | sed --expression 's/\/var\/www\/vhosts\///g;s/\/statistics\/logs\/access_log\:/  /g;s/- -.*--//;s/\/.*\;//g' | awk '{print $1" "$3" "$4" "$2}' | column -t | head
       #If Plesk version 12+ is present the new access log path is used
       else find /var/www/vhosts/*/logs/access_log -type f | grep --invert-match --extended-regexp $'(_|-).processed' | xargs grep --with-filename "" | grep $(date +%d/%b/%Y) | grep --ignore-case --extended-regexp "crawl|bot|spider|yahoo|bing|google"| while read line ; do IP=$(echo $line | awk '{print $0}'); AGENT=$(echo $line | awk -F\" '{print $6}' | grep --ignore-case --only-matching --perl-regexp '[^ ]*(bot|spider|crawl)[^ ]*' | grep --invert-match http); echo -e "$IP\t-- $AGENT"; done | sort | uniq --count | sort --reverse --numeric-sort | sed --expression 's/\/var\/www\/vhosts\///g;s/\/logs\/access_log\:/  /g;s/- -.*--//;s/\/.*\;//g' | awk '{print $1" "$3" "$4" "$2}' | column -t | head
fi
 
}
     
     
function plesk_safe
     
{
     
    ##Prints test title
    echo -e "\n$Red=== Version Info ===$NoColor\n"
    #Prints hostname
    echo -e "Hostname: $HOST"
    #Prints OS version of the server
    if [ -f /etc/redhat-release ]
       then echo "OS Version: `cat /etc/redhat-release`"
    elif [ -f /etc/lsb-release ]
       then echo "OS Version: `cat /etc/lsb-release | sed -n 4p | awk -F\= '{print $2}' | sed 's/"//g'`"
    else echo -e "Neither CentOS or Ubuntu Dectected"
    fi
    #Creates variable for kernel version
    KERVER=`uname --kernel-release`
    #Creates variable for kernel architecture
    KERARCH=`uname --hardware-platform`
         #Prints kernel Information
         echo "Kernel Version: $KERVER $KERARCH"
    #Creates variable for Plesk version
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Prints Plesk version
    echo "Plesk Version: $PVER"
    #Prints Apache version
    echo "Apache Version: `httpd -v | grep --color=never nix | awk -F/ '{print $2}' | awk '{print $1}'`"
    #Prints PHP version
    echo "PHP Version: `/usr/bin/php --version | grep --color=never cli | awk '{print $2}'`"
    #Creates variable and then displays MySQL version
    PSAMYSQL=$(mysqladmin -uadmin -p`cat /etc/psa/.psa.shadow` version | grep --color=never "Server version" | sed 's/Server version/MySQL Version:/')
    #Prints MySQL version
    echo $PSAMYSQL
     
    echo -e "\n$RedBold=== Disk Space Usage ===$NoColor\n"
    #Prints the current disk space
    df --human-readable
     
    echo -e "\n$Green=== Current Memory Usage ===$NoColor\n"
    #Prints the current disk usage
    free -m
     
    echo -e "\n$Yellow=== Number of Processors ===$NoColor\n"
    #Prints the number of CPU cores
    grep --count proc /proc/cpuinfo
    
    echo -e "\n$Red=== PHP Handlers ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`awk '{print $1}' /usr/local/psa/version`
    #Checks for Plesk version number and writes to a variable
    if [[ "1 2 3 4 5 6 7 8 9" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-9 is present, if so this check can't be used
       then echo -e "\nPHP Handler Check not supported by this version of Plesk.\n"
    elif [[ "10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then mysql -uadmin -p`cat /etc/psa/.psa.shadow` --execute="SELECT www_root, php_handler_type FROM psa.hosting;" | sed 's|\s\+|/|g' | cut --fields=5,7 --delimiter=/ | sed --expression='s|/|\t|g' --expression='s/module/dso/g' | column -t
       #If Plesk version 12+ is present the new access log path is used
       else mysql -uadmin -p`cat /etc/psa/.psa.shadow` --execute="SELECT www_root, php_handler_id FROM psa.hosting;" | sed 's|\s\+|/|g' | cut --fields=5,7 --delimiter=/ | sed --expression='s|/|\t|g' --expression='s/module/dso/g' | column -t
    fi
 
    echo -e "\n$Purple=== Number of PHP Processes ===$NoColor\n"
    #Prints the currently running PHP processes
    ps faux | grep php -c | grep --invert-match grep
     
    echo -e "\n$Red=== Apache Configuration ===$NoColor\n"
    #Prints the current Apache Multi-Processing Module
    echo -e "`httpd -V | grep --color=never MPM | grep --invert-match DIR`\n"
    #Checks for common Apache settings and their values in the httpd.conf and prints them
    grep --extended-regexp --color=never 'MaxClients|KeepAlive|MaxRequestsPerChild|Timeout|Servers|Threads|ServerLimit|MaxRequestWorkers|MaxConnectionsPerChild' $HTTPDP | grep --invert-match ^#
     
    echo -e "\n$RedBold=== MaxClients Hits ===$NoColor\n"
    grep MaxClients /etc/httpd/logs/error_log | tail
     
    echo -e "\n$Green=== Last Ten Graceful Restarts ==$NoColor\n"
    #Prints the last ten graceful restarts
    grep Graceful /etc/httpd/logs/error_log | tail
     
    echo -e "\n$Yellow=== Number of SYN connections ===$NoColor\n"
    #Prints the number of syn connections currently active
    netstat --numeric --all --program | grep SYN | wc --lines
     
    echo -e "\n$Purple=== Top 10 SYN Connections by IP ===$NoColor\n"
    #Prints the top ten syn flood connections
    netstat --tcp --numeric 2>/dev/null | grep SYN | awk '{print $5}' | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//'
     
    echo -e "\n$Red=== Top 10 Connections to Apache ===$NoColor\n"
    netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | head | sed 's/^ *//'
     
    echo -e "\n$RedBold=== Port 80 Connections ===$NoColor\n"
    netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") c=c+1}END{print c}' # grep :80 | wc -l
     
    echo -e "\n$Green=== Number of IPs Connected ===$NoColor\n"
    netstat -tn 2>/dev/null | awk '{if ($4 ~ ":80") print $5}' | cut -f1 -d: | sort | uniq -c | sort -rn | wc -l
     
    echo -e "\n$Yellow=== Number of MySQL Connections ===$NoColor\n"
    netstat -nap | grep -i sql.sock | wc -l
     
    echo -e "\n$Purple=== MySQL Database Queries ===$NoColor\n"
    mysqladmin -uadmin -p`cat /etc/psa/.psa.shadow` proc stat
     
    echo -e "\n$Red=== MySQL Databases ===$NoColor\n"
    du --max-depth=1 /var/lib/mysql | sort -nr | cut -f2 | xargs du -sh 2>/dev/null | head | cut -d "/" -f1,5
     
    echo -e "\n$RedBold=== MySQL Errors ===$NoColor\n"
    cat /var/log/mysqld.log | tail
     
    echo -e "\n$Green=== MySQL Connections ===$NoColor\n"
    mysql -uadmin -p`cat /etc/psa/.psa.shadow` --execute='show status;' | grep --color=never connect
     
    echo -e "\n$Yellow=== MySQL Configuration ===$NoColor\n"
    egrep 'max_connections|max_heap_table_size|tmp_table_size|query_cache_size|timeout|table_cache|open_files|thread|innodb' $MYSQL
     
}
     
     
function plesk_bot

{
    #Prints test title
    echo -e "\n$Red=== Bots (Robots or Crawlers) ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then find /var/www/vhosts/*/statistics/logs/access_log -type f | grep --invert-match --extended-regexp $'(_|-).processed' | xargs grep --with-filename "" | grep $(date +%d/%b/%Y) | grep --ignore-case --extended-regexp "crawl|bot|spider|yahoo|bing|google"| while read line ; do IP=$(echo $line | awk '{print $0}'); AGENT=$(echo $line | awk -F\" '{print $6}' | grep --ignore-case --only-matching --perl-regexp '[^ ]*(bot|spider|crawl)[^ ]*' | grep --invert-match http); echo -e "$IP\t-- $AGENT"; done | sort | uniq --count | sort --reverse --numeric-sort | sed --expression 's/\/var\/www\/vhosts\///g;s/\/statistics\/logs\/access_log\:/  /g;s/- -.*--//;s/\/.*\;//g' | awk '{print $1" "$3" "$4" "$2}' | column -t | head
       #If Plesk version 12+ is present the new access log path is used
       else find /var/www/vhosts/*/logs/access_log -type f | grep --invert-match --extended-regexp $'(_|-).processed' | xargs grep --with-filename "" | grep $(date +%d/%b/%Y) | grep --ignore-case --extended-regexp "crawl|bot|spider|yahoo|bing|google"| while read line ; do IP=$(echo $line | awk '{print $0}'); AGENT=$(echo $line | awk -F\" '{print $6}' | grep --ignore-case --only-matching --perl-regexp '[^ ]*(bot|spider|crawl)[^ ]*' | grep --invert-match http); echo -e "$IP\t-- $AGENT"; done | sort | uniq --count | sort --reverse --numeric-sort | sed --expression 's/\/var\/www\/vhosts\///g;s/\/logs\/access_log\:/  /g;s/- -.*--//;s/\/.*\;//g' | awk '{print $1" "$3" "$4" "$2}' | column -t | head
    fi
     
     
     
}
     
     
function plesk_wordpress
{
     
    echo -e "\n$Red=== WordPress Brute Force ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then grep --color=never 'wp-login.php' /var/www/vhosts/*/statistics/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
       #If Plesk version 12+ is present the new access log path is used
       else grep --color=never 'wp-login.php' /var/www/vhosts/*/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
    fi
     
}
     
     
function plesk_joomla
     
{
     
    #Prints test title
    echo -e "\n$Red=== Joomla Brute Force ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
       then grep --color=never 'administrator/index.php' /var/www/vhosts/*/statistics/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
       #If Plesk version 12+ is present the new access log path is used
       else grep --color=never 'administrator/index.php' /var/www/vhosts/*/logs/access_log | grep POST | grep "$(date +"%d/%b/%Y")" | cut --fields=1 --delimiter=: | sort | uniq --count | sort --reverse --numeric-sort | head | sed 's/^ *//g'
    fi
}
     
     
function plesk_mail
     
{
     
    #Prints test title
    echo -e "\n$Red=== Current Mail in Queue ===$NoColor\n"
    #Tests if Plesk is using Postfix
    if [[ -n $(/usr/local/psa/admin/sbin/mailmng --features|grep SMTP_Server|grep Postfix) ]]
       #If Postfix is detected it prints its queue total
       then echo -e "Postfix Detected\n"; postqueue -p | tail --lines 1
    #Tests if Plesk is using Qmail
    elif [[ -n $(/usr/local/psa/admin/sbin/mailmng --features|grep SMTP_Server|grep QMail) ]]
       #If Qmail is detected it prints its queue total
       then echo -e "Qmail Detected\n"; /var/qmail/bin/qmail-qstat
    #If neither Postfix nor Qmail is detected is prints that result
    else echo -e "Neither Postfix or Qmail Dectected"
    fi
     
}
     
     
     
function plesk_domlogs
     
{
     
    echo -e "\n$Red=== Bots (Robots or Crawlers) ===$NoColor\n"
    #Checks for Plesk version number and writes to a variable
    PVER=`cat /usr/local/psa/version | awk '{print $1}'`
    #Checks if Plesk version 1-11 is present
    if [[ "1 2 3 4 5 6 7 8 9 10 11" =~ `echo $PVER | awk -F\. '{print $1}'` ]]
       #If Plesk version 1-11 is present the old access log path is used
	then find /var/www/vhosts/*/statistics/logs/access_log -type f | grep --invert-match --extended-regexp $'(_|-).processed' | xargs grep --with-filename "" | grep $(date +%d/%b/%Y) | grep --ignore-case --extended-regexp "crawl|bot|spider|yahoo|bing|google"| while read line ; do IP=$(echo $line | awk '{print $0}'); AGENT=$(echo $line | awk -F\" '{print $6}' | grep --ignore-case --only-matching --perl-regexp '[^ ]*(bot|spider|crawl)[^ ]*' | grep --invert-match http); echo -e "$IP\t-- $AGENT"; done | sort | uniq --count | sort --reverse --numeric-sort | sed --expression 's/\/var\/www\/vhosts\///g;s/\/statistics\/logs\/access_log\:/  /g;s/- -.*--//;s/\/.*\;//g' | awk '{print $1" "$3" "$4" "$2}' | column -t | head
	   #If Plesk version 12+ is present the new access log path is used
	   else find /var/www/vhosts/*/logs/access_log -type f | grep --invert-match --extended-regexp $'(_|-).processed' | xargs grep --with-filename "" | grep $(date +%d/%b/%Y) | grep --ignore-case --extended-regexp "crawl|bot|spider|yahoo|bing|google"| while read line ; do IP=$(echo $line | awk '{print $0}'); AGENT=$(echo $line | awk -F\" '{print $6}' | grep --ignore-case --only-matching --perl-regexp '[^ ]*(bot|spider|crawl)[^ ]*' | grep --invert-match http); echo -e "$IP\t-- $AGENT"; done | sort | uniq --count | sort --reverse --numeric-sort | sed --expression 's/\/var\/www\/vhosts\///g;s/\/logs\/access_log\:/  /g;s/- -.*--//;s/\/.*\;//g' | awk '{print $1" "$3" "$4" "$2}' | column -t | head
	fi
 
 
 
} 



#End Super Duper Server Stats







welcome_screen
