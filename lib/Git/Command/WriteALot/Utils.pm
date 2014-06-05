use strict;
use warnings;

############################################################################
                 package Git::Command::WriteALot::Utils;
############################################################################

use Exporter 'import';
our @EXPORT = qw(is_dirty get_last_wal_entry get_wal_interval_iterator
	describe_interval);

sub is_dirty {
	# Get the git status of the current working directory
	return !!`git diff --shortstat`;
}

# Build an iterator via an anonymous function and a closure.
sub get_wal_entry_iterator {
	# Open the file handle that we'll read from
	open my $in_fh, '-|', qw(git log --grep=wal-st),
		'--pretty=format:COMMIT %H%nTIME %ct%n%N';
	# The first 'next' sha is taken from the first line
	my $next_sha = <$in_fh>;
	$next_sha =~ s/COMMIT (.*)\s*/$1/;
	return sub {
		return unless $next_sha;
		my %commit_info = (sha => $next_sha);
		LINE: while (my $line = <$in_fh>) {
			if ($line =~ /^COMMIT (.*)/) {
				$next_sha = $1;
				return %commit_info;
			}
			elsif ($line =~ /^TIME (\d+)/) {
				$commit_info{commit_time} = $1;
			}
			elsif ($line =~ /^wal-start=(\d+)/) {
				$commit_info{start_time} = $1;
			}
			elsif ($line =~ /^wal-goal=(.*)/) {
				$commit_info{start_goal} = $1;
			}
			elsif ($line =~ /^wal-stop/) {
				$commit_info{stop_time} = $commit_info{commit_time};
			}
		}
	};
}

# Call the entry iterator just once
sub get_last_wal_entry { wal_entry_iterator->() }

sub get_wal_interval_iterator {
	# Iterate through all of the log entries
	my $iterator = get_wal_entry_iterator;
	
	# Hold on to stop time and stop sha for future iterations through the
	# loop
	my %data_from_prev;
	return sub {
		my %entry = $iterator->();
		my %interval;
		while(keys %entry) {
			if (exists $data_from_prev{stop_time}) {
				# If the previous had a stop time, we expect to find a start time.
				if (not exists $entry{start_time}) {
					warn "Found two stopping commits without a corresponding start in between:\n"
						. "\t$entry{stop_sha}\n"
						. "\t$data_from_prev{stop_sha}\n";
				}
				else {
					%interval = (
						start_time => $entry{start_time},
						start_sha  => $entry{sha},
						%data_from_prev
					);
					$interval{goal} = $entry{goal} if exists $entry{goal};
				}
			}
			
			# If the current entry has a stop time, store that for the next
			# round through the loop
			if (exists $entry{stop_time}) {
				%data_from_prev = (
					stop_time => $entry{time},
					stop_sha  => $entry{stop_sha},
				);
			}
			
			return %interval if keys %interval;
		}
		continue { %entry = get_wal_entry_iterator->() }
	};
}

sub process_interval {
	my %interval = @_;
	
	# Compute the duration
	my $duration = $interval{duration}
		= $interval{stop_time} - $interval{start_time};
	$interval{duration_mins} = $duration / 60;
	$interval{s} = $duration % 60;
	$duration -= $interval{sec};
	$interval{m} = $duration % 60;
	$interval{h}= $duration - $interval{min};
	
	my ($additions, $subtractions) = (0, 0);
	open my $in_fh, '-|', qw(git diff --word-diff), $interval{start_sha},
		$interval{stop_sha};
	while(my $line = <$in_fh>) {
		# calculate the subtractions
		while ($line =~ s/\[-\s*(.*?)\s*-\]//) {
			my $removed = $1;
			$subtractions += split /\s+/, $removed;
		}
		while ($line =~ s/\{\+\s*(.*?)\s*\+\}//) {
			my $added = $1;
			$additions += split /\s+/, $added;
		}
	}
	$interval{added} = $additions;
	$interval{removed} = $subtractions;
	return %interval;
}

sub describe_interval {
	my %interval = process_interval(@_);
	print localtime($interval{start_time}), " --> ",
		localtime($interval{stop_time});
	print " # $interval{goal}" if exists $interval{goal};
	print "\n";
	print "  Words added  : $interval{added}\n" if $interval{added};
	print "  Words removed: $interval{removed\n" if $interval{removed};
	print "  Duration     : $interval{hour}:$interval{min}:$interval{sec}\n";
	print "  Avg add rate : ", $interval{added} / $interval{duration_mins},
		"\n" if $interval{added};
	print "  Avg rem rate : ", $interval{removed} / $interval{duration_mins},
		"\n" if $interval{removed};
}
