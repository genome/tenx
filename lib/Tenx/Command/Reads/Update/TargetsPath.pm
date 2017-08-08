package Tenx::Command::Reads::Update::TargetsPath;

use strict;
use warnings;

use Path::Class;
use Util::Tablizer;

class Tenx::Command::Reads::Update::TargetsPath { 
    is => 'Command::V2',
    has_input => {
        reads => {
            is => 'Tenx::Reads',
            is_many => 1,
            shell_args_position => 1,
            doc => 'Reads to update.',
        },
    },
    has_optional_input => {
        value => {
            is => 'String',
            doc => 'Targets path to set on the given reads.',
        },
    },
    has_optional => {
        old_values => { is => 'ARRAY', default_value => [], },
    },
    doc => 'update the targets path of reads',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;
    $self->_before_update;
    for my $reads ( $self->reads ) {
        $self->_update_object($reads);
    }
    $self->_after_update;
}

sub _before_update {
    my $self = shift;
    $self->status_message('Update TenX Reads...');
    my $val = dir( $self->value )->absolute->stringify;
    $self->fatal_message('Directory does not exist! %s', $val) if !-d $val;
    $self->value($val);
}

sub _update_object {
    my ($self, $object) = @_;
    push @{$self->old_values}, $object->targets_path // 'NULL';
    $object->targets_path($self->value);
}

sub _after_update {
    my $self = shift;

    my @rows = (
        [qw/ ID SAMPLE_NAME TARGETS OLD /],
        [qw/ -- ----------- ------- --- /],
    );

    my $old_values = $self->old_values;
    my $i = 0;
    for my $reads ( $self->reads ) {
        push @rows, [ map({ $reads->$_ } (qw/ id sample_name targets_path /)), $old_values->[$i] ];
        $i++;
    }

    print Util::Tablizer->format(\@rows);
}

1;
