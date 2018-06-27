#!/usr/bin/perl
# cPlicensing.net - scripts		Copyright(c) 2003 cPlicensing.net.
#					All rights Reserved.
# support@cPlicensing.net      		http://cPlicensing.net
# Unauthorized copying is prohibited
# Version: 0.02 

use DBI();
use Sys::Hostname;


#Sets the maximum concurrent connections per MySQL user.
my $max_concurrent_connections		= '15';

#Who to tell about this user... (email)
my $warning_email			= 'noc@localhost';

#Kill Abuser's MySQL Connections (0 = no, 1 = yes)
my $kill_user				= '0';

#MySQL polling in seconds (600 = 10 minutes)
my $check_interval			= '600';

###################################
####NO NEED TO EDIT BELOW HERE#####
###################################
#Set these if you wish to run the script as a diffrent mysql user.
my $mysqluser				= '';
my $mysqlpass				= '';

$hostname = hostname();
if ((!$mysqluser) or (!$mysqlpass)) {
	open(MYCNF,"/root/.my.cnf");
	while(<MYCNF>) {
		chomp;
		s/"//g;
		if(/user/is) { (undef,$mysqluser) = split('=', $_, 2); }
		if(/pass/is) { (undef,$mysqlpass) = split('=', $_, 2); }
	}
	close(MYCNF);
}

my $dbh = DBI->connect("DBI:mysql:host=localhost", "$mysqluser", "$mysqlpass", {'RaiseError' => 1});

while(1) {
	unless ($dbh->ping) {
		$dbh->disconnect;
		$dbh = DBI->connect("DBI:mysql:host=localhost", "$mysqluser", "$mysqlpass", {'RaiseError' => 1});
		my $rc = $dbh->ping;
		unless ($dbh->ping) { 
			print STDERR "Error, Could not reconnect to MySQL\n";
			exit;
		}
	}
	
	undef $abusers;
	undef %counter;
	my $watch = $dbh->prepare("SHOW PROCESSLIST");
	$watch->execute();
	while (my $ref = $watch->fetchrow_hashref()) {
		$counter{$ref->{'User'}} ++;
	}
	foreach $key (keys %counter) {
		if($counter{$key} > $max_concurrent_connections) {
			$abusers .= "$key:$counter{$key}\n";
		}
	}	
	if($abusers){
		my $subject = "WatchMySQL: Warning $hostname has MySQL Abusers\n";
		my $msg = "The Following Users have exceeded there maximum MySQL concurrent users limit\n\n Below is a list of users as well as how many times they are connected\n\n";
		open(SENDMAIL,"|/usr/sbin/sendmail -t");
		print SENDMAIL "To: <$warning_email>\n";
		print SENDMAIL "From: WatchMySQL\@$hostname\n";
		print SENDMAIL "Subject: $subject\n\n";
		print SENDMAIL "$msg$abusers";
		close(SENDMAIL);
	}
	if($kill_user == 1) {
		foreach ($abusers) {
			chomp;
			($abuser_user,undef) = split(':', $_ , 2);
			my $watch = $dbh->prepare("SHOW PROCESSLIST");
			$watch->execute();
		        while (my $ref = $watch->fetchrow_hashref()) {
				if($ref->{'User'} eq $abuser_user) {
					print "Killed $abuser_user\n";
					$dbh->do("kill $ref->{'Id'}");
				}
			}
		}
	}
	sleep $check_interval;
}

