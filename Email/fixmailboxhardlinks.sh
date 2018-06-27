#!/usr/bin/perl
# cPlicensing.net - scripts             Copyright(c) 2003 cPlicensing.net.
#                                       All rights Reserved.
# support@cPlicensing.net               http://cPlicensing.net
# Unauthorized copying is prohibited
#Version: 0.01


if($ARGV[0] eq "--combine"){
        $movemail = 1;
} elsif($ARGV[0] eq "--discard") {
	$movemail = 0;
} else {
	print "Usage: $0 --combine or --discard\n\n";
	print "--combine\tThis option is for those anal people.  If a mailbox is found\n";
	print "\t\ttoo have two locations it will first dump the mail from the\n";
	print "\t\tbad location before it removes and recreated the hardlink\n";
	print "\t\tWith this option your users may end up asking you why they\n";
	print "\t\tare just receiving mail from months ago (depends obviously)\n\n";
	print "--discard\tThis option will just discard/remove the inbox file that should\n";
	print "\t\tbe hardlinked to the correct inbox file.\n";
	exit;
}

opendir(CPUSERS,"/var/cpanel/users");
@CPUSERS = readdir(CPUSERS);
close CPUSERS;

foreach $cpuser (@CPUSERS) {
        if($cpuser =~ /^\./) { next; }
        undef $box1, $box2, $domain;
        if(!getpwnam($cpuser)) {
                print "Warning! There is not a system user for $cpuser, skipping\n";
                next;
        }
        open(USERDB,"/var/cpanel/users/$cpuser");
        while(<USERDB>){
                if(/^DNS=(\S+)/) { $domain = $1 }
        }
        close USERDB;
        if(!$domain) { next; }
        @SYSINFO = getpwnam($cpuser);
        open(MAILPASSWD,"$SYSINFO[7]/etc/passwd");
        while(<MAILPASSWD>) {
                ($mailbox,undef,undef,undef,undef,undef,undef) = split(':', $_, 7);
                $box1 = getinode("$SYSINFO[7]/mail/$domain/$mailbox/inbox");
                $box2 = getinode("$SYSINFO[7]/mail/$mailbox/inbox");
                if(($box1 != $box2) && ($box2)) {
                        print "Warning! Two Seperate inbox files found on $domain for mailbox $mailbox...\n";
                        if($movemail) {
                                print "->Moving mail into one mailbox...";
                                open(MBOX2,"$SYSINFO[7]/mail/$mailbox/inbox");
                                open(MBOX1,">>$SYSINFO[7]/mail/$domain/$mailbox/inbox");
                                while(<MBOX2>) {
                                        print MBOX1 $_;
                                }
                                close MBOX1;
                                close MBOX2;
                                print "Done\n";
                        }
                        unlink("$SYSINFO[7]/mail/$mailbox/inbox");
                        link("$SYSINFO[7]/mail/$domain/$mailbox/inbox","$SYSINFO[7]/mail/$mailbox/inbox");
                        print "$mailbox\@$domain FIXED\n";
                }
        }
}


sub getinode() {
        ($file) = @_;
        if(-f $file) {
                ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
                return $ino;
        } else {
                return 0;
        }
}

