#!/usr/bin/perl
# cPlicensing.net - scripts        	Copyright(c) 2003 cPlicensing.net.
#                                 	All rights Reserved.
# support@cPlicensing.net      		http://cPlicensing.net
# Version: 0.02


print "Starting Scan...\n";

while(@USERS=getpwent()){
        if (-d "$USERS[7]/public_html") {
                if (-f "$USERS[7]/public_html/404.shtml") {
                        print "$USERS[0] 404.shtml exists\n";
                } else {
                        print "$USERS[0] creating 404.shtml...";
                        open(FILE,">$USERS[7]/public_html/404.shtml") or die "Unable to create file: $!";
                        close(FILE);
                        chmod(0644, "$USERS[7]/public_html/404.shtml") or die "Unable to chmod file: $!";
                        chown($USERS[2],$USERS[3],"$USERS[7]/public_html/404.shtml") or die "Unable to chown file: $!";
                        print "done\n";
                }
        }
}
if (-f "/root/cpanel3-skel/public_html/404.shtml") {
        print "404.shtml file exists in skel dir\n";
} else {
        print "Creating 404.shtml file in skel dir...";
        open(FILE,">/root/cpanel3-skel/public_html/404.shtml") or die "Unable to create file: $!";
        print "done\n";
}

print "Scan Complete!\n";

#ChangeLog
#Version :: YYYY.MM.DD :: Type :: Description
#
#0.2 :: 2003.11.06 :: Bug Fix :: 404.shtml was created in the root skel folder, changed to public_html

