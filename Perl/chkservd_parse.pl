#! /usr/bin/perl
use warnings;
use strict;

my $v_VERSION = "2.2.0";

my $b_start_parse = 0;
my $b_highlight = 0;
my $b_process = 0;
my @v_services = ();
my $v_output_line = "";
my $v_diskcheck_line = "";
my $v_timestamp = "";
my @v_oom_records = ();

#===================#
#== Standard Mode ==#
#===================#

sub fn_standard {
   while (<STDIN>) {
      my $v_input_line = $_;
      if ( $v_input_line =~ m/^Service Check Started/ || ( $v_input_line =~ m/^Service Check Finished/ && $b_start_parse ) ) {
         if ( $b_start_parse == 1 && $v_output_line ) {
            $b_process = 1;
            fn_output();
         };
         ### We don't want to start parsing until we get to a starting point (otherwise everything would be all higgeldy-piggeldy).
         $b_start_parse = 1;
      } elsif ( $v_input_line =~ m/^Loading services/ && $b_start_parse ) {
         ### grab a list of services that are being checked so that we can iterate through them later.
         $v_input_line =~ s/^Loading services[[:blank:]]*\.*(.*?)\.*[[:blank:]]*Done$/$1/;
         $v_input_line =~ s/\.+/./g;
         @v_services = split( /\./, $v_input_line );
      } elsif ( ( $v_input_line =~ m/^The previous service check is still running/ || $v_input_line =~ m/^Chkservd is currently suspended/ ) && $b_start_parse ) {
         ### In either of these instances, we just want to output the line as a whole.
         chomp( $v_input_line );
         print "$v_input_line\n";
      } elsif ( $v_input_line =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] Disk check/ && $b_start_parse ) {
         ### Let's separate this out into individual lines for each file system.
         chomp( $v_input_line );
         $v_diskcheck_line = $v_timestamp = $v_input_line;
         fn_disk_check()
      } elsif ( $v_input_line =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] OOM check/ && $b_start_parse ) {
         ### I need to know more about what variations we might see in output here before I know exactly what to do with this.
         chomp( $v_input_line );
         fn_oom_check( $v_input_line );
      } elsif ( $v_input_line =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] Service check/ && $b_start_parse ) {
         ### This is the start of a service check, but not necessarily the whole thing.
         chomp( $v_input_line );
         $v_output_line = $v_input_line;
         fn_output();
      } elsif ( $b_start_parse == 1 ) {
         ### Anything else is probably the continuation of a service check.
         chomp $v_input_line;
         $v_output_line = $v_output_line . " " . $v_input_line;
         fn_output();
      }
   }
}

sub fn_output {
### Separate out service checks into multiple lines.
   if ( $v_output_line =~ m/Service Check Started$/ || $b_process == 1 ) {
      if ( $v_output_line =~ m/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]/ ) {
      ### If the line begins with a timestamp, we set that as a time stamp, otherwise we keep the timestamp from last time.
         $v_timestamp = $v_output_line;
         $v_timestamp =~ s/^(\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]).*$/$1/;
      }
      for my $v_service (@v_services) {
      ### For each service in the lsit of services.
         if ( $v_output_line =~ m/$v_service \[/ ) {
            my $v_output_line = $v_output_line;
            ### Lets otput the data from JUST that service (we hope).
            $v_output_line =~ s/.*($v_service \[([Tt]oo soon after restart to check\]|.*[Rr]estarting $v_service|.*?\]\]|.*$)).*/$1/;
            ### If the line ends in "Service Check Started", let's replace that with something more useful.
            ### In most cases, having "service check started" at the end of a "service check" line indicates that the last check ended abruptly, but I've seen at least one instance where two checks just randomly decided to run concurrently.
            $v_output_line =~ s/(Service Check Started$|Chkservd is currently suspended.*$)/...Service MIGHT have failed. Output from the log file is ambiguous. Check the log entries around timestamp \"$v_timestamp\" to confirm.\]/;
            print "$v_timestamp $v_output_line\n";
         }
      }
      $v_output_line = "";
      $b_process = 0;
   }
}

sub fn_disk_check {
### Separate out disk checks into multiple lines.
   $v_timestamp =~ s/^(\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]).*$/$1/;
   ### This cust off the status information, however when I know more of what variation we might see here, I'll probably want to keep this.
   $v_diskcheck_line =~ s/^\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\] Disk check \.* (.*) \.* \{status.*$/$2/;
   my @v_disks = split( /[[:blank:]]+\.+[[:blank:]]+/, $v_diskcheck_line );
   for my $v_disk (@v_disks) {
      print "$v_timestamp Disk check: $v_disk\n";
   }
}

sub fn_oom_check {
### Separate out information from OOM checks.
   my $v_line = $_[0];
   my $v_timestamp = $v_line;
   $v_timestamp =~ s/^(\[[0-9-]{10} [0-9:]{8}( [+-][0-9]{4})*\]).*$/$1/;
   my @v_ooms = split( /\.+OOM Event:/, $v_line );
   ### Remove the first line, it's just going to be the timestamp.
   shift( @v_ooms );
   ### Only go forward if there was anything to report.
   if ( $v_ooms[0] ) {
      $v_ooms[-1] = ( split( /\.+Skipped OOM/, $v_ooms[-1] ) )[0];
      my $v_notification = ( split( /\.+Sent OOM /, $v_ooms[-1] ) )[1];
      $v_ooms[-1] = ( split( /\.+Sent OOM/, $v_ooms[-1] ) )[0];
      for my $v_oom ( @v_ooms ) {
         my $v_oom_compare = $v_oom;
         ### Sometimes the same event will be recorded twice with the time stamp off by one second?
         $v_oom_compare =~ s/,(time=[0-9]*)[0-9]{2},/,$1,/;
         my $b_print_line = 1;
         ### Check previously printed lines; no use taking up space reprinting.
         for my $v_record ( @v_oom_records ) {
            if ( $v_oom_compare eq $v_record ) {
               $b_print_line = 0;
               last;
            }
         }
         if ( $b_print_line ) {
            print "$v_timestamp OOM Event: $v_oom\n";
            push( @v_oom_records, $v_oom_compare );
            ### remove lines after 20 entries.
            if ( $v_oom_records[20] ) {
               shift( @v_oom_records )
            }
         }
      }
      if ( $v_notification ) {
         print "$v_timestamp Sent OOM " . "$v_notification\n";
      }
   }
}

#======================#
#== Disk Change Mode ==#
#======================#

sub fn_disk_change {
   my $v_last_percent = "";
   while (<STDIN>) {
      ### From the lines we're given, find the percentage
      my $_line = $_;
      my $v_percent = $_line;
      $v_percent =~ s/^.*([0-9.]+%).*$/$1/;
      if ( $v_percent eq $_line ) {
         next;
      }
      ### Reduce the percentage down to one decimal point or less
      while ( $v_percent =~ m/\./ && $v_percent !~ m/\.[0-9]%/ ) {
         $v_percent =~ s/^([0-9.]+)[0-9]%$/$1%/;
      }
      if ( $v_percent ne $v_last_percent ) {
      ### If the current percentage is different than the last seen percentage...
         if ( $b_highlight ) {
            print "\e[32m" . $_line . "\e[0m";
         } else {
            print $_line;
         }
         $v_last_percent = $v_percent;
      } elsif ( $b_highlight ) {
         print $_line;
      }
   }
   exit 0;
}

#========================#
#== Helper Subroutines ==#
#========================#

sub fold_print {
### $_[0] is the message; $_[1] is the number of columns to use if columns can't be determined.
   my $v_columns;
   if( exists $ENV{PATH} && defined $ENV{PATH} ) {
      my @v_paths = split( m/:/, $ENV{PATH} );
      for ( @v_paths ) {
         if ( -f ( $_ . "/tput" ) && -x ( $_ . "/tput" ) ) {
            my $v_exe =  $_ . "/tput";
            $v_columns = `$v_exe cols`;
            chomp $v_columns;
            if ( $v_columns =~ m/^[0-9]+$/ ) {
               last;
            }
         }
      }
   }
   if ( $v_columns && $v_columns !~ m/^[0-9]+$/ ) {
      if ( $_[1] ) {
         $v_columns = $_[1];
      } else {
         return $_[0];
      }
   } else {
      $v_columns--;
   }

   my @v_message = split( m/\n/, ( $_[0] . "\n" . "last" ) );
   for my $_line ( @v_message ) {
      chomp( $_line );
      $_line =~ s/\t/     /g;
      $_line = $_line . "\n";
      next if length( $_line ) <= $v_columns;
      my $v_remaining = length( $_line ) - 1;
      my $v_complete = 0;
      my $v_spaces = "";
      for my $_character ( 0 .. ( $v_remaining - 1 ) ) {
         if ( substr( $_line, $_character, 1 ) =~ m/[ *-]/ ) {
            $v_spaces = $v_spaces . " ";
         } else {
            last;
         }
      }
      my $v_length_spaces = length( $v_spaces );
      while ( $v_remaining >= $v_columns ) {
         for my $_character ( reverse( ( $v_complete + $v_length_spaces ) .. ( $v_complete + $v_columns ) ) ) {
            if ( substr( $_line, $_character, 1 ) eq " "  ) {
               $_line = substr( $_line, 0, $_character ) . "\n" . $v_spaces . substr( $_line, ($_character + 1) );
               $v_remaining = ( length( $_line ) - 1 - $_character + 1 );
               $v_complete = ( $_character + 1 );
               last;
            }
            if ( $_character == ( $v_complete + $v_length_spaces ) ) {
               $v_remaining -= $v_columns;
               $v_complete += $v_columns;
            }
         }
      }
   }
   pop @v_message;
   $v_message[$#v_message] = substr( $v_message[$#v_message], 0, (length( $v_message[$#v_message] ) - 1 ) );
   return @v_message;
}

#=============================#
#== Information Subroutines ==#
#=============================#

sub fn_version {
print "Current Version: $v_VERSION\n";
my $v_message =  <<'EOF';

Version 2.2.0 () -
    - Added the "--disk-change" and "--highlight" flags

Version 2.1.0 (2017-03-05) -
    - Better handling on OOM events (Thanks ABurk).

Version 2.0.0 (2016-05-03) -
    - Entire script has been rewritten in Perl.
    - Lines from the chkservd.log file can be piped in to be processed.
    - No longer accepts arguments for filename and number of lines - piping in is more straight forward.

Version 1.0.2 (2016-03-27) -
    - Improved help and version output.
    - Changed all "grep" to "egrep" for a very marginal speed increase.
    - Modified variable names to fit the formatting I typically use

Version 1.0.1 (2015-07-18) -
    - Added better comments within the script.
    - Minor rearrangements to make the script more readable.

Version 1.0.0 (2015-01-28) -
    - Original version.

EOF
print fold_print($v_message);
exit 0;
}

sub fn_help {
my $v_message =  <<'EOF';

chkservd_parse.pl - a tool to parse the output of chkservd in a manner that makes it more human readable, as well as easier to grep.

USAGE:

Lines from /var/log/chkservd.log are piped into chkservd_parse.pl. Examples:

   tail -n [some number] /var/log/chkservd.log | ./chkservd_parse.pl
   grep -C10 "2016-04-04 08:33:56 -0400" /var/log/chkservd.log | ./chkservd_parse.pl

Note that chkservd_parse.pl relies on multiple lines in the chkservd.log file to tell it what and when data should be output. If you're going to grep for specific data, it's best to capture lines surrounding that data as well (with "grep -C", for example).

OTHER USAGE:

./chkservd_parse.pl --disk-change
    - Checks piped input lines for a percentage; only outputs lines where that percentage has changed (by a tenth of a percent or greater).
    - Useful when looking at disk usage and trying to find instances where it has changed.
    - Example:

   tail -n 40000 /var/log/chkservd.log | ./chkservd_parse.pl  | egrep "Disk check: / " | ./chkservd_parse.pl --disk-change

./chkservd_parse.pl --disk-change --highlight
    - As above, but outputs every line; changes the color of lines where disk usage has changed

./chkservd_parse.pl --version
./chkservd_parse.pl -v
   - Outputs version information.

./chkservd_parse.pl --help
./chkservd_parse.pl -h
   - Outputs this help information.

FEEDBACK:

Report any errors, unexpected behaviors, comments, or feedback to acwilliams@liquidweb.com

EOF
print fold_print($v_message);
exit 0;
}

#====================================#
#== Process Command Line Arguments ==#
#====================================#

if ( ! $ARGV[0] && -t STDIN ) {
   fn_help();
}

my $v_run_mode = "standard";
while ( defined $ARGV[0] ) {
   my $v_arg = shift( @ARGV );
   if ( $v_arg eq "--help" || $v_arg eq "-h" ) {
      fn_help();
   } elsif ( $v_arg eq "--version" || $v_arg eq "-v" ) {
      fn_version();
   } elsif ( $v_arg eq "--disk-change" ) {
      $v_run_mode = "disk change";
   } elsif ( $v_arg eq "--highlight" ) {
      $b_highlight = 1;
   } else {
      print "I don't understand argument \"$v_arg\".";
      exit 1
   }
}

if ( $v_run_mode eq "standard" ) {
   fn_standard();
} elsif ( $v_run_mode eq "disk change" ) {
   fn_disk_change();
}


