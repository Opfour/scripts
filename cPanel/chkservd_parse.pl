#! /usr/bin/perl
use warnings;
use strict;

my $v_VERSION = "2.0.0";

my $b_START_PARSE = 0;
my $b_PROCESS = 0;
my @v_SERVICES = ();
my $v_OUTPUT_LINE = "";
my $v_DISKCHECK_LINE = "";
my $v_TIMESTAMP = "";

sub fn_output {
### Separate out service checks into multiple lines.
   if ( $v_OUTPUT_LINE =~ m/Service Check Started$/ || $b_PROCESS == 1 ) {
      if ( $v_OUTPUT_LINE =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]/ ) {
      ### If the line begins with a timestamp, we set that as a time stamp, otherwise we keep the timestamp from last time.
         $v_TIMESTAMP = $v_OUTPUT_LINE;
         $v_TIMESTAMP =~ s/^(\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]).*$/$1/;
      };
      for my $v_SERVICE (@v_SERVICES) {
      ### For each service in the lsit of services.
         if ( $v_OUTPUT_LINE =~ m/$v_SERVICE \[/ ) {
            my $v_OUTPUT_LINE = $v_OUTPUT_LINE;
            ### Lets otput the data from JUST that service (we hope).
            $v_OUTPUT_LINE =~ s/.*($v_SERVICE \[([Tt]oo soon after restart to check\]|.*[Rr]estarting $v_SERVICE|.*?\]\]|.*$)).*/$1/;
            ### If the line ends in "Service Check Started", let's replace that with something more useful.
            ### In most cases, having "service check started" at the end of a "service check" line indicates that the last check ended abruptly, but I've seen at least one instance where two checks just randomly decided to run concurrently.
            $v_OUTPUT_LINE =~ s/(Service Check Started$|Chkservd is currently suspended.*$)/...Service MIGHT have failed. Output from the log file is ambiguous. Check the log entries around timestamp \"$v_TIMESTAMP\" to confirm.\]/;
            print "$v_TIMESTAMP $v_OUTPUT_LINE\n";
         };
      };
      $v_OUTPUT_LINE = "";
      $b_PROCESS = 0;
   };
};

sub fn_disk_check {
### Separate out disk checks into multiple lines.
   $v_TIMESTAMP =~ s/^(\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]).*$/$1/;
   ### This cust off the status information, however when I know more of what variation we might see here, I'll probably want to keep this.
   $v_DISKCHECK_LINE =~ s/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] Disk check \.* (.*) \.* \{status.*$/$2/;
   my @v_DISKS = split /[[:blank:]]+\.+[[:blank:]]+/, $v_DISKCHECK_LINE;
   for my $v_DISK (@v_DISKS) {
      print "$v_TIMESTAMP Disk check: $v_DISK\n";
   };
};

sub fn_version {
my $v_MESSAGE =  <<'EOF';

Version 2.0.0 (2016-05-03)-
     -Entire script has been rewritten in Perl.
     -lines from the chkservd.log file can be piped in to be processed.
     -No longer accepts arguments for filename and number of lines - piping in is more straight forward.

Version 1.0.2 (2016-03-27)-
     -Improved help and version output.
     -Changed all "grep" to "egrep" for a very marginal speed increase.
     -Modified variable names to fit the formatting I typically use

Version 1.0.1 (2015-07-18)-
     -Added better comments within the script.
     -Minor rearrangements to make the script more readable.

Version 1.0.0 (2015-01-28)-
     -Original version.

EOF
### Every pure perl solution for this is dumb. Using "fold" instead.
open( OUT_COLS, "| bash -c \"fold -s -w \$(( \$(tput cols) - 1 ))\"" );
print OUT_COLS "$v_MESSAGE";
exit 0;
};

sub fn_help {
my $v_MESSAGE =  <<'EOF';

chkservd_parse.pl - a tool to parse the output of chkservd in a manner that makes it more human readable, as well as easier to grep.

USAGE:

Lines from /var/log/chkservd.log are piped into chkservd_parse.pl. Examples:

   tail -n [some number] /var/log/chkservd.log | ./chkservd_parse.pl
   grep -C10 "2016-04-04 08:33:56 -0400" /var/log/chkservd.log | ./chkservd_parse.pl

Note that chkservd_parse.pl relies on multiple lines in the chkservd.log file to tell it what and when data should be output. If you're going to grep for specific data, it's best to capture lines surrounding that data as well (with "grep -C", for example).

OTHER USAGE:

./chkservd_parse.pl --version
./chkservd_parse.pl -v

     Outputs version information.

./chkservd_parse.pl --help
./chkservd_parse.pl -h

     Outputs this help information.

EOF
### Every pure perl solution for this is dumb. Using "fold" instead.
open( OUT_COLS, "| bash -c \"fold -s -w \$(( \$(tput cols) - 1 ))\"" );
print OUT_COLS "$v_MESSAGE";
exit 0;
};

if ( $ARGV[0] ) {
   if ( $ARGV[0] eq "--help" || $ARGV[0] eq "-h" ) {
      fn_help();
   } elsif ( $ARGV[0] eq "--version" || $ARGV[0] eq "-v" ) {
      fn_version();
   } else {
      fn_help();
   };
} elsif ( -t STDIN ) {
   fn_help();
};

while (defined ($_ = <ARGV>)) {
   if ( "$_" =~ m/^Service Check Started/ || ( "$_" =~ m/^Service Check Finished/ && $b_START_PARSE == 1 ) ) {
      if ( $b_START_PARSE == 1 && $v_OUTPUT_LINE ) {
         $b_PROCESS = 1;
         fn_output();
      };
      ### We don't want to start parsing until we get to a starting point (otherwise everything would be all higgeldy-piggeldy).
      $b_START_PARSE = 1;
   } elsif ( "$_" =~ m/^Loading services/ && $b_START_PARSE == 1 ) {
      ### grab a list of services that are being checked so that we can iterate through them later.
      $_ =~ s/^Loading services[[:blank:]]*\.*(.*?)\.*[[:blank:]]*Done$/$1/;
      $_ =~ s/\.+/./g;
      @v_SERVICES = split /\./, $_;
   } elsif ( ( "$_" =~ m/^The previous service check is still running/ || "$_" =~ m/^Chkservd is currently suspended/ ) && $b_START_PARSE == 1 ) {
      ### In either of these instances, we just want to output the line as a whole.
      chomp $_;
      print "$_\n";
   } elsif ( "$_" =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] Disk check/ && $b_START_PARSE == 1 ) {
      ### Let's separate this out into individual lines for each file system.
      chomp $_;
      $v_DISKCHECK_LINE = $v_TIMESTAMP = $_;
      fn_disk_check()
   } elsif ( "$_" =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] OOM check/ && $b_START_PARSE == 1 ) {
      ### I need to know more about what variations we might see in output here before I know exactly what to do with this.
      chomp $_;
      print "$_\n";
   } elsif ( "$_" =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] Service check/ && $b_START_PARSE == 1 ) {
      ### This is the start of a service check, but not necessarily the whole thing.
      chomp $_;
      $v_OUTPUT_LINE = $_;
      fn_output();
   } elsif ( $b_START_PARSE == 1 ) {
      ### Anything else is probably the continuation of a service check.
      chomp $_;
      $v_OUTPUT_LINE = $v_OUTPUT_LINE . " " . $_;
      fn_output();
   };
};
