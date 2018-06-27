#LAMP Version Checker v0.1 for Ubuntu
#Displays current versions of Linux, Apache, Mysql, PHP, Perl and Python
#Created By: Mark Benedict
#!/bin/bash

clear
echo "LAMP Version Checker - v0.1"
echo "Mark Benedict"
echo "------------------------------------------"
echo "Server Name - `hostname`"
echo "Server Time - `date`"
echo "------------------------------------------"
echo "Linux Details -"
echo ""
echo "Kernel Version:  `uname -r`"
lsb_release -a
echo ""
echo ""
echo "__________________________"
echo ""
echo "Apache Details -"
echo ""
httpd -v
echo ""
echo ""
echo "__________________________"
echo ""
echo "MYSQL Details -"
echo ""
mysql -V
echo ""
echo ""
echo "__________________________"
echo ""
echo "PHP Details -"
echo ""
php -v
echo ""
echo ""
echo "__________________________"
echo ""
echo "Perl Details -"
echo ""
perl -v
echo ""
echo ""
echo "__________________________"
echo ""
echo "Python Details -"
echo ""
python --version
echo ""
echo ""
echo "__________________________"










