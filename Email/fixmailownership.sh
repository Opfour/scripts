#!/bin/bash

# Written by bcathey 2008.03.29 - 13:00
#
# If users are having problems with Horde or Squirrel mail, such as
# "SquirrelMail ERROR Connection Dropped by IMAP Server"
# or
# In Horde, once the login button is clicked gives a username/password error

for i in $(cat /etc/domainusers | cut -d ":" -f 1 | sort)
do
  echo ""
  echo -e "Fixing ownership of Mail Dir for \E[34m\033[1m$i . . .\033[0m"
  cd /home/$i
  chown -R $i:$i mail
done

