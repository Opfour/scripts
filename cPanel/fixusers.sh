#!/usr/bin/perl -w

use strict;
my $text;

open(FILE, "list.txt") or die("Unable to open file");

while (my $domain = <FILE>) {
	chomp $domain;
	my $string = `grep -l $domain /var/cpanel/users/*`;
	chomp $string;
	my @user = split(/\//, $string);
	system("useradd $user[4]");
	system("groupadd $user[4]");
}

close(FILE);

