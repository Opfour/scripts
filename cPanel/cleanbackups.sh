#!/usr/bin/perl
# cPlicensing.net - scripts             Copyright(c) 2003 cPlicensing.net.
#                                       All rights Reserved.
# support@cPlicensing.net               http://cPlicensing.net
# Unauthorized copying is prohibited
#Version: 0.01

use POSIX;

$delete_old 	= '0'; #0 or 1, set to 1 to remove old account backups
if($ARGV[0] eq "-d") { $delete_old = '1'; }


$|++;
POSIX::nice(19);

print "Reading Backup Config...";
open(CPBACK,"/etc/cpbackup.conf") or die("Failed, Does it exist and do you have access?\n");
while(<CPBACK>) {
        s/\n//g;
        my($name,$value) = split(/ /, $_);
        $CONF{$name} = $value;
}
close(CPBACK);
print "Complete\n";

if ($CONF{'BACKUPENABLE'} ne "yes") {
        die "Backup Not Enabled\n";
}
if (! -e $CONF{'BACKUPDIR'}){
	die "Backup Dir Doesnt Exist\n";
}

until (`ps -ax` !~ m/cpbackup/) { 
	print "Detected cpbackup process...Sleeping for 60 Seconds\n"; 
	sleep(60);
};

if ($CONF{'BACKUPMOUNT'} eq "yes") {
	if(`mount` !~ m/$CONF{'BACKUPDIR'}/){
		system("mount","$CONF{'BACKUPDIR'}");
	}
	system("mount","-o","remount,rw","$CONF{'BACKUPDIR'}");
}

cleandir("$CONF{'BACKUPDIR'}/cpbackup/daily");
cleandir("$CONF{'BACKUPDIR'}/cpbackup/weekly");
cleandir("$CONF{'BACKUPDIR'}/cpbackup/monthly");

if ($CONF{'BACKUPMOUNT'} eq "yes") { system("umount","$CONF{'BACKUPDIR'}"); }

sub cleandir {
	my($target) = @_;
	
	opendir(DIRTYDIR,"$target");
	@DIRTYDIR = readdir(DIRTYDIR);
	closedir(DIRTYDIR);

	foreach(@DIRTYDIR) {
		next if /^\.\.?$|^files$|^dirs$/;
		if(-f "$target/$_"){
			$user = $_;
			$user =~ s/.tar.gz//;
			if(! -f "/var/cpanel/users/$user"){
				if($delete_old == 1){
					unlink("$target/$_");
					print "Deleted Old Backup... $target/$_\n";
				} else {
					print "Detected Old Backup... $target/$_\n";
				}
			}
			next;
		}
		if(-d "$target/$_"){
			if(! -f "/var/cpanel/users/$_"){
				if($delete_old == 1){
					#system("rm","-r","$target/$_");
					print "Directory Delete Not Supported, If you really want to remove dirs (incremental backups) you can edit this script and uncomment the line that looks like #system(\"rm\",\"-r\",\"$target/$_\")\n";
				} else {
					print "Detected Old Backup... $target/$_\n";
				}
			}
			next;
		}
	}
}

