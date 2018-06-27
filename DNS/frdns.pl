#!/usr/bin/perl -w
use strict;
use warnings;
use File::Basename;
use Getopt::Std;
use Net::Netmask;
use Net::Ping;
use Socket;
use Sys::Syslog;

my $start_time = time;
my $problems   = 0;
my $app        = basename($0);
my $ping;
my %opts;

# f shows FAILs, o shows OKs, v verbose, i input file, p pings
getopts('vfhi:op', \%opts);

usage() if $opts{'h'};

# default to showing all results.
unless ($opts{'o'} || $opts{'f'}) {
  $opts{'f'} = $opts{'o'} = 1;
}

my $iprange = shift unless $opts{'i'};
usage() unless $iprange || $opts{'i'}; # sanity check

eval {
  if ($opts{'p'}) { # requires root powers so only construct object if we need to.
    $ping = Net::Ping->new('icmp', 2);
  }
};

if ($@ =~ /icmp ping requires root privilege/) {
  print "$app - ping checks require root privilege to run\n";
  exit 1;
}

my @ipranges = get_ranges($iprange, $opts{'i'});

foreach my $range (@ipranges) {
  my $block = new Net::Netmask($range);

  for my $ip_address ($block->enumerate) {
    next if $ip_address eq $block->base();
    next if $ip_address eq $block->broadcast();

    print " -- checking $ip_address\n" if $opts{'v'};
    # lookup the PTR record for that IP.
    my $name = gethostbyaddr(inet_aton($ip_address), AF_INET);

    if ($opts{'p'}) {
      if ($ping->ping($ip_address) && (! defined $name)) {
        if ($opts{'f'}) {
          print "FAIL: Queried $ip_address : IP has no reverse record\n";
          $problems++;
          next;
        }
      }
    }

    next unless defined $name; # no reverse found. give up and move on

    warn "  -- IP: '$ip_address' :: NAME: '$name'\n" if $opts{'v'};

    my ($hostname, $aliases, $addrtype, $length, @addrs) = gethostbyname($name);
    $_ = inet_ntoa($_) for @addrs;

    # deal with round robin DNS.
    if (scalar @addrs > 1) { # handle multiple records
      if ($opts{'v'}) {
        warn " -- -- ROUND ROBIN - $_\n" for @addrs;
      }
    } elsif (scalar @addrs == 1) {
      warn " -- -- SINGLE - $addrs[0]\n" if $opts{'v'};
    } else {
      # this means it's got a reverse but not a forward. Complain.
      print "FAIL: Queried '$ip_address' : No forward record for '$name'\n";
      $problems++;
      next;
    }

    # see if they match
    if (grep { $ip_address eq $_ } @addrs) {
      if ($opts{'o'}) {
        print "OK: Queried '$ip_address' : Reverse is '$name' : Forward is ", join(", ", @addrs),"\n";
      }
    } else {
      if ($opts{'f'}) {
        print "FAIL: Queried '$ip_address' : Reverse is '$name' : Forward is ", join(", ", @addrs),"\n";
        $problems++;
      }
    }
  }
}

$ping->close() if defined $ping;

my $total_time = (time - $start_time);

# log that we're done.
openlog($app, "ndelay,pid", "local0");
syslog("info|local0", "$app took $total_time seconds to run - $problems problems found.");
closelog();

exit 0;

#=======================================================#

sub usage {
  print<<EOH;

Usage: $app [OPTIONS] <ip range(s)>
Check the forward and reverse record for an IP and warn if they are different.

Required Arguments:
  <ip ranges(s)> - A single, or multiple comma seperated, CIDR netmasks.

Optional Arguments:
  -i\tA file containing one CIDR netmask per line.
  -h\tThis information.
  -o\tOnly show correct mappings.
  -f\tOnly show broken mappings.
  -d\tDisplays additional debug messages.
  -p\tPerform ping checks - flag IPs that don't have reverse records.

Example:

  $app\t-f 10.10.10.0/24

Notes:
You must either specify a CIDR range on the command line or the '-i'
option with a filename as an argument (the file should contain one CIDR
range on each line).

Enabling the ping check will find any IPs that are active (respond to
ping) but lack a reverse DNS record. It will also slow the run down
significantly as it tries every IP address in the range and times out on
each unallocated address.

If a ping check fails but the forward and reverse records are fine $app
will output an OK.

EOH

  exit 0;
}

#-------------------------------------------------------#

sub get_ranges {
  # work out the ranges and return them.

  my $ranges    = shift;
  my $from_file = shift;
  my @ipranges;

  if ($from_file) {
    open(my $ranges_fh, $from_file)
      || die "Failed to open '$from_file': $!\n";

    @ipranges = grep { !/^\s*#/ } <$ranges_fh>;

    close $ranges_fh;
  } else {
    # allow multiple networks to be passed on the command line
    @ipranges = split(",", $iprange);
  }

  # TODO: add simple ip validator regex here to look for broken addresses

  return @ipranges;
}

#-------------------------------------------------------#
