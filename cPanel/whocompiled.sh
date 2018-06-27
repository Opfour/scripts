#!/usr/bin/perl
# cPlicensing.net - scripts        	Copyright(c) 2003 cPlicensing.net.
#                                 	All rights Reserved.
# support@cPlicensing.net      		http://cPlicensing.net
# Unauthorized copying is prohibited
# Version: 0.01


if (!-e "/usr/local/cpanel") {
        print "cPanel not found, Are you sure this is a cPanel box?\n";
        exit;
}

while(@USERS=getpwent()){
        if (-d "$USERS[7]" && -e "/var/cpanel/users/$USERS[0]") {
                if (-f "$USERS[7]/.bash_history") {
                        open(HISTORY,"$USERS[7]/.bash_history");
                        while(<HISTORY>) {
                                if (/\bcc\b/ || /\bgcc\b/ || /\bi386-redhat-linux-gcc\b/ || /\bmake\b/) {
                                        chomp;
                                        print "$USERS[0] ran... $_\n";
                                }
                        }
                        close(HISTORY);
                } else {
                        print "$USERS[0] odd... .bash_history doesnt exist.. Creating it\n";
                        open(FILE,">$USERS[7]/.bash_history");
                        close(FILE);
                        chmod(0600, "$USERS[7]/.bash_history") or die "Unable to chmod file: $!";
                        chown($USERS[2],$USERS[3],"$USERS[7]/.bash_history") or die "Unable to chown file: $!";
                }
        }
}

