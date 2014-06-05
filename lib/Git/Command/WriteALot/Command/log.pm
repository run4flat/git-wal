use strict;
use warnings;

############################################################################
              package Git::Command::WriteALot::Command::log;
############################################################################

use Git::Command::WriteALot -command;
use Git::Command::WriteALot::Utils;

sub execute {
	my ($self, $opt, $args) = @_;
	
	my $iterator = get_wal_interval_iterator;
	
	my %interval = $iterator->();
	while(keys %interval) {
		describe_interval(%interval);
	}
	continue { %interval = $iterator->() }
}

1;
