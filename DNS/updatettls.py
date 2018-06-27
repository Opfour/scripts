#!/usr/bin/python

import commands
import os
import time

date = time.strftime("%Y%m%d%H")

ttl = raw_input("What TTL do you want to use? ")
ttl = str(ttl)

print "Backing up zone file directory..."

try:
	os.mkdir('/home/named.backup')
except:
	print "Backup directory already exists, skipping."

cmd = "rsync -aq /var/named /home/named.backup"

os.system(cmd)

print "Adjusting TTLs..."

os.chdir("/var/named")
files = commands.getoutput("ls *.db").split("\n")

for file in files:
	os.system("sed -i -e 's/[0-9]*\s).*$/%s )\t\t; minimum TTL/' %s" %(ttl, file))
	os.system("sed -i -e 's/\$TTL.*/\$TTL %s/' %s" %(ttl, file))
	os.system("sed -i -e 's/[0-9]\{10\}/%s/' %s" %(date, file))
	
print "Reloading zone files..."
os.system('rndc reload')

print "Done!"
