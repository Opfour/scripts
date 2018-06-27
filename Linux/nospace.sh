#!/usr/pkg/bin/python2.4
# nospace.py /this/dir /that/dir /those/too

import commands,os,re,sys,time


def dorename(files, p):
  for file in files:
    if ( p.search(file) ):
      newname = file.replace(" ", "_")
      cmd = 'mv "%s" "%s"' %(file, newname)
      print file, "=>", newname
      os.system(cmd)
      #print cmd

  
if len(sys.argv) <= 1:
  print "Usage: nospace.py /this/dir /that/dir /those/too"
  sys.exit(1)
    
dirs = sys.argv[1:]
p = re.compile(".*\s.*")

for dir in dirs:
  dir = dir.rstrip('/')
  files = commands.getoutput("find %s -type d" %dir).split("\n")
  dorename(files, p)

  time.sleep(2)
  
  files = commands.getoutput("find %s -type f" %dir).split("\n")
  dorename(files, p)
  
