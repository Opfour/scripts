#!/bin/sh
cd /usr/local/cpanel/base/frontend/x/cells
rm -rf soholaunch
cd /usr/local/cpanel/base/frontend/x
rm -f soholaunch
rm -rf soholaunch
rm -f soholaunch.html
rm -f soho-cp-inst.tar.gz
wget "http://update.securexfer.net/panel_files/soho-cp-inst.tar.gz"
tar -xzvf soho-cp-inst.tar.gz
chmod -R 0755 soholaunch
cd ../x2
rm -f soholaunch
rm -rf soholaunch
ln -s /usr/local/cpanel/base/frontend/x/soholaunch soholaunch
cd ../x3
rm -f soholaunch
rm -rf soholaunch
ln -s /usr/local/cpanel/base/frontend/x/soholaunch soholaunch
cd ../x3mail
rm -f soholaunch
rm -rf soholaunch
ln -s /usr/local/cpanel/base/frontend/x/soholaunch soholaunch
cd ../tree
rm -f soholaunch
rm -rf soholaunch
ln -s /usr/local/cpanel/base/frontend/x/soholaunch soholaunch
rm -f soho-cp-inst.tar.gz
cd /usr/local/cpanel/base/frontend/x
chmod -R 0755 soholaunch
mv soholaunch.cpaneladdonmodule /usr/local/cpanel/bin/soholaunch.cpaneladdonmodule
chmod 0755 /usr/local/cpanel/bin/soholaunch.cpaneladdonmodule
/usr/local/cpanel/bin/unregister_cpanelplugin /usr/local/cpanel/bin/soholaunch.cpaneladdonmodule
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/bin/soholaunch.cpaneladdonmodule