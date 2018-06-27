#!/usr/bin/perl
# cPlicensing.net - scripts         Copyright(c) 2006 cPlicensing.net.
#                 All rights Reserved.
# support@cPlicensing.net        http://cPlicensing.net
# Unauthorized copying is prohibited
#Version: 0.03
#
#+CHANGE LOG (YYYY-MM-DD)
#-v0.3 :: 2006-03-15 :: Changed script to no longer use accounting file, how pulls csv from whostmgr binary
#-v0.2 :: 2004-02-22 :: Now will show a catagory for domains that point to the correct ip as well.

use strict;
use warnings;
use Socket;

$|++;
$ENV{'REMOTE_USER'} = 'root';

print "Building Interface IP List...";
my %localips;
foreach(qx(/sbin/ifconfig | /bin/grep inet | /bin/cut -d: -f2 | /bin/awk '{print \$1 }')) {
	chomp;
	$localips{$_} = $_;
}
print "Success\n";

print "Checking /etc/resolv.conf\n";
if ( -f "/etc/resolv.conf" ) {
	open RESOLVCONF, "</etc/resolv.conf";
	while(<RESOLVCONF>) {
		chomp;
		if(/nameserver/) {
			my(undef,$nsip) = split(/\s+/,$_);
			if($localips{$nsip}) {
				print "Warning!!! IP Address $nsip was found in your /etc/resolv.conf but that ip is assigned to a local interface on this server.  It is recommended that you remove the entry and replace it with a external nameserver (ex: your Data Centers Resolvers).  Leaving the ip may result in this script giving your wrong information\n\n";
				print "Press CTRL+C to exit or press enter to continue\n";
				<STDIN>;
			}
		}
	}
	close RESOLVCONF;
}

print "Retreiving CSV from whostmgr...";
my %csv;
foreach(qx(/usr/local/cpanel/whostmgr/bin/whostmgr fetchcsv)) {
	chomp;
	next unless /^,/;
	my(undef,$domain,$ip,$user,undef) = split(",", $_, 5);
	next unless $domain and $ip and $user;
	$ip =~ s/:443//;
	$csv{$user}{domain} = $domain;
	$csv{$user}{ip} = $ip;
}
print "Success\n";

print "Domain to IP check...";
my (%fr,%ri,%wi);
foreach (keys %csv) {
	print ".";
	my $iaddr = gethostbyname($csv{$_}{domain});
	unless ( $iaddr ) {
		$fr{$_} = 1;
		next;
	}
	if ( inet_ntoa( $iaddr ) eq $csv{$_}{ip} ) {
		$ri{$_} = 1;
		next;
	} else {
		$wi{$_} = 1;
	}
}
print "Done\n";

print "Displaying Results...\n";

print "\n\n";
print "--------------------------------------------\n";
print "- LIST OF DOMAINS THAT POINT TO CORRECT IP -\n";
print "============================================\n";

foreach(keys %ri) {
	print "--> ".$csv{$_}{domain}."\n";
}

print "\n\n";
print "--------------------------------------------\n";
print "-  LIST OF DOMAINS THAT FAILED TO RESOLVE  -\n";
print "============================================\n";

foreach(keys %fr) {
	print "--> ".$csv{$_}{domain}."\n";
}

print "\n\n";
print "--------------------------------------------\n";
print "-  LIST OF DOMAINS THAT POINT TO WRONG IP  -\n";
print "============================================\n";

foreach(keys %wi) {
        print "--> ".$csv{$_}{domain}."\n";
}

print "\n\n";
print "--------------------------------------------\n";
print "-                   SUMMERY                -\n";
print "============================================\n";
print "-->PRIMARY DOMAINS FOUND ON SERVER..................".scalar(keys %csv)."\n";
print "-->PRIMARY DOMAINS THAT RESOLVE TO THE CORRECT IP...".scalar(keys %ri)."\n";
print "-->PRIMARY DOMAINS THAT DONT RESOLVE TO A IP........".scalar(keys %fr)."\n";
print "-->PRIMARY DOMAINS THAT POINT TO WRONG IP...........".scalar(keys %wi)."\n";
print "\n\n";


