# ABSTRACT: Start a writing session
use strict;
use warnings;

############################################################################
              package Git::Command::WriteALot::Command::start;
############################################################################

use Git::Command::WriteALot -command;
use Git::Command::WriteALot::Utils;

sub execute {
	my ($self, $opt, $args) = @_;
	
	# Check that the current working status is clean
	die "Can only start with a clean repository\n" if is_dirty;
	
	# Make sure that they haven't left a dangling writing session
	my %last_entry = get_last_wal_entry;
	die "Already started at " . localtime($last_entry{start_time})
		. " (see $last_entry{sha})\n" if exists $last_entry{start_time};
	
	# Add a note to the current commit indicating our start time. Store the
	# gmtime to keep things simple.
	system(qw(git notes append -m), "wal-start=" . time);
	
	# Add a note if there was a goal indicated
	system(qw(git notes append -m), "wal-goal=$opt->{goal}")
		if exists $opt->{goal};
}

1;
