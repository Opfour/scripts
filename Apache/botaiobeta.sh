#By Mark Benedict
# 09/29/2012
ver=1.0
clear
echo "Bots All In One Tool $ver"
echo ""
echo "What would you like to do?"
echo ""
PS3='Please enter your choice: '
echo ""
options=("Quick Display robots.txt" "Scan For Blocked Bots" "Check for Crawlers" "Future2" "Future3" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Quick Display robots.txt")
clear
echo "Robots.txt Quick Display - mbenedict"
echo "------------------------------------"
echo "Searching...... This may take some time." 
echo ""
rm -rf /root/rbt.txt.results
find /home*/*/public_html -name 'robots.txt' >> /root/rbt.txt.results.3
echo "Start robots.txt Search" >> /root/rbt.txt.results
for file in $(cat /root/rbt.txt.results.3); do echo "" >> /root/rbt.txt.results.2; echo "------------------" >> /root/rbt.txt.results.2; echo "Path: $file" >> /root/rbt.txt.results.2; echo "Perms and Ownership: `ls -al $file |awk '{print $1, $2, $3, $4}'`"  >> /root/rbt.txt.results.2; echo "" >> /root/rbt.txt.results.2; cat $file >> /root/rbt.txt.results.2; done
grep -v '^[[:space:]]*#' /root/rbt.txt.results.2 >> /root/rbt.txt.results
echo "------------------" >> /root/rbt.txt.results; echo " " >> /root/rbt.txt.results; echo "End robots.txt Search" >> /root/rbt.txt.results; echo " " >> /root/rbt.txt.results
echo " Results stored in /root/rbt.txt.results" >> /root/rbt.txt.results; echo "" >> /root/rbt.txt.results
rm -rf /root/rbt.txt.results.*
cat /root/rbt.txt.results
            break
            ;;
        "Scan For Blocked Bots")


rdns=$(grep 'LF_LOOKUPS = "1"' /etc/csf/csf.conf |awk '{ print $3 }'|sed "s/^\([\"']\)\(.*\)\1\$/\2/g")
rdnsyes=1
if  ! [[ $rdns == $rdnsyes ]] 
then
clear
echo "Firewall Bot Check  $ver -mbenedict"
echo "-----------------------------------"
echo ""
echo "  ###########################################"
echo " # Pro TIP -                                 #"
echo " # Add the following to /etc/csf/csf.rignore #"
echo " # to prevent further blocking:              #"
echo " # .googlebot.com                            #"
echo " # .crawl.yahoo.net                          #"
echo " # .search.msn.com                           #"
echo "  ##########################################"
echo ""
rm -rf /root/botcheckresults
echo "CSF Detected with RDNS checking current entries."
grep .googlebot.com /etc/csf/csf.deny >> /root/botcheckresults
grep .crawl.yahoo.net /etc/csf/csf.deny >> /root/botcheckresults
grep .search.msn.com /etc/csf/csf.deny >> /root/botcheckresults
echo "___________________________________________"
echo ""
echo "Bots Found: `cat /root/botcheckresults |wc -l`"
echo ""
echo "Please report any issues to mbenedict@liquidweb.com"
echo ""
cat /root/botcheckresults

else
cat /root/botcheckresults
echo "Firewall Bot Check  $ver"
echo ""
echo "Please report any issues to mbenedict@liquidweb.com"
echo ""
grep -v '^[[:space:]]*#' /etc/csf/csf.deny 2> /dev/null >> /root/botcheck.tmp
grep -v '^[[:space:]]*#' /etc/csf/csf.tempban 2> /dev/null >> /root/botcheck.tmp
grep -v '^[[:space:]]*#' /etc/apf/deny_hosts.rules 2> /dev/null >> /root/botcheck.tmp 
sed --in-place '/(sshd)/d' /root/botcheck.tmp
sed --in-place '/(smtpauth)/d' /root/botcheck.tmp
sed --in-place '/(ftpd)/d' /root/botcheck.tmp
sed --in-place '/(imapd)/d' /root/botcheck.tmp
sed --in-place '/(cpanel)/d' /root/botcheck.tmp
cat /root/botcheck.tmp |awk '{print $1}' >> /root/botcheck.tmp.2
for file in $(cat /root/botcheck.tmp.2); do host -WRs $file >> /root/botcheck.results; done
cat /root/botcheck.results
exit
	
fi
 
 
 
 
 
            break
            ;;
        "Check for Crawlers")

clear
echo "Checking for Google, Yahoo and Microsoft Bot connections."
echo ""
echo ""
netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | awk '{print $2}' | head >> crawlchk.1.tmp
sed --in-place '/127.0.0.1/d' /root/crawlchk.1.tmp
for file in $(cat /root/crawlchk.1.tmp); do host -WRs $file >> /root/crawlchk.2.tmp; done
grep .googlebot.com /root/crawlchk.2.tmp >> /root/crawlchk.3.tmp
grep .crawl.yahoo.net /root/crawlchk.2.tmp >> /root/crawlchk.3.tmp
grep .search.msn.com /root/crawlchk.2.tmp >> /root/crawlchk.3.tmp
results=$(wc -l /root/crawlchk.3.tmp |awk '{print $1}' )
echo " $results crawler/s found connected to server."
echo "----------------------------------------------"
cat /root/crawlchk.3.tmp
rm -rf /root/crawlchk.*
 
            break
            ;;
        "Future2")


 SHIT HERE
 
 
 
            break
            ;;
        "Future3")


 SHIT HERE
 
 
 
            break
            ;;

        "Quit")
            clear
            break
            ;;
        *) echo invalid option;;
    esac
done
