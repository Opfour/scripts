#!/usr/bin/perl
# liquidweb.com
# wordpress admin adder

use strict;
use DBI;
use DBD::mysql;

my $db = shift || die "usage: $0 DB\n";

print "Enter lwsupport user password:\n";
my $pass = <>;
chomp($pass);

my $dsn = "DBI:mysql:$db;mysql_read_default_file=$ENV{HOME}/.my.cnf";
my $dbh = DBI->connect($dsn, undef, undef, {RaiseError => 1}) or die "$0: Cannot connect to MySQL server: $DBI::errstr\n";

my $sql = "INSERT IGNORE INTO wp_users (id,user_login,user_pass,user_nicename,user_email,user_url,user_registered,user_activation_key,user_status,display_name) VALUES(9999,'lwsupport',MD5('$pass'),'LW Support','support\@liquidweb.com','','2010-01-01 00:00:00','',0,'LW Support');";
$dbh->do("$sql") or die "Unable to execute query: $DBI::errstr\n";
print "+ Inserted user 'lwsupport' with pass '$pass'\n";

$sql = "INSERT IGNORE INTO wp_usermeta (user_id,meta_key,meta_value) VALUES(9999,'wp_capabilities','a:1:{s:13:\"administrator\";b:1;}');";
$dbh->do("$sql") or die "Unable to execute query: $DBI::errstr\n";
print "+ Inserted capabilities for user 'lwsupport'\n";

$sql = "INSERT IGNORE INTO wp_usermeta (user_id,meta_key,meta_value) VALUES(9999,'wp_user_level',10);";
$dbh->do("$sql") or die "Unable to execute query: $DBI::errstr\n";
print "+ Inserted administrator privileges for user 'lwsupport'\n";

$dbh->disconnect or warn "Disconnect failed: $DBI::errstr\n";
print "You're all set.\n";
