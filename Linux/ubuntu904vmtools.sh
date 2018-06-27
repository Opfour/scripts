#!/bin/bash

echo "Updating packages..."
sleep 15
sudo apt-get update
echo Y|sudo apt-get upgrade

echo -n "Determining whether this is a desktop or a server installation... "
if [ "${kernelstring=`uname -r|grep -i server`}" == "" ]; then
	desktopinstall=true
	echo "desktop."
else
	desktopinstall=false
	echo "server."
fi
sleep 15

if [ $desktopinstall == true ]; then
	echo Y|sudo apt-get install build-essential libgtk2.0-dev libgtkmm-2.4-dev libproc-dev libdumbnet-dev xorg-dev psmisc linux-headers-`uname -r` libproc-dev libicu-dev libglib2.0-dev libnotify-dev libfuse-dev xserver-xorg-input-vmmouse
else
	echo Y|sudo apt-get install build-essential libproc-dev libdumbnet-dev psmisc linux-headers-`uname -r` libproc-dev libicu-dev libglib2.0-dev libfuse-dev
fi

mkdir /tmp/chrysaor.info && cd /tmp/chrysaor.info
echo "Downloading VMware Tools..."
sleep 15
wget http://chrysaor.info/scripts/vmware-tools-ubuntu904.tgz

echo "Removing (Open) VMware Tools if installed"
sleep 15
echo Y|sudo apt-get remove open-vm-tools
if [ -f /usr/bin/vmware-uninstall-tools.pl ]; then
	sudo perl /usr/bin/vmware-uninstall-tools.pl
fi

echo "Untaring VMware Tools..."
sleep 15
tar xzvf vmware-tools*.tgz

echo "Installing VMware Tools..."
sleep 15
cd vmware-tools*/
sudo perl ./vmware-install.pl

echo "Installation of VMware Tools finished. You may now reboot."
echo "Please come visit us at http://chrysaor.info ."
