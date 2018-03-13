package Tenx::Util::Loader;

use strict;
use warnings 'FATAL';

use File::Slurp 'slurp';

sub location { $_[0]->{location} }
sub lines { $_[0]->{lines} }

sub new {
    my ($class, $location) = @_;
    die "No location given to loader!" if not $location;

	my $lines;
	if ( -s "$location" ) {
		$lines = _load_file("$location");
	}
	else {
		die "Do not know how to load '$location'";
	}

    my %self = (
        location => $location,
		lines => $lines,
    );
	bless \%self, $class;
}

sub _load_file {
	[ slurp("$_[0]") ];
}

1;
