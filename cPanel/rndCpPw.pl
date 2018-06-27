#!/usr/bin/perl
### rndCpPw.pl
#
# AUTHOR: Scott Sullivan (ssullivan@liquidweb.com)
#
# GENERAL:
# See the POD (perldoc /path/to/rndCpPw.pl) or --help       
### 

use JSON;
use LWP::UserAgent;
use Encode;
use Scalar::Util qw(looks_like_number);
use Term::ANSIColor;

use strict;

my $version = '0.3';

sub preChecks {
	if ( $< != 0 ) {
		print "ERROR: must be root to run this.\n";
		exit(1);
	}
	my $cpanelVerify = `/sbin/chkconfig --list | grep cpanel`;
	if ( $cpanelVerify !~/3:on/) {
	        print "ERROR: cPanel not found (needs to be enabled in chkconfig run level 3).\n";
	        exit(1);
	}
}

sub getAuth {
        my $silent = $_[0];
        if ( $silent ne 'yes' ) {
                print "Generating hash...";
        }
        system("QUERY_STRING=\\\"regen=1\\\" /usr/local/cpanel/whostmgr/bin/whostmgr ./setrhash &> /dev/null");
        my $hashfile = '/root/.accesshash';
        if (! -e $hashfile) {
                print "ERROR: Failed to automatically generate hash! Please try logging into WHM and click `Setup Remote Access Key` and then re-run this script. \n";
                exit(1);
        }
        my $hash = `cat /root/.accesshash`;
        if ( $silent ne 'yes' ) {
                print "success!\n";
        }
        $hash =~ s/\n//g;
        my $auth = "WHM root:" . $hash;
        return $auth;
}

sub call {
        my $url = $_[0];
        my $params = $_[1] || {};
        my $auth = getAuth('yes');
        my $json = new JSON;
        my $ua = LWP::UserAgent->new;
        $ua->agent("rndCpPw");
        $ua->env_proxy();
        my $request = HTTP::Request->new(POST => $url);
        $request->header( Authorization => $auth );
        $request->content_type('application/jsonrequest');
        $request->content("$params");
        my $response = $ua->request($request);
        my $rawResponse = $response->content;
        my $result = encode("UTF-8", $rawResponse);
        my $decoded;
        eval {
                $decoded = $json->allow_nonref->utf8->relaxed->decode($result);
        };
        if ($@) {
                print "ERROR: Didn't receive a valid JSON response from cPanel API.\n";
                print "Got Error: $@ ";
                exit(1);
        }
        return $decoded;
}

sub help {
	print color 'yellow'; print "\nRandomizing cPanel Passwords: \n\n"; print color 'reset';
	print "--cpuser all passwordLength --- Sets all cPanel accounts to random password equal in length to passwordLength specified.\n";
	print "--cpuser cPanelAccount passwordLength --- Sets specified cPanel account to random password equal in length to passwordLength specified.\n";
	print color 'yellow'; print "\nRandomizing email passwords:\n\n"; print color 'reset';
	print "--mailbox all passwordLength --- Randomize all email account passwords for all cPanel accounts to specified length. \n";
	print "--mailbox cPanelAccount passwordLength --- Randomizes all email accounts under cPanelAccount to random password of specified length.\n";
	print "--mailbox cPanelAccount passwordLength user\@domain.com --- Randomizes user\@domain.com to random password of specified length.\n";
	print color 'yellow'; print "\nRandomizing FTP passwords:\n\n"; print color 'reset';
	print "--ftp all passwordLength --- Randomize all FTP account passwords for all cPanel accounts to specified length. \n";
	print "--ftp cPanelAccount passwordLength --- Randomizes all FTP accounts under cPanelAccount to random password of specified length.\n";
}

sub generate {
        my $password_length = shift;
        my $password;

        my @chars=('a'..'z','A'..'Z','0'..'9','_','!','^','=','@',,'-',,',','|','(',')','{','}','<','>',';','/',']','[');
        foreach (1..$password_length) {
                $password.=$chars[rand @chars];
        };

        return $password;
}

sub chngCpUser {
	die "chngCpUser() requires two arguments. Something bad happened you shouldnt see this!\n" if (scalar(@_) != 2);

	my $cpArg = $_[0];
	my $length = $_[1];

	if ( $cpArg eq 'all' ) {
		my $acct_resp = call("http://127.0.0.1:2086/json-api/listaccts");
		my $count = 0;
		my $error = 0;
		for my $users( @{$acct_resp->{acct}} ) {
			my $pass = generate($length);
			print color 'bold blue'; print "Working with: $users->{user}\n"; print color 'reset';
			my $resp = call("http://127.0.0.1:2086/json-api/passwd?user=$users->{user}&pass=$pass");
		
			print color 'dark blue'; print "$resp->{passwd}[0]{rawout}"; print color 'reset';
			if ( $resp->{passwd}[0]{statusmsg} =~ m/Password changed for user/ ) {
				print color 'bold blue'; print "Set $users->{user} password to: $pass \n\n"; print color 'reset';
				$count++;
			}			
			else {
				print color 'red'; print "ERROR: $resp->{passwd}[0]{statusmsg} \n\n"; print color 'reset';
				$error++;
			}	
		};
		print color 'yellow'; print "Finished; Set $count cPanel accounts to random $length character password. Errors: $error\n"; print color 'reset';
	}
	else {
		my $valid = chkCpUser("$cpArg");
		if ( $valid ne 'true' ) {
			print "$cpArg is not a valid cPanel user.\n";
		}
		else {
			my $pass = generate($length);
			print color 'bold blue'; print "Working with: $cpArg\n"; print color 'reset';
			my $resp = call("http://127.0.0.1:2086/json-api/passwd?user=$cpArg&pass=$pass");
			
			print color 'dark blue'; print "$resp->{passwd}[0]{rawout}"; print color 'reset';
			if ( $resp->{passwd}[0]{statusmsg} =~ m/Password changed for user/ ) {
				print color 'bold blue'; print "Set $cpArg password to: $pass \n\n"; print color 'reset';
			}
			else {
				print color 'red'; print "ERROR: $resp->{passwd}[0]{statusmsg} \n\n"; print color 'reset';
			}
		}
	}
}

sub chngFTPuser {
	die "chngFTPuser() requires two arguments. Something bad happened you shouldnt see this!\n" if (scalar(@_) != 2);
	
        my $cpArg = $_[0];
        my $length = $_[1];

	if ( $cpArg eq 'all' ) {
		my $acct_resp = call("http://127.0.0.1:2086/json-api/listaccts");
		for my $users( @{$acct_resp->{acct}} ) {
			my $ftpUsers = call("http://127.0.0.1:2086/json-api/cpanel?user=$users->{user}&cpanel_jsonapi_module=Ftp&cpanel_jsonapi_func=listftpwithdisk&cpanel_jsonapi_version=2&domain=$users->{domain}");
			my $runCount = '0';
			for my $ftps( @{$ftpUsers->{cpanelresult}->{data}} ) {
				if ( $runCount == 0 ) {
					print color 'bold blue'; print "\nRandomizing $users->{domain} FTP accounts passwords...\n\n"; print color 'reset';
				}	
				my $pass = generate($length);
				my $chngPassResult = call("http://127.0.0.1:2086/json-api/cpanel?cpanel_jsonapi_user=$users->{user}&cpanel_jsonapi_module=Ftp&cpanel_jsonapi_func=passwd&cpanel_jsonapi_version=2&user=$ftps->{login}&pass=$pass");
				if ( $chngPassResult->{cpanelresult}->{data}[0]{result} != '1' ) {	
					print color 'red'; print "** ERROR: Was unable to change the password for $ftps->{serverlogin} ; $chngPassResult->{cpanelresult}->{data}[0]{reason}\n"; print color 'reset';
				}
				else {
					print "** Set $ftps->{serverlogin} to: $pass\n";
				}
				$runCount++;
			};
		};
	}
	else {
		my $valid = chkCpUser("$cpArg");
		if ( $valid ne 'true' ) {
			print "$cpArg is not a valid cPanel user.\n";
		}
		else {
			my $accntInfo = call("http://127.0.0.1:2086/json-api/accountsummary?user=$cpArg");
			my $domain;
			for my $info( @{$accntInfo->{acct}} ) {
				$domain = $info->{domain};	
			};
			my $ftpUsers = call("http://127.0.0.1:2086/json-api/cpanel?user=$cpArg&cpanel_jsonapi_module=Ftp&cpanel_jsonapi_func=listftpwithdisk&cpanel_jsonapi_version=2&domain=$domain");
			my $counter = '0';
                        print color 'bold blue'; print "\nRandomizing $domain FTP accounts passwords...\n\n"; print color 'reset';
			
			for my $ftps( @{$ftpUsers->{cpanelresult}->{data}} ) {
                                my $pass = generate($length);
				
                                my $chngPassResult = call("http://127.0.0.1:2086/json-api/cpanel?cpanel_jsonapi_user=$cpArg&cpanel_jsonapi_module=Ftp&cpanel_jsonapi_func=passwd&cpanel_jsonapi_version=2&user=$ftps->{login}&pass=$pass");
				if ( $chngPassResult->{cpanelresult}->{data}[0]{result} != '1' ) {
                                        print color 'red'; print "** ERROR: Unable to change password for $ftps->{serverlogin}; $chngPassResult->{cpanelresult}->{data}[0]{reason}\n"; print color 'reset';
                                }
                                else {
                                        print "** Set $ftps->{serverlogin} to: $pass\n";
                                }
                                $counter++;
                        };
                        if ( $counter == 0 ) {
                                print "$cpArg has no FTP accounts.\n";
                        }
		}
	}
}

sub validateMailbox {
	my $mailbox = $_[0];
	my $cpUser = $_[1];
	my $domain = $_[2];

	my $valid = 'no';
	my $mailboxes = call("http://127.0.0.1:2086/json-api/cpanel?user=$cpUser&cpanel_jsonapi_module=Email&cpanel_jsonapi_func=listpopswithdisk&cpanel_jsonapi_version=2&domain=$domain");
	for my $boxes( @{$mailboxes->{cpanelresult}->{data}} ) {
		if ( $boxes->{email} eq $mailbox ) {
			$valid = 'yes';
		}
	};
	return $valid;
}

sub chngMailbox {
	die "chngMailbox() requires at least two arguments. Something bad happened you shouldnt see this!\n" if (scalar(@_) > 3);
	
	my $cpArg = $_[0];
	my $length = $_[1];
	my $singleMailbox = $_[2];

	if ( $cpArg eq 'all' ) {
		my $acct_resp = call("http://127.0.0.1:2086/json-api/listaccts");
		for my $users( @{$acct_resp->{acct}} ) {
			my $mailboxes = call("http://127.0.0.1:2086/json-api/cpanel?user=$users->{user}&cpanel_jsonapi_module=Email&cpanel_jsonapi_func=listpopswithdisk&cpanel_jsonapi_version=2&domain=$users->{domain}");
			my $runCount = '0';
			for my $boxes( @{$mailboxes->{cpanelresult}->{data}} ) {
				if ( $runCount == 0 ) {
					print color 'bold blue'; print "\nRandomizing $users->{domain} email accounts passwords...\n\n"; print color 'reset';
				}
				my $pass = generate($length);
				my $chngPassResult = call("http://127.0.0.1:2086/json-api/cpanel?user=$users->{user}&cpanel_jsonapi_module=Email&cpanel_jsonapi_func=passwdpop&cpanel_jsonapi_version=2&domain=$users->{domain}&email=$boxes->{user}&password=$pass");
				if ( $chngPassResult->{cpanelresult}->{data}[0]{result} != '1' ) {
					print color 'red'; print "** ERROR: Was unable to change the password for $boxes->{email} !\n"; print color 'reset';
				}
				else {
					print "** Set $boxes->{email} to: $pass\n";
				}
				$runCount++;
			};
		};
	}
	else {
		my $valid = chkCpUser("$cpArg");
		if ( $valid ne 'true' ) {
			print "$cpArg is not a valid cPanel user.\n";
		}
		else {
			my $accntInfo = call("http://127.0.0.1:2086/json-api/accountsummary?user=$cpArg");
			my $domain;
			for my $info( @{$accntInfo->{acct}} ) {
				$domain = $info->{domain};
			};
			my $mailboxes = call("http://127.0.0.1:2086/json-api/cpanel?user=$cpArg&cpanel_jsonapi_module=Email&cpanel_jsonapi_func=listpopswithdisk&cpanel_jsonapi_version=2&domain=$domain");
			my $counter = '0';
			print color 'bold blue'; print "\nRandomizing $domain email accounts passwords...\n\n"; print color 'reset';
			for my $boxes( @{$mailboxes->{cpanelresult}->{data}} ) {
				my $pass = generate($length);

				if ( $singleMailbox ) {
					if ( $boxes->{email} ne $singleMailbox ) {
						next;
					}
					my $chkMailbox = validateMailbox("$singleMailbox","$cpArg","$domain");
					if ( $chkMailbox eq 'yes' ) {
						my $chngPassResult = call("http://127.0.0.1:2086/json-api/cpanel?user=$cpArg&cpanel_jsonapi_module=Email&cpanel_jsonapi_func=passwdpop&cpanel_jsonapi_version=2&domain=$domain&email=$boxes->{user}&password=$pass");
						if ( $chngPassResult->{cpanelresult}->{data}[0]{result} != '1' ) {
							print "** ERROR: Was unable to change the password for $singleMailbox !\n";
						}
						else {
							print "** Set $singleMailbox to: $pass\n";
						}
					}
					else {
						print "ERROR: $singleMailbox is not a valid email under $cpArg.\n";
					}
					exit;
				}

				my $chngPassResult = call("http://127.0.0.1:2086/json-api/cpanel?user=$cpArg&cpanel_jsonapi_module=Email&cpanel_jsonapi_func=passwdpop&cpanel_jsonapi_version=2&domain=$domain&email=$boxes->{user}&password=$pass");
				if ( $chngPassResult->{cpanelresult}->{data}[0]{result} != '1' ) {
					print color 'red'; print "** ERROR: Was unable to change the password for $boxes->{email} !\n"; print color 'reset';
				}
				else {
					print "** Set $boxes->{email} to: $pass\n";
				}
				$counter++;
			};
			if ( $counter == 0 ) {
				print "$cpArg has no email accounts.\n";
			}
		}
	}	
}

sub chkCpUser {
	die "chkCpUser() requires one argument. Something bad happened you shouldnt see this!\n" if (scalar(@_) != 1);	

	my $cpArg = $_[0];

	my $accntList = call("http://127.0.0.1:2086/json-api/listaccts");
	my $isValid;
	for my $userCnt( @{$accntList->{acct}} ) {
		if ( $userCnt->{user} eq $cpArg ) {
			$isValid = 'true';
		}
	}
	if ( $isValid ne 'true' ) {
		$isValid = 'false';
	}
	
	return $isValid;
}

### Main() ###

preChecks();
print "-$0 $version\n";
if ( $ARGV[0] eq '--cpuser' ) {
	if ( scalar(@ARGV) > '3' ) {
		print "Too many arguments passed. For help, see --help.\n";
		exit;
	}
	elsif ( defined($ARGV[1]) && defined($ARGV[2]) ) {
		if ( ! looks_like_number($ARGV[2]) ) {
			print "Password length must be numeric. You specified: $ARGV[2]\n";
			exit;
		}
		chngCpUser("$ARGV[1]","$ARGV[2]"); ## cpArg, length
	}
	else {
		print "Please give a valid argument to --cpuser. For help, see --help.\n";
	}
}
elsif ( $ARGV[0] eq '--mailbox' ) {
	if ( scalar(@ARGV) > '4' ) {
		print "Too many arguments passed. For help, see --help.\n";
		exit;
	}
	elsif ( defined($ARGV[1]) && defined($ARGV[2]) ) {
		if ( ! looks_like_number($ARGV[2]) ) {
			print "Password length must be numeric. You specified: $ARGV[2]\n";
			exit;
		}
		chngMailbox("$ARGV[1]","$ARGV[2]","$ARGV[3]"); ## cpArg, length 
	}      
	else {
		print "Please give a valid argument to --mailbox. For help, see --help.\n";
	}
}
elsif ( $ARGV[0] eq '--ftp' ) {
	if ( scalar(@ARGV) > '3' ) {
		print "Too many arguments passed. For help, see --help.\n";
		exit;
	}
	elsif ( defined($ARGV[1]) && defined($ARGV[2]) ) {
		if ( ! looks_like_number($ARGV[2]) ) {	
			print "Password length must be numeric. You specified: $ARGV[2]\n";
			exit;
		}
		chngFTPuser("$ARGV[1]","$ARGV[2]");
	}
	else {
		print "Please give a valid argument to --ftp. For help, see --help.\n";
	}
}
elsif ( $ARGV[0] eq '--help' ) {
	help();
}
else {
	print "Invalid option. For help, see --help.\n";
}

=head1 TITLE

 rndCpPw.pl - Randomize cPanel , cPanel email accounts, cPanel FTP account passwords.

=head1 SUMMARY

 This script randomizes cPanel, cPanel email accounts, and cPanel FTP accounts passwords to specified length.

=head1 USAGE

 Randomizing cPanel Passwords: 

 --cpuser all passwordLength --- Sets all cPanel accounts to random password equal in length to passwordLength specified.
 --cpuser cPanelAccount passwordLength --- Sets specified cPanel account to random password equal in length to passwordLength specified.

 Randomizing email passwords:

 --mailbox all passwordLength --- Randomize all email account passwords for all cPanel accounts to specified length. 
 --mailbox cPanelAccount passwordLength --- Randomizes all email accounts under cPanelAccount to random password of specified length.
 --mailbox cPanelAccount passwordLength user@domain.com --- Randomizes user@domain.com to random password of specified length.

Randomizing FTP passwords:

--ftp all passwordLength --- Randomize all FTP account passwords for all cPanel accounts to specified length. 
--ftp cPanelAccount passwordLength --- Randomizes all FTP accounts under cPanelAccount to random password of specified length.

=head1 AUTHOR

 Scott Sullivan (ssullivan@liquidweb.com)

=cut
