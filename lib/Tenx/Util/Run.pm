package Tenx::Util::Run;

use strict;
use warnings 'FATAL';

use Tenx::Util::Run::Log;

sub location { $_[0]->{location} }

sub new {
    my ($class, $location) = @_;
    bless { location => $location }, $class;
}

sub log_file {
    $_[0]->location->file('_log');
}

sub log {
    Tenx::Util::Run::Log->create(log_file => $_[0]->log_file);
}

sub outs_directory {
    $_[0]->location->subdir('outs');
}

sub summary_csv {
    $_[0]->outs_directory->file('summary.csv');
}

1;
