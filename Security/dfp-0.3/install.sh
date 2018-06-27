#!/bin/bash

# Install script for dfp

INSTALL_PATH="/etc/dfp"
BINPATH="/usr/local/sbin/dfp"

installation() {
  mkdir $INSTALL_PATH
  cp -Rf files/* $INSTALL_PATH
  chmod -R 640 $INSTALL_PATH/*
  chmod 750 $INSTALL_PATH/dfp
  ln -fs $INSTALL_PATH/dfp $BINPATH
  cp dfp.cron /etc/cron.d/dfp
  cp logrotate.d.dfp /etc/logrotate.d/dfp
  chmod 750 $INSTALL_PATH
}

VER=$(cat files/VERSION | grep version | awk '{print $2}')

echo -n "Installing dfp $VER: "
installation

sleep 5
echo "Installation Done."
echo
echo "Details:"
echo "  Install Path:            $INSTALL_PATH/"
echo "  Config Path:             $INSTALL_PATH/conf.dfp"
echo "  Executable Path:         $BINPATH"
echo
echo "Please be sure to look over the configuration file and set this up to your needs"
