# ABSTRACT: Discard current writing session
use strict;
use warnings;

############################################################################
              package Git::Command::WriteALot::Command::quit;
############################################################################

use Git::Command::WriteALot -command;
use Git::Command::WriteALot::Utils;

sub execute {
	my ($self, $opt, $args) = @_;
	
	# Check that the current working status is clean
	die "Can only quit with a clean repository\n" if is_dirty;
	
	# Can only stop if they already started before
	my %last_entry = get_last_wal_entry;
	die "Can't quit what you didn't start\n"
		unless exists $last_entry{start_time};
	
	# Can only quit if there have been no commits since the wal-start
	chomp(my $head = `git rev-parse HEAD`);
	die "Can only quit if you haven't committed any changes\n"
		if $head ne $last_entry{sha};
	
	# Remove the last commit
	system(qw(git reset --hard HEAD~1));
}

1;
