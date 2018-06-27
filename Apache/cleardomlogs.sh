##################################################################
#                                                                #
# Author: Joe varghese <joevarghese@gmail.com>                   #
# Date: Mar 25 2005                                              #
# Version: 1.0                                                   #
#                                                                #
#!!! CAUTION !!! USE AT YOUR OWN RISK                            #
# Script to clear the first 10 domlogs taking up most disk space,#
# exim_mainlog, exim_rejectlog, maillog in cpanel servers.       #
# Parameters: <none>                                             #
#                                                                #
##################################################################

echo ;
echo "1) Clear the first 10 domlogs taking up most disk space, exim_mainlog, exim_rejectlog and maillog in one go";
echo "2) Clear the first 10 domlogs taking up most disk space only";
echo "3) Clear exim_mainlog";
echo "4) Clear exim_rejectlog";
echo "5) Clear maillog";
echo "6) Bail out";
echo ;

read Keypress

echo ;

case "$Keypress" in
  1 )   echo "Clearing domlogs...";
        cd /usr/local/apache/domlogs;
        for i in `ls -alhS | head  | awk  {'print $9'}`
        do
        echo "Clearing /usr/local/apache/domlogs/$i";
        cat " " > /usr/local/apache/domlogs/$i 2> /dev/null;
        done
echo "Clearing exim_mainlog...";
        cat " " >    /var/log/exim_mainlog 2> /dev/null;
echo "Clearing exim_rejectlog...";
        cat " " >    /var/log/exim_rejectlog 2> /dev/null;
echo "Clearing maillog...";
        cat " " >    /var/log/maillog 2> /dev/null;echo "Done";;

  2 )   echo "Clearing domlogs...";
        cd /usr/local/apache/domlogs;
        for i in `ls -alhS | head  | awk  {'print $9'}`
        do
        echo "Clearing /usr/local/apache/domlogs/$i";
        cat " " >    /usr/local/apache/domlogs/$i 2> /dev/null;
        done;echo "Done";;

 3 )    echo "Clearing exim_mainlog...";
        cat " " >    /var/log/exim_mainlog 2> /dev/null;echo "Done";;


 4 )    echo "Clearing exim_rejectlog...";
        cat " " >    /var/log/exim_rejectlog 2> /dev/null;echo "Done";;

 5 )    echo "Clearing maillog...";
        cat " " > /var/log/maillog 2> /dev/null;echo "Done";;

 * )    echo "Bailing out";exit;;
esac
echo ;

