#!/bin/bash
### mshooltz
#
# check script for modsecurity rpms bases on easy apache version, logs to /var/log/cron
#
#### Variables
ea4flag="/etc/cpanel/ea4/is_ea4"
ea3rpmCHK=`rpm -qa | grep -v ea4 | grep lp-modsec2-rules-*.*.noarch`
ea4rpmCHK=`rpm -qa | grep lp-modsec2-rules-ea4*.*.noarch`
userconfCHK=`grep "# Include " /etc/apache2/conf.d/modsec2.user.conf`
lpyumchk=$(grep lpyum /root/.bashrc| cut -d= -f1 | cut -d\  -f2)
cronpath="/etc/cron.hourly/modsec2_check"
install="" #needs to stay blank
remove="" #needs to stay blank
userconfCHK=`grep "# Include " /etc/apache2/conf.d/modsec2.user.conf | wc -l  | sed 's/0//'`


#### Functions
yumremove () {
        if [ -z $lpyumchk ]; then
                yum -y remove $remove;
        else
                lpyum -y remove $remove;
        fi
}

yuminstall () {
        if [ -z $lpyumchk ]; then
                yum -y install $install;
        else
                lpyum -y install $install;
        fi
}

#### Logic
# if neither rpm is installed, end script run
if [[ -z $ea3rpmCHK  &&  -z $ea4rpmCHK ]]; then
        logger -p cron.notice "$cronpath halted, no lp-modsec rpm found on the system, suggest to customer to install our modsec rules."
        exit
fi

# check for ea4 flag
if [ -f $ea4flag ]; then
        # check if ea4modsec rpm is installed
        if [ -z $ea4rpmCHK ]; then
                logger -p cron.notice "EA4 detected, installing the lp-modsec2-rules-ea4 rpm, removing $ea3rpmCHK."
                #remove the ea3 rpm if needed 
                remove="$ea3rpmCHK"
                yumremove
		#make  sure modsec2.user.conf is empty before upgrade
		if [ ! -z $userconfCHK ]; then
			echo "Backing up modsec2.user.conf, and cleaning the file."
			cp /etc/apache2/conf.d/modsec2.user.conf /etc/apache2/conf.d/modsec2.user.conf.pre-clean.`date +%m-%d-%Y`
			echo "" > /etc/apache2/conf.d/modsec2.user.conf
		fi
                #install the correct rpm
                install="lp-modsec2-rules-ea4"
                yuminstall
        else
                #exit because all is correct and nothing to do
                exit
        fi
else
        #server is not ea4, make sure ea3 modsec rpm is in place.
        if [ -z $ea3rpmCHK ]; then
                logger -p cron.notice "EA3 detected, installing the lp-modsec2-rules rpm, removing $ea4rpmCHK."
                echo "need to install ea3rpm modsec rpm"
                #remove the EA4 rpm if needed.
                remove="$ea4rpmCHK"
                yumremove
                #install the correct rpm
                install="lp-modsec2-rules"
                yuminstall
        else
                #exit because all is correct and nothing to do
                exit
        fi
fi
