#!/usr/bin/perl


use Apache::ConfigParser;
use Data::Dumper;




$Data::Dumper::Indent = 3;         # pretty print with array indices

$Data::Dumper::Useqq = 1;          # print strings in double quotes




$conf_location = '/usr/local/apache/conf/httpd.conf';

my $c1 = Apache::ConfigParser->new();
my $rc = $c1->parse_file($conf_location);

if (not $rc) {
            print $c1->errstr, "\n";
    }


    my %domains;
                
    foreach my $vhost_node ( $c1->find_down_directive_names('VirtualHost') ) {
        my $domain;
        my $docroot;
        my $user;

        foreach my $docroot_node ( $c1->find_down_directive_names($vhost_node, 'DocumentRoot') ){
                $docroot = $docroot_node->value;
        }
        foreach my $servername_node ( $c1->find_down_directive_names($vhost_node, 'ServerName') ){
                $domain = $servername_node->value;
        }
        foreach my $user_node ( $c1->find_down_directive_names($vhost_node, 'SuexecUserGroup') ){
                $user_value = $user_node->value;
                $user_value =~ m/(.*)\ /;
                $user = $1;
        }


        # ok, we got the three needed values
         # see if this is the first 
         if( ref($domains{$user}) eq 'ARRAY'){
                 # it exists, push
                 push( @{$domains{$user}} , { 'Domain' => $domain, 'DocRoot' => $docroot});

        } else {
                $domains{$user} = ();
                push( @{$domains{$user}} , { 'Domain' => $domain, 'DocRoot' => $docroot});
        }


        }
    

        #ok, iterate and print any domains that do not have a match between docroot in conf and userdata file. 
        foreach $user ( keys(%domains)){
                #print Dumper( @{$domains{$user}} );
                foreach $dom_hash ( @{ $domains{$user}} ){
                        #print Dumper($dom_hash) ;
                        #print  $dom_hash->{"Domain"} . "\n";
                        my $domain = $dom_hash->{"Domain"};
                        my $docroot = $dom_hash->{"DocRoot"};

                        my $foo = `grep -i documentroot /var/cpanel/userdata/$user/$domain | awk '{print \$2}'`;
                        chomp $foo;

                        # if $foo doesnt match docroot, its a problem.
                        
                        if( $foo ne $docroot){ 
                                print "DOMAIN $domain saved docroot does not match in httpd.conf\n";
                                print "httpd.conf: $docroot\n";
                                print "saved valu: $foo\n";
                        }
                        #print $foo . "\n";
                }
        }


#my @foo = $rc->dump();
#foreach(@foo){
#       print $_ . "\n";
#}
      



