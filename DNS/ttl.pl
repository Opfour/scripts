#!/bin/perl
use File::Find;
find(sub{
    local @ARGV=($_);
    local $^I="";
    while( <> ){
        s/(\$TTL\s+)\d+\b/$1 1800/;
        #s/\b\Q200.201.129.12\E\b/200.157.0.47/g;
        #to modify IP in dns file, uncomment line above
	print;
    }
},"/var/named");
