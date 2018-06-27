#!/usr/bin/python

import os

files = os.listdir(os.getcwd())

for file in files:
	parts = file.split('.', 1)
	base = parts[0]
	try:
		oldname = "%s.%s" %(parts[0], parts[1])
	except:
		print 'no extension, nothing to change.'
		oldname = parts[0]

	newname = parts[0] + ".txt"
	os.rename(oldname, newname)
