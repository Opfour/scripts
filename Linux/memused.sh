#!/bin/bash
echo "Please input date in two digits"
read date
echo ""
echo "   TIME      MB USED"
sar -f /var/log/sa/sa$date -r | grep -v mem | grep -v LINUX | grep -v Average | grep -v Linux | awk '{print $1, $2, "", "", "", ($4 - $6 - $7) / 1024}'| cut -d. -f1 | grep -v '     0'
