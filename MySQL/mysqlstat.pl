#!/bin/env perl

use strict;
use warnings;
#use diagnostics;
use Getopt::Long;
use Data::Dumper;

# set default options
my %opt = (
		"debug"                           => 0,
		"mem-display"                     => "auto",
		"datadir"                         => "none",
		"query-cache"                     => 0,
		"table-lock"                      => 1,
		"security"                        => 0,
		"status-all-engines"               => 0,
		"check-slow_queries"              => 1,
		"scale-innodb_buffer_pool_size"   => 1.4,
		"scale-key_buffer_size"           => 1.4,
		"scale-read_buffer_size"          => 1.4,
		"scale-read_rnd_buffer_size"      => 1.1,
		"scale-sort_buffer_size"          => 1.1,
		"scale-myisam_sort_buffer_size"   => 0.7,
		"scale-max_allowed_packet"        => 1.0,
		"scale-query_cache"               => 0.7,
		"scale-table_lock"                => 0.3,
		"scale-open_files"                => 0.4,
		"scale-slow_queries"              => 0.3
	);

# Gather the options from the command line
GetOptions(\%opt,
		'debug+',
		'mem-display=s',
		'datadir=s',
		'query-cache!',
		'table-lock!',
		'security!',
		'status-all-engines!',
		'check-slow_queries!',
		'scale-innodb_buffer_pool_size=f',
		'scale-key_buffer_size=f',
		'scale-read_buffer_size=f',
		"scale-read_rnd_buffer_size=f",
		"scale-sort_buffer_size=f",
		"scale-myisam_sort_buffer_size=f",
		"scale-max_allowed_packet=f",
		"scale-query_cache=f",
		"scale-table_lock=f",
		"scale-open_files=f",
		"scale-slow_queries=f"
	);

# my dirty dirty globals
my %mysql_stat = ();
my %mysql_var = ();
my %mysql_cnf = ();

sub usage {
	# Shown with --help option passed
	print "\n".
		"   mysqlstat.pl - a script to quickly see some information on MySQL as it's running\n".
		"   Internal bug reports and feature requests go to the author\n".
		"   ### This tool is for internal use only ###\n".
		"\n".
		"   General usage:\n".
		"     mysqlstat.pl\n".
		"\n".
		"   Commonly used flags:\n".
		"      --security           Looks for accounts without passwords and accounts with pre-MySQL 4.1 style passwords (recommended)\n".
		"      --status-all-engines Reports status information for all engines\n".
		"      --datadir files      Determines the size of the datadir by looking at files and displays some cache information\n".
		"      --datadir query      Same information as before, but by a slower, more resoursce intensive method\n".
		"      --query-cache        Display query-cache statistics\n".
		"      --help OR --usage    Print out this information\n".
		"\n".
		"   For more information please see the Readme file\n".
		"\n";
	exit;
}

# run given command and break two column output into key->value hash table
sub read_stats {
	# initialize the hash table to pass back.
	my %response = ();
	my @result = `$_[0]`;

	foreach my $line (@result) {
		$line =~ /^([a-zA-Z0-9_]+)\s+(.+)/;
		$response{$1} = $2;
	}
	return %response;
}

sub run_query {
	# declare a hash table that we'll use for the response
	# format is {column}{first value of row} = "value of cell"
	my %response = ();

	# pad the query out a bit and run it
	my $query = shift;
	$query = 'mysql -Be "'.$query.'"';
	my @result = `$query`;
	undef $query;
	# left with array @result

	# grab the first row - it's my column headings
	my $query_header = shift @result;
	my @query_columns = split(/\t/, $query_header);
	chomp(@query_columns);
	undef $query_header;		
	# left with array @query_columns

	foreach my $line (@result) {
		# go through each line of the result set
		my @line_cols = split(/\t/, $line);
		chomp(@line_cols);

		for(my $i = 1; $i < scalar @query_columns; $i++) {
			# go through each column of that line - skipping the first column
			# and assign that item to $response{column}{first row value}

			my $column = $query_columns[$i];
			my $row = $line_cols[0];
			my $value = $line_cols[$i];
			$response{$column}{$row} = $value;
			undef	$column;
			undef $row;
			undef $value;

			# $response{$query_columns[$i]}{$line_cols[0]} = $line_cols[$i];
		} 
	}
	return %response;
}

sub good{print "[\e[0;32mYAS\e[0m] ".$_[0]."\n";};
sub meh{print "[\e[0;34mUHH\e[0m] ".$_[0]."\n";};
sub bad{print "[\e[0;31mFAK\e[0m] ".$_[0]."\n";};

sub header{print "########## \e[0;32m".$_[0]."\e[0m ##########\n";};

sub hr_percent { return sprintf('%.3f', $_[0]);};


# print 4 values and a label in 5 columns
sub col4 {
	# valid calls to this function are:
	# col4 label repeat_value
	# col4 label color value1 value2 value3 value4
	my $color = "";
	my $reset = "\e[0m";
	if(! defined $_[5]) {
	# if 6 items were not passed, a color was not given so set to default color
		$color = "\e[0m";
	}	elsif($_[1] eq 'blue') {
		$color = "\e[1 ;34m";
	} elsif ($_[1] eq "purple") {
		$color = "\e[1;35m";
	} elsif ($_[1] eq "yellow") {
		$color = "\e[1;33m";
	} elsif ($_[1] eq "green") {
		$color = "\e[0;32m";
	} else {
		# if a bad color was given, go to normal
		$color = "\e[0m";
	}

	if(defined $_[5]) {
		# if there are at least 6 arguments print each one - arguments 0, 2, 3, 4, and 5 are things to print
		print sprintf('%28s',$_[0]).$reset." | ".$color.sprintf('%10s',$_[2]).$reset." | ".$color.sprintf('%10s',$_[3]).$reset." | ".$color.sprintf('%10s',$_[4]).$reset." | ".$color.sprintf('%10s',$_[5]).$reset."\n";
	} else {
		# if there is just two arguments, print the 2nd four times for the four columns
		print sprintf('%28s',$_[0])." | ".sprintf('%10s',$_[1])." | ".sprintf('%10s',$_[1])." | ".sprintf('%10s',$_[1])." | ".sprintf('%10s',$_[1])."\n";
	}
}

# read the my.cnf and populate a hash with the configured items
sub read_mycnf {
	open(my $cnf_file, "<", "$_[0]");
	my $current_section = 'mysqld';
	my %configured_options = ();
	while (<$cnf_file>) {
		my $line = $_;
		if ($line =~ /^\s*\[([a-zA-z]+)\]\s*$/ ) { # drunk regex - do not change
			# regex above evaulates to spaces[anything]spaces
			# print "bracket match for ".$1."\n";
			$current_section = $1;
		} elsif ($line =~ /^\s*([^\s\=\#]+)($|[\s\=]+(.*)$)/) { # drunk regex - do not change
			# regex evaulates to spaces(any word)(spacesand=(everything else))optional
			# print "conf val match for ".$1."\n";
			$configured_options{$current_section}{$1} = $3;
		}
	}
	close($cnf_file);
	return %configured_options;
}

sub hr_bytes {
	my $num = shift;
	if ($num >= (1024**3)) { #GB
		return sprintf("%.1f",($num/(1024**3)))."G";
	} elsif ($num >= (1024**2)) { #MB
		return sprintf("%.1f",($num/(1024**2)))."M";
	} elsif ($num >= 1024) { #KB
		return sprintf("%.1f",($num/1024))."K";
	} else {
		return $num."B";
	}
}

sub mem_usage {
	sub cheat4 {
		my $label = shift;
		my $color = shift;
		my $var_scale = shift;
		# called like cheat4 "color" "label" "mysql variable * scale"
		col4 ($label, $color,
			hr_bytes($var_scale ),
			hr_bytes($var_scale * $mysql_stat{'Value'}{'Threads_connected'}),
			hr_bytes($var_scale * $mysql_stat{'Value'}{'Max_used_connections'}),
			hr_bytes($var_scale * $mysql_var{'Value'}{'max_connections'})
		); 
	}

	# first some labels
	header "Memory Usage per connections";
	col4 "", "yellow", "base", "now", "peak", "limit";
	col4 "# of connections", "blue", "1", $mysql_stat{'Value'}{'Threads_connected'}, $mysql_stat{'Value'}{'Max_used_connections'}, $mysql_var{'Value'}{'max_connections'};

	if (($opt{'mem-display'} eq "full") || ($opt{'mem-display'} eq "auto")) {

		#innodb_buffer_pool_size and key_buffer_size are constant - don't care if reported as key_buffer or key_buffer_size
		if(defined $mysql_var{'Value'}{'innodb_buffer_pool_size'})
			{col4 "innodb_buffer_pool_size", hr_bytes($mysql_var{'Value'}{'innodb_buffer_pool_size'});};
		if(defined $mysql_var{'Value'}{'key_buffer_size'}) {col4 "key_buffer_size", hr_bytes($mysql_var{'Value'}{'key_buffer_size'});};
		if(defined $mysql_var{'Value'}{'key_buffer'}) {col4 "key_buffer", hr_bytes($mysql_var{'Value'}{'key_buffer'});};
		if(defined $mysql_var{'Value'}{'query_cache_size'}) {col4 "query_cache_size", hr_bytes($mysql_var{'Value'}{'query_cache_size'});};

		# if set, print out read_buffer_size assuming each thread is scaled to scaled-read_buffer_size
		# buffer allocated to each table for each thead for sequential reads
		if(exists $mysql_cnf{'mysqld'}{'read_buffer_size'} || $opt{'mem-display'} eq "full")
			{cheat4("read_buffer_size", "blue", $mysql_var{'Value'}{"read_buffer_size"} * $opt{'scale-read_buffer_size'});};	

		# buffer allocated for random reads - per table if the read is random
		if(exists $mysql_cnf{'mysqld'}{'read_rnd_buffer_size'} || $opt{'mem-display'} eq "full")
			{cheat4("read_rnd_buffer_size", "blue", $mysql_var{'Value'}{"read_rnd_buffer_size"} * $opt{'scale-read_rnd_buffer_size'});};	

		# same, but for sort_buffer_size
		# used during joins and sorts - in memory sorts will be handled in this buffer
		if(exists $mysql_cnf{'mysqld'}{'sort_buffer_size'} || $opt{'mem-display'} eq "full")
			{cheat4("sort_buffer_size", "blue", $mysql_var{'Value'}{"sort_buffer_size"} * $opt{'scale-sort_buffer_size'});};	

		if(exists $mysql_cnf{'mysqld'}{'myisam_sort_buffer_size'} || $opt{'mem-display'} eq "full")
			{cheat4("myisam_sort_buffer_size", "blue", $mysql_var{'Value'}{"myisam_sort_buffer_size"} * $opt{'scale-myisam_sort_buffer_size'});};	

		if(exists $mysql_cnf{'mysqld'}{'max_allowed_packet'} || $opt{'mem-display'} eq "full")
			{cheat4("max_allowed_packet", "blue", $mysql_var{'Value'}{"max_allowed_packet"} * $opt{'scale-max_allowed_packet'});};	
	}

	# we know for certain that we're going to print the memory summary usage
	my $constant_mem_summary = 0;
	$constant_mem_summary += $mysql_var{'Value'}{'innodb_buffer_pool_size'};
	$constant_mem_summary += $mysql_var{'Value'}{'query_cache_size'};
	if(defined $mysql_var{'Value'}{'key_buffer'}) {
		$constant_mem_summary += $mysql_var{'Value'}{'key_buffer'};
	}
	if(defined $mysql_var{'Value'}{'key_buffer_size'}) {
		$constant_mem_summary += $mysql_var{'Value'}{'key_buffer_size'};
	}

	my $scale_mem_summary = 0;
	if(defined $mysql_var{'Value'}{'read_buffer_size'}) {
		$scale_mem_summary += $mysql_var{'Value'}{'read_buffer_size'} * $opt{'scale-read_buffer_size'};
	}
	if(defined $mysql_var{'Value'}{'read_rnd_buffer_size'}) {
		$scale_mem_summary += $mysql_var{'Value'}{'read_rnd_buffer_size'} * $opt{'scale-read_rnd_buffer_size'};
	}
	if(defined $mysql_var{'Value'}{'sort_buffer_size'}) {
		$scale_mem_summary += $mysql_var{'Value'}{'sort_buffer_size'} * $opt{'scale-sort_buffer_size'};
	}
	if(defined $mysql_var{'Value'}{'myisam_sort_buffer_size'}) {
		$scale_mem_summary += $mysql_var{'Value'}{'myisam_sort_buffer_size'} * $opt{'scale-myisam_sort_buffer_size'};
	}
	if(defined $mysql_var{'Value'}{'max_allowed_packet'}) {
		$scale_mem_summary += $mysql_var{'Value'}{'max_allowed_packet'} * $opt{'scale-max_allowed_packet'};
	}

	col4 ("Total Memory Guess", "yellow",
		hr_bytes($constant_mem_summary + ($scale_mem_summary * 1 )),
		hr_bytes($constant_mem_summary + ($scale_mem_summary * $mysql_stat{'Value'}{'Threads_connected'})),
		hr_bytes($constant_mem_summary + ($scale_mem_summary * $mysql_stat{'Value'}{'Max_used_connections'})),
		hr_bytes($constant_mem_summary + ($scale_mem_summary * $mysql_var{'Value'}{'max_connections'}))
	);

	if($opt{'debug'} == 3) {
		print "constant_mem_summary ".$constant_mem_summary."\n";
		print "scale_mem_summary ".$scale_mem_summary."\n";
		print "threads_connected ".$mysql_stat{'Value'}{'Threads_connected'}."\n";
		print "Max_used_connections ".$mysql_stat{'Value'}{'Max_used_connections'}."\n";
		print "max_connections ".$mysql_var{'Value'}{'max_connections'}."\n";
	}
	print "\n";
}

sub total_all_files {
	my $refhash = shift;
	my %extension_total = %$refhash;
	my $path = shift;

	opendir (DIR, $path) or die "Unable to open $path: $!";

	my @files =
		map { $path. '/' .$_ } # find all things in this location
		grep { !/^\.{1,2}$/ } # eliminate . and .. files
		readdir (DIR);

	closedir(DIR);

	for (@files) {
		if (-d $_) {
			total_all_files($refhash, $_);
		} elsif (-l $_) {
			# skipping symlinks - not currently impleneted
		} elsif (-f $_) {

			my $current_file = $_;
			my $current_size = -s $current_file;
			$current_file =~ /^(.*(\.|\/))?([^\.]+)$/; # run some regex against $current_file
			my $current_extension = $3;

			if(exists $refhash->{$current_extension}){
				$refhash->{$current_extension} = $refhash->{$current_extension} + (-s $current_file);
			} else {
				$refhash->{$current_extension} = (-s $current_file);
			}
		}
	}
}

sub print_datadir_stats {
	# called with print_datadir_stats ($innodb_data_size, $innodb_index_size, $myisam_data_size, $myisam_index_size)
	my $innodb_data_size = shift;
	my $innodb_index_size = shift;
	my $myisam_data_size = shift;
	my $myisam_index_size = shift;

	my $innodb_buffer_pool_size = shift;
	my $key_buffer_size = shift;

	my $myisam_buffer_short_percent = hr_percent(($myisam_data_size + $myisam_index_size) / $key_buffer_size);
	my $innodb_buffer_short_percent = hr_percent(($innodb_data_size + $innodb_index_size) / $key_buffer_size);

	my $max_myisam_buffer_use = hr_percent(($mysql_stat{'Value'}{'Key_blocks_used'} * $mysql_var{'Value'}{'key_cache_block_size'})
									 / $key_buffer_size);
	my $max_innodb_buffer_use = hr_percent(($mysql_stat{'Value'}{'Key_blocks_used'} * $mysql_var{'Value'}{'key_cache_block_size'}) / $innodb_buffer_pool_size);

	if ($myisam_buffer_short_percent < $opt{'scale-key_buffer_size'}) {
		good ("MyISAM total space usage (tables & indexes) ".hr_bytes($myisam_data_size+$myisam_index_size));
		good ("MyISAM key_buffer_size is ".hr_bytes($key_buffer_size)." - ". $myisam_buffer_short_percent ."% of the engine usage")
	} else {
		bad ("MyISAM total space usage (tables & indexes) ".hr_bytes($myisam_data_size));
		bad ("MyISAM key_buffer_size is ".hr_bytes($key_buffer_size)." - ". $myisam_buffer_short_percent ."% of the engine usage")
	}

	meh ("MyISAM contains ".hr_bytes($myisam_data_size)." of data and ".hr_bytes($myisam_index_size)." of indexes");
	meh("key_buffer_size has been $max_myisam_buffer_use % full");

	print "\n";

	if ($innodb_buffer_short_percent < $opt{'scale-key_buffer_size'}) {
		good ("InnoDB total space usage (tables & indexes) ".hr_bytes($innodb_data_size+$innodb_index_size));
		good ("InnoDB innodb_buffer_pool_size is ".hr_bytes($innodb_buffer_pool_size)." - ". $innodb_buffer_short_percent ."% of the engine usage")
	} else {
		bad ("MyISAM total space usage (tables & indexes) ".hr_bytes($innodb_data_size));
		bad ("MyISAM innodb_buffer_pool_size is ".hr_bytes($innodb_buffer_pool_size)." - ". $innodb_buffer_short_percent ."% of the engine usage")
	}

	if($innodb_index_size == 0) {
		meh ("When using the short method, the usage difference between data and indexes is not available");
	} else {
		bad ("InnoDB contains ".hr_bytes($innodb_data_size)." of data and ".hr_bytes($innodb_index_size)." of indexes");
	}
	meh("innodb_buffer_pool_size has been $max_innodb_buffer_use % full");

}

sub inode_count_tablespace_size {
	my %extension_total = ();
	total_all_files(\%extension_total, $mysql_var{'Value'}{'datadir'});

	header("Detailed Engine Total by Files (fast)");

	if(exists $mysql_var{'Value'}{'key_buffer_size'} && exists $extension_total{'ibd'}) {
		print_datadir_stats ($extension_total{'ibdata1'}+$extension_total{'ibd'}, 0,	$extension_total{'MYD'}, $extension_total{'MYI'},
			$mysql_var{'Value'}{'innodb_buffer_pool_size'}, $mysql_var{'Value'}{'key_buffer_size'});
	} elsif(exists $mysql_var{'Value'}{'key_buffer'} && exists $extension_total{'ibd'}) {
		bad ("Because you are on an older version of MySQL, the MyISAM variable here is key_buffer");
		print_datadir_stats ($extension_total{'ibdata1'}+$extension_total{'ibd'}, 0, $extension_total{'MYD'}, $extension_total{'MYI'},
			$mysql_var{'Value'}{'innodb_buffer_pool_size'}, $mysql_var{'Value'}{'key_buffer'});
	} elsif(exists $mysql_var{'Value'}{'key_buffer_size'} && ! exists $extension_total{'ibd'}) {
		print_datadir_stats ($extension_total{'ibdata1'}, 0, $extension_total{'MYD'}, $extension_total{'MYI'},
			$mysql_var{'Value'}{'innodb_buffer_pool_size'}, $mysql_var{'Value'}{'key_buffer_size'});
	} elsif(exists $mysql_var{'Value'}{'key_buffer'} && ! exists $extension_total{'ibd'}) {
		bad ("Because you are on an older version of MySQL, the MyISAM variable here is key_buffer");
		print_datadir_stats ($extension_total{'ibdata1'}, 0, $extension_total{'MYD'}, $extension_total{'MYI'},
			$mysql_var{'Value'}{'innodb_buffer_pool_size'}, $mysql_var{'Value'}{'key_buffer_size'});
	} else {
		die("You hit an error");
	}
	print "\n";
}

sub query_count_tablespace_size {
	my $query = "SELECT engine, count(*) tables,
	                sum(table_rows) rows,
	                sum(data_length) data,
	                sum(index_length) idx
	              FROM information_schema.TABLES
	              GROUP BY engine;";
	my %table_stats = run_query($query);

	header("Detailed Engine Total by tablescan (slow)");

	if(exists $mysql_var{'Value'}{'key_buffer_size'}) {
		print_datadir_stats ($table_stats{'data'}{'InnoDB'}, $table_stats{'idx'}{'InnoDB'},	$table_stats{'data'}{'MyISAM'},
			$table_stats{'idx'}{'MyISAM'}, $mysql_var{'Value'}{'innodb_buffer_pool_size'}, $mysql_var{'Value'}{'key_buffer_size'});
	} elsif(exists $mysql_var{'Value'}{'key_buffer'}) {
		bad ("Because you are on an older version of MySQL, the MyISAM variable here is key_buffer");
		print_datadir_stats ($table_stats{'data'}{'InnoDB'}, $table_stats{'idx'}{'InnoDB'}, $table_stats{'data'}{'MyISAM'},
			$table_stats{'idx'}{'MyISAM'}, $mysql_var{'Value'}{'innodb_buffer_pool_size'}, $mysql_var{'Value'}{'key_buffer'});
	} else {
		die("You hit an error");
	}
	print "\n";
}

sub query_cache {
	header("Query Cache Statistics");

	if ($mysql_var{'Value'}{'query_cache_size'} == 0 || $mysql_var{'Value'}{'query_cache_type'} eq "OFF") {
		#query cache is disabled
		bad("The MySQL Query Cache is disabled.");
	} else{
		# mysql documentation says that the Com_select is supposed to carry the total count of queries - less those served from cache
		# my own checking looks like Com_select also does not include queries exempt from the query_cache
		#my $total_select_queries = $mysql_stat{'Value'}{'Com_select'} + $mysql_stat{'Value'}{'Qcache_hits'} + $mysql_stat{'Value'}{'Qcache_not_cached'};
		my $total_select_queries = $mysql_stat{'Value'}{'Questions'};
		my $qcache_hit_percent = hr_percent($mysql_stat{'Value'}{'Qcache_hits'} / $total_select_queries);
		my $qcache_untouchable_percent = hr_percent($mysql_stat{'Value'}{'Qcache_not_cached'}/$total_select_queries);

		if ($opt{'debug'} == 4) {
			print "com select ".$mysql_stat{'Value'}{'Com_select'}."\n";
			print "queries served from cache ".$mysql_stat{'Value'}{'Qcache_hits'}."\n";
			print "queries put into the cache ".$mysql_stat{'Value'}{'Qcache_inserts'}."\n";
			print "queries that cannot be cached ".$mysql_stat{'Value'}{'Qcache_not_cached'}."\n";
			print "total select queries ". $total_select_queries."\n";
			print "query cache hit percent ".$qcache_hit_percent."\n";
			print "query cache untouchable percent ".$qcache_untouchable_percent."\n";
		}

		if ($qcache_hit_percent > $opt{'scale-query_cache'}) {
			good("The MySQL Query Cache hit rate is ".$mysql_stat{'Value'}{'Qcache_hits'}."/".$total_select_queries." - $qcache_hit_percent %");
		} else {
			bad("The MySQL Query Cache hit rate is ".$mysql_stat{'Value'}{'Qcache_hits'}."/".$total_select_queries." - $qcache_hit_percent %");
		}
		if ($qcache_untouchable_percent < (1 - $qcache_hit_percent) / 2) {
			meh("You cannot touch $qcache_untouchable_percent % of these queries or ".$mysql_stat{'Value'}{'Qcache_not_cached'}." queries");
		} else {
			bad("You cannot touch $qcache_untouchable_percent % of these queries or ".$mysql_stat{'Value'}{'Qcache_not_cached'}." queries");
		} 
	}
	print "\n";
}

sub table_lock {
	my $table_lock_requests = $mysql_stat{'Value'}{'Table_locks_immediate'} + $mysql_stat{'Value'}{'Table_locks_waited'};
	my $table_lock_wait_percent = hr_percent($mysql_stat{'Value'}{'Table_locks_waited'} / $table_lock_requests);

	if ($table_lock_wait_percent > $opt{'scale-table_lock'}){
		bad("SELECT queries are waiting on a lock $table_lock_wait_percent % of the time - there have been $table_lock_requests requests");
	} elsif	($table_lock_requests < 1){
		meh("There have no been table lock requests");
	} else {
		good("SELECT queries are waiting on a lock $table_lock_wait_percent % of the time - there have been $table_lock_requests requests");
	}

	print "\n";
}

sub security_check {
	header("Security Concerns");
	my $no_issues = 1;
	my %bad_users = run_query("SELECT CONCAT(Host, ' @ ', User) as user , Password FROM mysql.user WHERE Password REGEXP '[0-9a-f]{16}' OR Password = '';");
	while ((my $user, my $passhash) = each %{$bad_users{'Password'}}) {
		if($passhash eq '') {
			$no_issues = 0;
			bad("blank password discovered - $user ");
		} elsif ($passhash =~ /^[0-9a-fA-F]{16}$/ ) {
			$no_issues = 0;
			bad("old_password discovered - $user")
		}
	}
	if($no_issues == 1) {
		good("No Security issues found")	
	}
	print "\n";
}

sub engine_status {
	sub check_engine {
		my $engine = shift;
		my $status = shift;
		if ($status eq "YES" || $status eq "DEFAULT") {
			return " \e[0;32m+".$engine."\e[0m";
		} else {
			return " \e[0;31m-".$engine."\e[0m";
		}
	}

	my %engine_status = run_query("show engines;");
	my $engine_report_line = "";
	
	if($opt{'status-all-engines'} == 1) {
		while ((my $engine, my $status) = each %{$engine_status{'Support'}}) {
			$engine_report_line .= check_engine($engine, $status);
		}
	} else {
		$engine_report_line .= check_engine('InnoDB', $engine_status{'Support'}{'InnoDB'});
		$engine_report_line .= check_engine('MyISAM', $engine_status{'Support'}{'MyISAM'});
		$engine_report_line .= check_engine('MEMORY', $engine_status{'Support'}{'MEMORY'});
		$engine_report_line .= check_engine('BLACKHOLE', $engine_status{'Support'}{'BLACKHOLE'});
		$engine_report_line .= check_engine('ARCHIVE', $engine_status{'Support'}{'ARCHIVE'});
	}

	if(($engine_status{'Support'}{'InnoDB'} eq "YES" || $engine_status{'Support'}{'InnoDB'} eq "DEFAULT") &&
			($engine_status{'Support'}{'MyISAM'} eq "YES" || $engine_status{'Support'}{'MyISAM'} eq "DEFAULT") &&
			($engine_status{'Support'}{'MEMORY'} eq "YES" || $engine_status{'Support'}{'MEMORY'} eq "DEFAULT")) {
		good("Engines:".$engine_report_line);
	} else{
		bad("Engines:".$engine_report_line);
	}
}

sub check_open_files{
	if($mysql_stat{'Value'}{'Open_files'} / $mysql_var{'Value'}{'open_files_limit'} < $opt{'scale-open_files'}) {
		good("There are currently ".$mysql_stat{'Value'}{'Open_files'}." files open - the limit is ".$mysql_var{'Value'}{'open_files_limit'});
	} else {
		bad("There are currently ".$mysql_stat{'Value'}{'Open_files'}." files open - the limit is ".$mysql_var{'Value'}{'open_files_limit'});
	}
}

sub check_slow_queries {
	my $slow_query_percent = hr_percent($mysql_stat{'Value'}{'Slow_queries'} / $mysql_stat{'Value'}{'Questions'});

	my $slow_query_time = "";
	if(exists $mysql_var{'Value'}{'long_query_time'}) {
		$slow_query_time = $mysql_var{'Value'}{'long_query_time'};
	}
	if ($slow_query_percent < $opt{'scale-slow_queries'}) {
		good($slow_query_percent." % of your queries are slow by the threshold ".$slow_query_time." seconds\n");
		good("This is ".$mysql_stat{'Value'}{'Slow_queries'}." queries out of a total of ".$mysql_stat{'Value'}{'Questions'}."\n");
	} else {
		bad($slow_query_percent." % of your queries are slow by the threshold ".$slow_query_time." seconds\n");
		bad("This is ".$mysql_stat{'Value'}{'Slow_queries'}." queries out of a total of ".$mysql_stat{'Value'}{'Questions'}."\n");
	}
}

####### main section #######

if ($opt{'help'} == 1 || $opt{'usage'} == 1) {usage();};

if (exists $ARGV[0]) {usage();};

%mysql_var = run_query("show variables;");
%mysql_stat = run_query("show global status;");
%mysql_cnf = read_mycnf("/etc/my.cnf");

# print the headers if we're printing memory output
print "\nInformation for ".$mysql_var{"Value"}{"hostname"}." running MySQL Version ".$mysql_var{"Value"}{"version"}."\n";
engine_status();
check_open_files();

if($opt{'table-lock'} == 1) {table_lock();};

if($opt{'check-slow_queries'} == 1) {check_slow_queries();};

print "\n";

if($opt{'mem-display'} eq 'auto' || $opt{'mem-display'} eq 'full' || $opt{'mem-display'} eq 'summary') {
	mem_usage();
}

if($opt{'datadir'} eq 'files' ) {inode_count_tablespace_size;};

if($opt{'datadir'} eq 'query' ) {query_count_tablespace_size;};

if($opt{'query-cache'} == 1) {query_cache();};

if($opt{'security'} == 1) {security_check();};
