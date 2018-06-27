#!/usr/bin/perl
#
# Written By: Shaun.Reitan -- Network Data Center Host, Inc.
# Description: Scans MySQL databases for old versions of phpbb and displays them.
#
# If you have a site that you want to host these scripts on please link your users to the
# scripts page at http://cPlicensing.net/ Thanks.


use strict;
use DBI;
use Getopt::Long;

my($opt_disable,$opt_quiet,$opt_contact,$opt_help,$phpbb_version,$phpbb_path,%found);

GetOptions (	'd' => \$opt_disable,
		'q' => \$opt_quiet,
		'c' => \$opt_contact,
		'h' => \$opt_help,
		'help' => \$opt_help );

chomp(my $hostname = `hostname`);

#2.0.xx  Only put the last oct below
my $current_version = '17';

if($opt_help) {
	print "Usage: $0 <OPTIONS>\n\n";
	print "Description: This script will search all of your mysql databases for a vulnerable\n";
	print "             version of phpbb.\n\n";
	print "\t-d\tDisable Vulnerable Versions of PHPBB\n";
	print "\t-q\tQuiet, dont print anything to STDOUT\n";
	print "\t-c\tAttempt to send user a notice\n";
	print "\t-h\tDisplay this screen\n";
	exit;
}

print "PHPBB Version Checker\t\tFor More Scripts GoTo: http://www.cPlicensing.net/\n" unless $opt_quiet;
print "Written By: Shaun.Reitan <> Network Data Center Host, Inc.\n\n" unless $opt_quiet;
print "This script will search all of your mysql databases for a vulnerable version of phpbb\n\n" unless $opt_quiet;


my %MYCNF;
open MYCNF, "</root/.my.cnf" or die("Fatal Error: Unable to open /root/.my.cnf");
while(<MYCNF>) {
	s/"|\n//g;
	my($d,$v) = split(/=/,$_,2);
	$MYCNF{$d} = $v;
}
close MYCNF;


# Only uncomment these if you need to change the default mysql user and pass, you really should modify your /root/.my.cnf
#$MYCNF{'user'} = '';
#$MYCNF{'pass'} = '';

print "Searching..." unless $opt_quiet;
my $dbh = DBI->connect("DBI:mysql:host=localhost",$MYCNF{'user'},$MYCNF{'pass'}, {'RaiseError' => 0});
die("Fatal Error: MySQL connection failed") unless $dbh;

my $dbs_sth = $dbh->prepare("SHOW DATABASES");
my $dbs_rv = $dbs_sth->execute();
while(my $dbname = $dbs_sth->fetchrow_array()) {
	my($user,undef) = split(/_/,$dbname,2);
	my $sth = $dbh->do("use \`$dbname\`");
	my $tables_sth = $dbh->prepare("SHOW TABLES");
	my $tables_rv = $tables_sth->execute();
	while(my $tablename = $tables_sth->fetchrow_array) {
		if($tablename =~ /_config$/) {
			my $rows_sth = $dbh->prepare("SELECT * FROM $tablename");
			my $rows_rv = $rows_sth->execute();
			while(my($n,$v) = $rows_sth->fetchrow_array()) {
				$phpbb_version = $v if $n eq "version";
				$phpbb_path = $v if $n eq "script_path";
			}
			if($phpbb_version) {
				my(undef,$f,$s) = split (/\./, $phpbb_version,3);
				if($f eq "0" and $s < $current_version) {
					$found{$user}{'version'} = $phpbb_version;
					$found{$user}{'path'} = $phpbb_path;
				}
			}
			$phpbb_version = 0;
			$phpbb_path = 0;
		}
	}
}
print "Complete, Found ".(scalar keys %found)." Vulnerable Versions of PHPBB 2.0.x\n\n" unless $opt_quiet;

foreach my $key (keys %found) {
	print "User: ".$key.", Version: ".$found{$key}{'version'}.", WebPath: ".$found{$key}{'path'}."\n" unless $opt_quiet;
	disable_phpbb($key,$found{$key}{'path'}) if $opt_disable;
	sendnotice($key) if $opt_contact;
}


sub sendnotice {
	my($user) = @_;

	my @USER = getpwnam($user);
	return unless @USER;
	
	return unless -f $USER[7]."/.contactemail";

	open CONTACTEMAIL , "<".$USER[7]."/.contactemail";
	chomp(my $user_email = <CONTACTEMAIL>);
	close CONTACTEMAIL;
	
	open SENDMAIL, "|/usr/sbin/sendmail -t";
	print SENDMAIL "To: <$user_email>\n";
	print SENDMAIL "From: Security\@$hostname\n";
	print SENDMAIL "Subject: Vulnerable PHPBB Warning!\n\n";
	if($opt_disable) {
		print SENDMAIL "Hello,\n\nA recent server scan revealed that your site had a vulnerable version of phpbb.  To help ensure the security of the server and all of it's users we have disabled your phpbb forum.  Please upgrade your forum to the latest phpbb version before you re-enable your forum.  Thank You.\n";
	} else {
		print SENDMAIL "Hello,\n\nA recent server scan revealed that your site had a vulnerable version of phpbb.  To help ensure the security of the server we are asking you to update your phpbb forum to the latest version.  Please do this immediately. Thank You\n";
	}
	close SENDMAIL;
}


sub disable_phpbb() {
	my($user,$path) = @_;

	unless ( -f "/usr/local/cpanel/cpanel" ) {
		print "Cannot Disable $user, This feature is for cPanel Servers Only\n" unless $opt_quiet;
		return;
	}
	unless( -f "/usr/local/apache/htdocs/suspended.page/phpbb_vuln.html" ) {
		open HTML, ">/usr/local/apache/htdocs/suspended.page/phpbb_vuln.html";
		print HTML "<html><head><title>PHPBB DISABLED</title></head><body bgcolor=white><center><b>The Following PHPBB Forum was disabled for security reasons.  If you are the webmaster of this forum please contact your web host for more detail.</b></center></html>\n";
		close HTML;
	}
		
	my @USER = getpwnam($user);
	if(@USER) {
		rename $USER[7]."/public_html/".$path."/.htaccess", $USER[7]."/".$path."/.htaccess.phpbbsuspended" if -f $USER[7]."/".$path."/.htaccess";
		open HTACCESS, ">".$USER[7]."/public_html/".$path."/.htaccess";
		print HTACCESS "RedirectMatch .* http://$hostname/suspended.page/phpbb_vuln.html\nOptions -Includes -Indexes -ExecCGI\n";
		close HTACCESS;
		chown($USER[2],$USER[3],$USER[7]."/public_html/".$path."/.htaccess");
	} else{
		print "Error: getpwnam returned false for $user\n" unless $opt_quiet;
	}

}

