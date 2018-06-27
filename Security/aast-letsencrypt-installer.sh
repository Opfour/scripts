#!/bin/bash

# Installer for Let's Encrypt cPanel Plugin

# Download the .tar.gz file to be extracted 
url=http://rep0.admin-ahead.com/sources/aast-letsencrypt/aast-letsencrypt.tar.gz
installdir=/usr/local/cpanel/whostmgr/cgi/letsencrypt-plugin
# Check if centos 6 or 7, if it is 6, install python 2.7 and stuff
function install_python27 {
	# Install Epel Repository
	yum install epel-release -y > /dev/null 2>1
	# Install IUS Repository
	rpm -ivh https://rhel6.iuscommunity.org/ius-release.rpm > /dev/null 2>1
	# Install Python 2.7 and Git
	echo "Installing Python 2.7 and Git"
	echo "XXXXX"
	yum --enablerepo=ius install python27 python27-devel python27-pip python27-setuptools python27-virtualenv -y > /dev/null 2>1
}

function plugin_installation {
	echo 80
	echo "Downloading package"
	echo "XXXXX"
	cd $installdir
	wget $url  > /dev/null 2>1
	tar -xzf aast-letsencrypt.tar.gz > /dev/null 2>1
	rm -f aast-letsencrypt.tar.gz
	echo 90
	echo "Registering Plugin"
	echo "XXXX"
	/usr/local/cpanel/bin/register_appconfig app.conf > /dev/null 2>1
	echo 100
	echo "XXXX"
	echo "Completed"
	echo "XXXXX"
}

function letsencrypt_installation {
	mkdir -p $installdir
	cd $installdir
	/usr/local/cpanel/3rdparty/bin/git clone https://github.com/letsencrypt/letsencrypt > /dev/null 2>1
	cd letsencrypt
	echo 60
	echo "Initial setup for Let's Encrypt"
	echo "XXXXX"
	./letsencrypt-auto --help > /dev/null 2>1
}

function install_centos7 {
	echo 20
	echo "Beginning letsencrypt installation"
	echo "XXXX"
	letsencrypt_installation
}

function install_centos6 {
	echo 15
	install_python27
	echo 50
	echo "Beginning letsencrypt installation"
	echo "XXXX"
	letsencrypt_installation
}



function get_os {
	echo "XXXXX"
	if [ -f '/etc/redhat-release' ]
	then
		os=`perl -ne '/release\s+(\d)\S+\s+/ and print $1' /etc/redhat-release`
		if [ $os -eq 6 ]
		then
			install_centos6
		elif [ $os -eq 7 ]
		then
			install_centos7
		else
			echo 100
			echo "XXX"
			echo "OS not supported. Exiting"
			exit
		fi
	fi
}

function uninstall {
	echo 20
	echo "XXXX"
	echo "Unregistering the plugin"
	echo "XXXX"
	cd $installdir
	/usr/local/cpanel/bin/unregister_appconfig app.conf	> /dev/null 2>1
	echo 60
	echo "Removing files"
	echo "XXX"
	cd ..
	rm -rf letsencrypt-plugin> /dev/null 2>1
	sleep 1
	echo 100
	echo "XXXX"
	echo "Completed"
	echo "XXXXX"
}

function main {
	clear
	which dialog > /dev/null 2>&1
	#install dialog
	if [ $? -ne 0 ]
	then
	yum -y install dialog > /dev/null 2>1
	fi
	DIALOG=${DIALOG=dialog}
	tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
	trap "rm -f $tempfile" 0 1 2 5 15
	$DIALOG --clear --title "Choose an option" \
        --menu "Choose an option:" 20 51 4 \
        "Install"  "Install Letsencrypt-plugin" \
        "Uninstall"  "Uninstall Letsencrypt-plugin" 2> $tempfile
	retval=$?
	choice=`cat $tempfile`
	case $retval in
  		0)
	if [ $choice = 'Install' ]
	then
	(	echo 10
		echo "XXX"
		echo "Installing dependencies.."
		echo "XXX"
		yum install gcc libffi-devel python-devel openssl-devel -y > /dev/null 2>1
		get_os
		plugin_installation
	) |
	$DIALOG --title "Installing" --gauge "Installing Letsencrypt-plugin" 20 70 0
	else
		(	
			uninstall
			sleep 1
		) |
		$DIALOG --title "Uninstalling" --gauge "Uninstalling Letsencrypt-plugin" 20 70 0

	fi
		;;
  	1)
		;;
  	255)
		echo "ESC pressed"
		;;
 esac
}
main

	
