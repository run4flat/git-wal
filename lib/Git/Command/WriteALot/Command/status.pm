# ABSTRACT: Get information about the current writing session
use strict;
use warnings;

############################################################################
              package Git::Command::WriteALot::Command::status;
############################################################################

use Git::Command::WriteALot -command;
use Git::Command::WriteALot::Utils;

sub execute {
	my ($self, $opt, $args) = @_;
	
	# See if they're in a writing session
	my %last_entry = get_last_wal_entry;
	if (not exists $last_entry{start_time}) {
		print "Not tracking a writing session\n";
		return;
	}
	# Convert this into an interval
	$last_entry{stop_time} = time;
	$last_entry{start_sha} = $last_entry{sha};
	describe_interval(%last_entry);
}

1;
