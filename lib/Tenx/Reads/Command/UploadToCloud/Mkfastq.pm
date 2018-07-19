package Tenx::Reads::Command::UploadToCloud::Mkfastq;

use strict;
use warnings 'FATAL';

use Path::Class;
use List::MoreUtils;

class Tenx::Reads::Command::UploadToCloud::Mkfastq {
    is => 'Tenx::Reads::Command::UploadToCloud::Base',
    has_optional_input => {
        white_list => {
            is => 'Text',
            is_many => 1,
            doc => 'Only upload the samples in this list.',
        },
    },
    doc => 'upload fastqs from mkfastq directory to GCP object store',
};
__PACKAGE__->__meta__->property_meta_for_name('directory')->doc('Mkfastq output directory. Must include outs subdir with input samplesheet.');

sub execute {
    my $self = shift; 
    $self->status_message('Upload mkfastq directory to GCP object store...');

    my $samplesheet = Tenx::Reads::MkfastqRun->create( $self->directory );
    my @sample_names = $samplesheet->sample_names;
    $self->fatal_message("Failed to find samples in %s", $self->directory) if not @sample_names;

    my @white_list = $self->white_list;
    for my $sample_name ( $samplesheet->sample_names ) {
        next if @white_list and List::MoreUtils::any { $sample_name eq $_ } @white_list;
        my $sample_directory = $samplesheet->fastq_directory_for_sample_name($sample_name);
        $self->run_command($sample_directory);
    }

    $self->status_message('Done.');
    1;
}

1;
