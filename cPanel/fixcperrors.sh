# Fixing Cpanel Errors
#
# Here are a number of fixes for Cpanel issues.
#
1. ACCOUNT CREATION ERROR #1
# ==========================
# Account doesn't actually show up

$ mv /root/.cpan/CPAN/MyConfig.pm /root/.cpan/CPAN/MyConfig.pm.old
$ cd /home/temp
$ wget http://search.cpan.org/CPAN/authors/id/D/DM/DMUEY/File-Copy-Recursive-0.33.tar.gz
$ tar -zxf File-Copy-Recursive-0.33.tar.gz; cd File-Copy-Recursive-0.33
$ perl Makefile.pl
$ make
$ make test
$ make install
$ /scripts/upcp --force



2. ACCOUNT CREATION ERROR #2
# ==========================
# DNS doesn't propagate on new accounts, no zone files
#
# If a customer is creating accounts and complains about DNS, check /var/named
# to see if the zone file is there.  If it isn't then the issue is that when
# the account was created, the "IP" box was checked.  Doing this doesn't setup
# zone files.  So you have to recreate the account without selecting to give
# the account it's own IP, and then change it in WHM.



3. HORDE PHP ERRORS
# =================

$ /usr/local/cpanel/bin/update-horde --force
$ /scripts/fullhordereset
$ /scripts/upcp --force

# You can also run:

$ /scripts/makecpphp



4. FIX PERL MODULES
# =================

$ mv /root/.cpan/CPAN/MyConfig.pm /root/.cpan/CPAN/MyConfig.pm.old
$ /scripts/checkperlmodules

5. FIX DOMAIN REDIRECTS
# =====================
# This error is when a customer attempts to use an accounts domain.com/cpanel
# and it redirects to the main sites hostname.  There have been two different
# errors I've seen, either it works after the redirect or the sites just time
# out.

$ rm /var/cpanel/ssl/cpanel-CN
$ touch /var/cpanel/ssl/cpanel-CN



6. INSTALLING A NEW VERSION OF ZEND
# =================================

$ /scripts/installzendopt 3.2.8



7. FIX BYTESLOG ERROR APACHE
# -------------------------
# [root@host ~]# /etc/init.d/httpd startssl
# Syntax error on line 1127 of /usr/local/apache/conf/httpd.conf:
# Invalid command 'BytesLog', perhaps mis-spelled or defined by a module
# not included in the server configuration
# /etc/init.d/httpd startssl: httpd could not be started

$ cd /usr/local/cpanel/apache
$ /usr/local/apache/bin/apxs -iac mod_log_bytes.c
$ /etc/init.d/httpd startssl



8. MAILDIR - CPANEL FIX
# =====================

# Run:
$ /scripts/convert2maildir
# Select option:
3) Start maildir conversion process
# This will take a while to complete.  Once it is done you will see this in
# the maildirconversion log:
# [maildirupdate] Update Complete



9. IMAP CONNECTION ISSUES
# =======================
# After the mailbox format changes Squirrel Mail (and possibly Horde) are
# having issues connecting to the IMAP server.  Run this and it should
# correct the issue.

$ /scripts/courierup --force



10. CONVERT SINGLE USERS
# ======================
# Read more about usage here: http://batleth.sapienti-sat.org/projects/mb2md/

$ /usr/local/cpanel/3rdparty/mb2md/mb2md --help



11. FIXING FRONTPAGE INSTALL
# ==========================
# Sometimes when you run '/scripts/setupfp5 <domain>' you get the error:
#   No Server found
#
# The fix is to remove all _vt_* directories, the following commands will work
# to get you squared away.

$ /scripts/unsetupfp4
$ cd /home/$USER/public_html
$ rm -rf _vt_*
$ mv .htaccess .htaccess.LWold
$ /scripts/setupfp5 <domain_of_$USER>



12. FIXING MAIL DELIVERY
# ======================
# When there are a lot of 'Connection timed out' messages in the mail log.

$ rpm -e clamd clamav clamav-db
$ rm -Rvf /var/clamav /var/log/clam*
$ lpyum -y install clamd clamav clamav-db
$ /scripts/eximup --force



13. FIXING A BROKEN HORDE RESET
# =============================
# --- Originally found by jmays, perfected by CurtM
#
# When you run /scripts/fullhordereset it breaks and says it can't find a
# file.  It is looking for the wrong tar file.  Do the following:

$ ls -l /usr/local/cpanel/src/3rdparty/gpl | grep horde
# Figure out the version from the file name, example:
# horde-3.1.3.cpanel.tar.gz = 3.1.3

$ vi /usr/local/cpanel/bin/update-horde
# Look for the line that looks like the following:
#   hordever="3.1.3p2"
# Change this to the version of the file above, so in our example you'd change
# this line to:
#   hordever="3.1.3"
#
# Now run:
$ /scripts/fullhordereset

# == EOF == #

