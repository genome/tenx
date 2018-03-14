package Tenx::Util::Loader;

use strict;
use warnings 'FATAL';

use File::Temp;
use File::Slurp 'slurp';
use IO::String;

sub location { $_[0]->{location} }
sub lines { $_[0]->{lines} }
sub io_handle { IO::String->new( join('', @{$_[0]->lines}) ) }

sub new {
    my ($class, $location) = @_;
    die "No location given to loader!" if not $location;

	my $lines;
	if ( -s "$location" ) {
		$lines = _load_file($location);
	}
	else {
		die "Location to load does not exist, or we know how to load '$location'";
	}

    my %self = (
        location => "$location",
		lines => $lines,
    );
	bless \%self, $class;
}

sub _load_file {
	[ slurp("$_[0]") ];
}

1;
