# ABSTRACT: Summarizes all writing sessions for this project
use strict;
use warnings;

############################################################################
            package Git::Command::WriteALot::Command::summary;
############################################################################

use Git::Command::WriteALot -command;
use Git::Command::WriteALot::Utils;

sub execute {
	my ($self, $opt, $args) = @_;
	
	my $iterator = get_wal_interval_iterator;
	
	my ($time_sum, $added_sum, $removed_sum) = (0, 0, 0);
	
	my %interval = $iterator->();
	while(keys %interval) {
		$time_sum += $interval{stop_time} - $interval{start_time};
		my %details = process_interval(%interval);
		$added_sum += $details{added};
		$removed_sum += $details{removed};
	}
	continue { %interval = $iterator->() }
	
	my $total_min = int($time_sum / 60);
	my $m = $total_min % 60;
	my $h = int($total_min / 60);
	print "Total time: ", $h ? "$h hours and " : "", "$m minutes\n";
	print "Total words added: $added_sum\n";
	print "Total words removed: $removed_sum\n";
}

1;
