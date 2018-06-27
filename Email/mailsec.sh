#!/bin/bash

me=`/usr/bin/whoami`
if [[ $me = root ]]; then
        echo "Not meant to be ran as root, run as a user please.";
        exit 1;
fi

if [[ "$1" == "--help" ]]; then
        echo "";
        echo "Usage:";
        echo "Type mailsec --help to get this output.";
        echo "Example: mailsec --help";
        echo "";
        echo "Type mailsec alone for a scan of all domains in the /home/user/list file.";
        echo "Example:  mailsec";
        echo "";
        echo "Type mailsec domain.com to scan a single specific domain.";
        echo "Example: mailsec liquidweb.com";
        echo "";
        echo "";
        exit 1;
elif [[ -z "$1" ]]; then
        echo "No domain specified, Checking list file located at \"/home/$me/list\"";
        THElist="`cat /home/$me/list`";
else
        echo "Domain specified, Checking $1";
        THElist="$1";
fi

echo "";
MKDIR=`which mkdir`
$MKDIR -p /home/$me/mailsecure
#rm /home/$me/mailsecure/mailsec-check-*
FIEL="/home/$me/mailsecure/mailsec-check-`date +%d%m%Y-%H%M%S`";
TOUCH=`which touch`
$TOUCH $FIEL;
for each in $THElist;
do
mx1=`dig +short mx $each|awk '{print $2}'|sed 's/\.$//g'`;
mx2=`dig +short mx $each|awk '{print $2}'|sed 's/\.$//g'|head -n1`;
ns1=`dig +short ns $each|head -n1|sed ':a;N;$!ba;s/\n/ /g'`;
mxip=`dig +short $mx2`;
if [[ $each = $mx1 ]]; then
        echo "$each~-~MX matches A Record~-~$ns1 MX=$mx2" >> $FIEL;
elif [[ bmx01.sourcedns.com = $mx2 ]] || [[ bmx01.liquidweb.com = $mx2 ]]; then
        echo "$each~-~Already using Mailsecure~-~$ns1 MX=$mx2" >> $FIEL;
else
        echo "$each~-~DOES NOT MATCH AND NEEDS ADJUSTMENT~-~$ns1 MX=$mx2" >> $FIEL;
fi;
if [[ bmx01.sourcedns.com = $mx2 ]] || [[ bmx01.liquidweb.com = $mx2 ]]; then
        echo "$each~-~MX matches Mailsecure~-~$mxip" >> $FIEL;
else
        echo "$each~-~MX resolves to~-~$mxip" >> $FIEL;
fi;
echo "" >> $FIEL;
done
CAT=`which cat`
$CAT $FIEL |column -s '~' -t |sort | sed '0~2 a\\'
echo ""

