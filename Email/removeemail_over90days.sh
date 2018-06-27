#HOW TO DELETE EMAIL OLDER THAN 3 MONTHS FROM CPANEL
#JULY 19, 2010 MICK GENIE	5 COMMENTS
#Some email user never remove their email message and they have never though that the older email actually wasting the hosting account space. With this article, Mick Genie will guide you some shell script to remove email older than 3 months(90 days).
#To run the shell script, you may make the shell script with .sh file as sample below.
#Save the following coding name removed_mails_for_90days.sh

#!/bin/bash
IFS=”$”
cpanel_username=mickgenie //your cPanel username
domain=domain.com //your domain name
username=mickgenie //your email username (without domain)
cd /home/${cpanel_username}/mail/${domain}/${username}
find -P /home/${cpanel_username}/mail/${domain}/${username}/* -mindepth 1 -maxdepth 1 -mtime ‘+90’ | while read old; do
echo “Deleting ${old}…”
rm -rf “${old}”
done

Remember to change your cpanel_username, domain and username from the script.

Set the cronjob from your cPanel or shell access(SSH) which running daily.
0 0 * * * /bin/sh /home/mickgenie/scripts/removed_mails_for_90days.sh
