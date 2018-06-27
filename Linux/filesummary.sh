#!/bin/bash
#Custom Quick Display - Prints summary of specified files
#Created By: Mark Benedict
# Future Additions; Check if plesk or cpanel change paths accordingly.
#Auto Update Whiptail

clear
srcfile=$(whiptail --title "Custom Quick Display" --backtitle "Custom Quick Display - Created by: mbenedict" --separate-output  --checklist "Choose file to search:" 10 60 5 robots.txt cPanel.Users.Only off .htaccess cPanel.Users.Only off php.ini cPanel.Users.Only off 3>&1 1>&2 2>&3)
srctxt=$(whiptail --title "Custom Quick Display" --backtitle "Custom Quick Display - Created by: mbenedict" --nocancel --inputbox "Please enter keywords:" 10 30 3>&1 1>&2 2>&3)
if  [[ -z "$srcfile"  ]]
then
whiptail --title "Custom Quick Display" --backtitle "Custom Quick Display - Created by: mbenedict" --ok-button Quit --msgbox "No search criteria defined" 8 78
else
{
    for ((i = 0 ; i <= 100 ; i+=10)); do
        sleep 1
        echo $i
    done
} | whiptail --gauge "Searching" 5 50 0
rm -rf /root/custsrch.txt.*
find /home*/*/public_html -name \*${srcfile}\* >> /root/custsrch.txt.results.3
echo "Start $srcfiles Search" >> /root/custsrch.txt.results
if  [[ -z "$srctxt"  ]]
then
for file in $(cat /root/custsrch.txt.results.3); do echo "" >> /root/custsrch.txt.results.2; echo "------------------" >> /root/custsrch.txt.results.2; echo "Path: $file" >> /root/custsrch.txt.results.2; echo "Perms and Ownership: `ls -al $file |awk '{print $1, $2, $3, $4}'`"  >> /root/custsrch.txt.results.2; echo "" >> /root/custsrch.txt.results.2; cat $file >> /root/custsrch.txt.results.2; done
else
for file in $(cat /root/custsrch.txt.results.3); do echo "" >> /root/custsrch.txt.results.2; echo "------------------" >> /root/custsrch.txt.results.2; echo "Path: $file" >> /root/custsrch.txt.results.2; echo "Perms and Ownership: `ls -al $file |awk '{print $1, $2, $3, $4}'`"  >> /root/custsrch.txt.results.2; echo "" >> /root/custsrch.txt.results.2; egrep -i -A 4 "$srctxt" $file >> /root/custsrch.txt.results.2; done	
fi
grep -v '^[[:space:]]*#' /root/custsrch.txt.results.2 >> /root/custsrch.txt.results
echo "------------------" >> /root/custsrch.txt.results; echo " " >> /root/custsrch.txt.results; echo "End $srcfiles Search" >> /root/custsrch.txt.results; echo " " >> /root/custsrch.txt.results
echo " Results stored in /root/custsrch.txt.results" >> /root/custsrch.txt.results; echo "" >> /root/custsrch.txt.results
rm -rf /root/custsrch.txt.results.*
whiptail --textbox /root/custsrch.txt.results 60 150 --scrolltext
whiptail --title "Custom Quick Display" --backtitle "Custom Quick Display - Created by: mbenedict" --ok-button Quit --msgbox "Results stored in /root/custsrch.txt.results" 8 78
fi
