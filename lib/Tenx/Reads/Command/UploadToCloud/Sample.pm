package Tenx::Reads::Command::UploadToCloud::Sample;

use strict;
use warnings 'FATAL';

use Path::Class;

class Tenx::Reads::Command::UploadToCloud::Sample {
    is => 'Tenx::Reads::Command::UploadToCloud::Base',
    has_optional_input => {
        sample_name => {
            is => 'Text',
            doc => 'Sample name. If not given, the base name of the directory will be used.',
        },
    },
    doc => 'upload sample fastqs to GCP object store',
};
__PACKAGE__->__meta__->property_meta_for_name('directory')->doc('Mkfastq output directory. Must include outs subdir with input samplesheet.');

sub execute {
    my ($self) = @_;
    $self->status_message('Upload fastqs to GCP object store...');

    $self->fatal_message('Directory does not exist: %s', $self->directory) if not -d $self->directory;
    $self->status_message('Directory: %s', $self->directory);

    $self->_resolve_sample_name;
    $self->status_message('Sample name: %s', $self->sample_name);

    $self->run_command($self->directory);

    $self->status_message('Done.');
    1;
}

sub _resolve_sample_name {
    my ($self) = @_;
    return if $self->sample_name;
    $self->sample_name( dir($self->directory)->basename );
    $self->fatal_message('Could not get sample name from directory: %s', $self->directory) if not $self->sample_name;
}

1;
