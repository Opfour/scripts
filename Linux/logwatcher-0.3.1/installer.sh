#!/bin/bash

# Install script for watcher

INSTALL_PATH="/etc/watcher"
BINPATH="/usr/local/sbin/watcher"

function installation(){
	mkdir $INSTALL_PATH
	cp -Rf files/* $INSTALL_PATH
	chmod -R 640 $INSTALL_PATH
	chmod 750 $INSTALL_PATH/watcher
	ln -fs $INSTALL_PATH/watcher $BINPATH
	cp -f watcher.cron /etc/cron.d/watcher
	chmod 750 $INSTALL_PATH
}

echo -n "Installing watcher"
installation
echo
echo "Installation Done"
echo
echo "Details:"
echo "  Install Path:              $INSTALL_PATH"
echo "  Primary Config:            $INSTALL_PATH/watcher.conf"
echo "  Module Config:             $INSTALL_PATH/modules.conf"
echo "  Cron Job:                  /etc/cron.d/watcher"
echo
echo "Please be sure to adjust:"
echo " * Primary Config to contain Ticket and Account link as well as thresholds required"
echo " * Module Config to reflect what you wish to be monitored and reported"
echo
