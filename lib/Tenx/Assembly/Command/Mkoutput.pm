package Tenx::Assembly::Command::Mkoutput;

use strict;
use warnings 'FATAL';

class Tenx::Assembly::Command::Mkoutput {
    is => 'Command::V2',
    has_input => {
        assembly => {
            is => 'Tenx::Assembly',
            doc => 'The assembly to run mkoutput on.',
        },
        styles => {
            is => 'Text',
            is_many => 1,
            valid_values => [qw/ raw megabubbles pseudohap2 /],
            default_value => 'raw,megabubbles,pseudohap2',
            doc => 'The style of mkutput to run.',
        },
    },
};

sub shortcut {
    die "shortcut is not implemented"
}

sub execute {
    my ($self) = @_;

    #mkdir $self->assembly->mkoutput_path;

    for my $style ( $self->styles ) {
        $self->status_message("Style: $style");
    }

    1;
}

1;
