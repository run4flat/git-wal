# ABSTRACT: Mark current writing session concluded with the latest commit
use strict;
use warnings;

############################################################################
              package Git::Command::WriteALot::Command::stop;
############################################################################

use Git::Command::WriteALot -command;
use Git::Command::WriteALot::Utils;

sub execute {
	my ($self, $opt, $args) = @_;
	
	# Check that the current working status is clean
	die "Can only stop with a clean repository\n" if is_dirty;
	
	# Can only stop if they already started before
	my %last_entry = get_last_wal_entry;
	die "Can't stop what you didn't start\n"
		unless exists $last_entry{start_time};
	chomp(my $head = `git rev-parse HEAD`);
	die "Can't stop on the same commit where you started\n"
		if $head eq $last_entry{sha};
	
	# Add a note to the current commit indicating the the writing stopped at
	# this commit
	system(qw(git notes append -m), "wal-stop");
}

1;
