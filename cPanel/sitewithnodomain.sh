#View Cpanel Site Without Domain v0.1
#Generates link for viewing cpanel without a domain.
#Created By: Mark Benedict
#!/bin/bash
clear
echo "View Cpanel Site Without Domain v0.1"
echo ""
echo ""
echo "Please enter server IP"
read ip
echo "Please enter username of cpanel account"
read name
echo "Opening"
firefox http://$ip/~$name/