#!/bin/bash
cat  /etc/userdatadomains | awk '{print $1}' | tr -d ':|*' > domainlist.txt
while read LINE; do
  curl -o /dev/null --silent --head --write-out '%{http_code}' "$LINE"
  echo " $LINE"
done < domainlist.txt
