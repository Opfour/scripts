#!/usr/bin/env python
# 
# spam must die

import os
import commands
import sys

def grep_spool(header):
	cmd = "find /var/spool/exim/input -name '*-H' | xargs grep -s '%s' | cut -d ':' -f 2- | sort | uniq -c | sort -n | tail -5" %header
	results = commands.getoutput(cmd)
	return results

headers = ["Subject:", "From:", "host_name", "To:"]

li = []
option = 0

for header in headers:
	print "Top Five %s Headers:" %header
	results = grep_spool(header)
	try:
		top = results.splitlines()
        	top = top.pop()
		li.append(top)
		print results + "\n"
	except:
		print "No results found.\n"

while option != "2":
	print "What do you want to do?"
	print "[1] Delete spam"
	print "[2] Exit\n"
	option = raw_input("Enter option number: ")
	if option == "1":
		num = 0
		for i in li:
			print "[%s] -- %s" %(num, i)
			num = num + 1	
			
		print "[X] -- Cancel\n"
		z = raw_input("Which messages to delete? ")

		if z.upper() == "X":
			sys.exit(0)

		search_string = li[int(z)].lstrip()
		print "String:"
		print search_string
		try:
			search_string = search_string.split(":", 1)
			search_string = search_string[1]
		except:
			search_string = search_string[0]

		print "Search string is: %s" %search_string
		print "Deleting spam, this may take a while..."

		cmd = "grep -lrs '%s' /var/spool/exim/input | cut -d '/' -f 7" %search_string

		messages = commands.getoutput(cmd).splitlines()

		for msg in messages:
			try:
				id = msg.split("-")
				cmd = "exim -Mrm %s-%s-%s" %(id[0], id[1], id[2])
				os.system(cmd)
				#print "exim -Mrm %s" %id[0]
			except:
				print "Error deleting message."

		print "Spam has been eliminated."
		sys.exit(0)
	elif option == "2":
		sys.exit(0)

