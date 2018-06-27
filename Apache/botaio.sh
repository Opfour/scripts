#Robots.txt Quick Display
#Prints summary of current robot.txt files
#Created By: Mark Benedict
#!/bin/bash
# Future Additions; Check if plesk or cpanel change paths accordingly.
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