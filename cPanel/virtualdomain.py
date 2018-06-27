#!/usr/bin/python2

import os
import commands
import time

config = '/usr/local/apache/conf/httpd.conf'

#date = time.strftime("%m%d%Y")

user_name = raw_input("Enter user name: ")

virt_domain = raw_input("What is the virtual domain? ")
virt_domain = virt_domain.lower()

web_dir = raw_input("Web directory name: ")

ip_addr = raw_input("IP Address: ")

email = raw_input("Where should all email go by default? ")

email_config = "/etc/valiases/" + virt_domain

#print "\nBacking up Apache config:\n"
#command = "cp %s %s.bak.%s" % (config, config, date)
#os.system(command)

f = open(config, 'a')

f.write("""
<VirtualHost %s>
DocumentRoot /home/%s/public_html/%s
ServerAdmin wwwadmin@%s
ServerName www.%s
ServerAlias www.%s %s
BytesLog domlogs/%s-bytes_log
CustomLog domlogs/%s combined
ScriptAlias /cgi-bin/ /home/%s/public_html/%s/cgi-bin/
</VirtualHost>
""" %(ip_addr, user_name, web_dir, virt_domain, virt_domain, virt_domain, virt_domain, virt_domain, virt_domain, user_name, web_dir) )

f.close()

print "Restarting apache server:\n"
results = commands.getoutput("httpd restart")
print results + "\n"

print "Virtual domain setup complete.\n"

print "Setting up Default Email forwarder:\n"

f = open(email_config, 'a')

if email == "":
	f.write("*: %s\n" %user_name)
else:
	f.write("*: %s\n" %email)

print "Email forwader added.\n"

print "Adding to Exim config...\n"

f = open("/etc/localdomains", 'a')
f.write("%s\n" %virt_domain)
f.close()

f = open("/etc/userdomain", 'a')
f.write("%s: %s\n" %(virt_domain, user_name) )
f.close()

dnscount = commands.getoutput("egrep -c -e 'DNS.*' /var/cpanel/users/%s" %user_name)
num = int(dnscount) +1

f = open("/var/cpanel/users/%s" %user_name, 'a')
f.write("DNS%s=%s\n" %(str(num), virt_domain))
f.close()

os.system("/scripts/mailperm")

print "Virtual domain setup is complete.\n"
