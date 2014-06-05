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
	
	# Can only stop if they already started before
	my %last_entry = get_last_wal_entry;
	die "Can't quit what you didn't start\n"
		unless exists $last_entry{wal_start};
	
	# Remove the note indicating the wal-start from the entry.
	my $notes = join '', grep { $_ !~ /^wal-start=/ }
		`git notes show $last_entry{sha}`;
	
	# Set up the revised notes
	system(qw(git notes add -f -m), $notes, $last_entry{sha});
}

1;
