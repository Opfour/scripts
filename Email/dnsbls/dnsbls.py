#!/usr/bin/python
# RELEASED UNDER THE GNU GPLv3 LICENSE
# DNSBLS.py is tested and found compatible with Ubuntu 12.04 Server with Python 2.7.3
#
# INSTALL
# Simply download the script with you favorite tool (ex. wget) and run the script from where you placed it.
# 
# Use the software at your own risk!
# I can be contacted through the Ubuntu forums as the user MadsRC regarding the software.
############# CHANGELOG ################
# Changes since v. 1.1:
# * Removed the hardcoded list and made it as an imported list from the file "blacklists".
# * Added the option "--true" which nearly does the same as "-v". The difference is that "--true"
# returns whatever IP is registered in a given RBL list. "-v" only returns the value if it 
# starts with 127.
import socket, sys, argparse
from argparse import RawTextHelpFormatter
parser = argparse.ArgumentParser(description="DNSBLS\n\nHelps you find out whether or not you are on a DNS blacklist.\n\nExamples:\n--------\ndnsbls.py -i 1.2.3.4\nWill tell you if you are on any of the lists that DNSBLS checks against.\n\ndnsbls.py -i 1.2.3.4 -s\nOutputs 1 if you are on a list that DNSBLS checks against, and 0 if you aren't\n\ndnsbls.py -i 1.2.3.4 -v\nOutputs the lists you are on.\n\ndnsbls.py -i 1.2.3.4 -vv\nOutputs every list that DNSBLS checks against, and tells you if you are on any of them.\n\ndnsbls.py -l\nOutputs every list that DNSBLS checks\n\nTIP: -i also resolves hostnames", formatter_class=RawTextHelpFormatter)
parser.add_argument('-i', '--ip', action='store', dest='IP',
                    	help='The IP or hostname you want to check')
parser.add_argument('-s', '--short', action='store_true', default=False,
			dest='short',
			help='Extra short output')
parser.add_argument('-v', '--verbose', action='store_true', default=False,
			dest='verbose',
			help='Output is verbose')
parser.add_argument('-vv', '--verbose2', action='store_true', default=False,
			dest='verbose2',
			help='Output is extra verbose')
parser.add_argument('-l', '--list', action='store_true', default=False,
			dest='list',
			help='Lists the DNS blacklists in use')
parser.add_argument('--true', action='store_true', default=False,
			dest='true',
			help='Lists the true output from each DNSBLS') 
parser.add_argument('--version', action='version', version='%(prog)s 1.2')
results = parser.parse_args()
# To add your own dns blacklists or remove some, just edit the below list.
with open('blacklists', 'r') as f:
	L = [line.strip() for line in f]
def ip_reversed(ip, separator='.'):

    ipListe = ip.split(separator)
    ipListeReversed = []

    n = len(ipListe)
    while n != 0:
        ipListeReversed.append(ipListe[n-1])
        n -= 1
        continue

    return separator.join(ipListeReversed)

try:
	socket.inet_aton(results.IP)
	if len(results.IP.split('.')) == 4:
		ip = results.IP	
	else:
		sys.exit("Input does not consist of 4 octets!")
except (socket.error):
	try:
		resolved_domain = socket.gethostbyname(results.IP)
		ip = resolved_domain
	except (socket.gaierror):
		sys.exit("Cannot resolve input")
except (TypeError):
	sys.exit("Use argument -h for help")
isonlist = False
if results.short == True and results.verbose == False and results.verbose2 == False and results.list == False and results.true == False:
	for dnsbls in L:
		try:
			if  socket.gethostbyname("%s.%s" % (ip_reversed(ip), dnsbls)).startswith("127"):
				isonlist = True
		except (socket.gaierror):
			pass
	if isonlist == True:
		print "1"
	else:
		print "0"
elif results.verbose == False and results.short == False and results.verbose2 == False and results.list == False and results.true == False:
        for dnsbls in L:
                try:
                        if  socket.gethostbyname("%s.%s" % (ip_reversed(ip), dnsbls)).startswith("127"):
                                isonlist = True
                except (socket.gaierror):
                        pass
        if isonlist == True:
                print "You are on one of my lists! - Use -v argument to find out what lists."
        else:
                print "You are NOT on any of my lists!"
elif results.verbose == True and results.short == False and results.verbose2 == False and results.list == False and results.true == False:
	for dnsbls in L:
		try:
			if socket.gethostbyname("%s.%s" % (ip_reversed(ip), dnsbls)).startswith("127"):
				print  "%s %s" % (dnsbls, socket.gethostbyname("%s.%s" % (ip_reversed(ip), dnsbls)))
		except (socket.gaierror):
			pass
elif results.verbose == False and results.short == False and results.verbose2 == True and results.list == False and results.true == False:
        for dnsbls in L:
                try:
                        if socket.gethostbyname("%s.%s" % (ip_reversed(ip), dnsbls)).startswith("127"):
                                print  "%s %s" % (dnsbls, socket.gethostbyname("%s.%s" % (ip_reversed(ip), dnsbls)))
                except (socket.gaierror):
                       print "%s - Not listed" % (dnsbls)
elif results.list == True and results.verbose == False and results.verbose2 == False and results.short == False and results.true == False:
	for dnsbls in L:
		print  dnsbls
elif results.true == True and results.verbose == False and results.verbose2 == False and results.short == False and results.list == False:
	for dnsbls in L:
		try:
			print '%s %s' % (dnsbls, socket.gethostbyname('%s.%s' % (ip_reversed(ip), dnsbls)))
		except (socket.gaierror):
			pass
else:
	sys.exit("Combination of arguments not supported")
