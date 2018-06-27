#!/usr/bin/perl
# cPlicensing.net - scripts		Copyright(c) 2003 cPlicensing.net.
#					All rights Reserved.
# support@cPlicensing.net      		http://cPlicensing.net
# Unauthorized copying is prohibited
# Version: 0.02
$|++;

my ($MonitorPort) = @ARGV;
die "usage: <port>\n" unless $ARGV[0];

@OUT =	`netstat -an`;

#Proto Recv-Q Send-Q Local Address           Foreign Address         State

foreach (@OUT) {
	s/\n//g;
	($Proto,$RecvQ,$SendQ,$LocalAddress,$ForeignAddress,$State) = split(' ', $_, 6);
	next unless $LocalAddress =~ /(\d*)\.(\d*)\.(\d*).(\d*)/;
	($LocalIp,$LocalPort) = split(':', $LocalAddress, 2);
	($ForeignIp,$ForeignPort) = split(':', $ForeignAddress, 2);
#	next unless $LocalPort eq $MonitorPort;
	next if $ForeignIp eq "0.0.0.0";
	if($Proto eq "udp") {
		$UDP{$ForeignIp} ++;
	}
	if($Proto eq "tcp") {
		$TCP{$ForeignIp} ++;
	}
}
foreach $key (sort { $TCP{$b} <=> $TCP{$a} } keys %TCP) {
	print "TCP!!!$key:$TCP{$key}\n";
}
foreach $key (sort { $UDP{$b} <=> $UDP{$a} } keys %UDP) {
	print "UDP!!!$key:$UDP{$key}\n";
}

