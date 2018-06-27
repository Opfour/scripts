#!/usr/bin/perl
# cPlicensing.net - scripts        Copyright(c) 2003 cPlicensing.net.
#                                 All rights Reserved.
# support@cPlicensing.net      http://cPlicensing.net
# Unauthorized copying is prohibited
# Version: 0.01


$nameddir = '/var/named';
$cpanelusers = '/var/cpanel/users';
$wwwacct = '/etc/wwwacct.conf';

print "Rebuild Named Zones Script from cPlicensing.net\n\n";
print "MAKE SURE YOU BACKUP YOUR EXISTING $nameddir directory\n";
print "Waiting 5 seconds... press ctrl+c to quit\n";
sleep 5;
print "\n\n";

opendir(USERS,"$cpanelusers");
@CPUSERS=readdir(USERS);
closedir(USERS);

print "Grabbing first 2 NameServers from $wwwacct...";
open(CONF,"$wwwacct");
while(<CONF>) {
$_ =~ s/\n//g;
if ($_ !~ /^;/) {
if ($_ =~ /^NS /) {
                        (undef,$nameserver) = split(/ /, $_);
                }
if ($_ =~ /^NS2 /) {
                        (undef,$nameserver2) = split(/ /, $_);
                }
}
}
close(CONF);
print "done.\n";

print "Rebuilding Zone Files... (cross your fingers)...";
foreach $cpusers (@CPUSERS) {
chomp;
open(USERDB,"$cpanelusers/$cpusers");
while(<USERDB>) {
if(/IP=/i) { (undef,$ip) = split(/=/, $_, 2); }
if(/DNS=/i) { (undef,$dns) = split(/=/, $_, 2); }
chomp($ip);
chomp($dns);
}
createzone();
}
print "Done.\n";
print "\n\nZones have been rebuild but the named.conf has not.\n";
print "use /scripts/rebuildnamedconf to rebuild the named.conf with\n";
print "the new zones.  Note that running /scripts/rebuildnamedconf will not\n";
print "just rebuild the named.conf, you will need to pipe it into the file but\n";
print "also you need to make sure their are no existing zones in it\n";

sub createzone(){
$time=time();

$nameddata = <<EOM;
; cPanel 5.x
; Zone file for $domain
@    14400   IN      SOA     $nameserver. hostmaster.$dns. (
                        $time      ; serial, todays date+todays
                        28800           ; refresh, seconds
                        7200            ; retry, seconds
                        3600000         ; expire, seconds
                        86400 )         ; minimum, seconds

$dns. 14400 IN NS $nameserver.
$dns. 14400 IN NS $nameserver2.
$dns. 14400 IN A $ip

localhost.$dns.   14400    IN A   127.0.0.1

$dns. 14400 IN MX 0 $dns.

mail    14400        IN CNAME    $dns.
www     14400        IN CNAME    $dns.
ftp     14400        IN CNAME    $dns.

EOM

open(VNAMEDF,">$nameddir/$dns.db");
print VNAMEDF $nameddata;
close(VNAMEDF);

}


