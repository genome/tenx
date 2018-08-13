package Pacbio::Command::Assembly::BaxToBam::GenerateCommands;

use strict;
use warnings 'FATAL';

use IO::File;
use Pacbio::Run;
use Path::Class;

class Pacbio::Command::Assembly::BaxToBam::GenerateCommands {
    is => 'Command::V2',
    has_input => {
        bam_to_bax_command => {
            is => 'Text',
            doc => 'Command to fill in with BAX files and logging files. BAX files will be appended to the command. Use %LOG for the log file base name for each cell.  Example: bsub -o /my-logging-dir/%LOG bam2bax',
        },
        run_directories => {
            is => 'Text',
            is_many => 1,
            doc => 'Pacbio run directories',
        },
    },
    has_optional_input => {
        bam_output_directory => {
            is => 'Text',
            doc => 'Give the bam output directory to check if the bam already exists. If so, the bax2bam command for that cell will not be printed.',
        },
    },
    has_optional_output => {
        commands_file => {
            is => 'Text',
            default_value => '-',
            doc => 'Output file to print commands. Defaults to STDOUT.',
        },
    },
    has_optional_transient => {
        _bam_output_directory => { is => 'Path::Class::Dir', },
        _runs => { is => 'ARRAY', },
        _commands_fh => { is => 'IO::Handle', },
    },
    doc => 'insert missing primary contigs from haplotigs',
};

sub __init__ {
    my ($self) = @_;

    my @runs;
    for my $directory ( $self->run_directories ) {
        push @runs, Pacbio::Run->new(
            directory => Path::Class::dir($directory),
            machine_type => 'rsii',
        );
    }
    $self->_runs(\@runs);

    my $commands_file = $self->commands_file;
    if ( $commands_file and $commands_file ne '-' and -s $commands_file ) {
        $self->fatal_message("Output commands file exists: $commands_file. Please change detination, or remove it.");
    }

    $self->_commands_fh(
        ( $commands_file eq '-' )
        ? 'STDOUT'
        : IO::File->new($commands_file, 'r')
    );

    my $bam_output_directory = $self->bam_output_directory;
    if ( $bam_output_directory ) {
        $self->fatal_message('Given bam output directory, but it does not exist!') if not -d $bam_output_directory;
        $self->_bam_output_directory( Path::Class::dir($bam_output_directory) );
    }

}

sub execute {
    my ($self) = @_;

    $self->__init__;
    for my $run ( @{$self->_runs} ) {
        my $analyses = $run->analyses;
        for my $analysis ( @$analyses ) {
            my $bam = $self->_bam_output_for_analysis($analysis);
            next if $bam and -s $bam;
            my $cmd = $self->_bax_to_bam_command_for_analysis($analysis);
            $self->_commands_fh->print("$cmd\n");
        }
    }

    1;
}

sub _bam_output_for_analysis {
    my ($self, $analysis) = @_;
    return if not $self->bam_output_directory;
    # m151026_060206_00116_c100928752550000001823208204291687_s1_p0.subreads.bam
    # m151026_060206_00116_c100928752550000001823208204291687_s1_p0.bax.h5
    my @bax_files = map { $_->stringify } grep { "$_" =~ /\.bax\.h5$/ } @{$analysis->analysis_files};
    my @bax_basenames = List::Util::uniq( 
        map { my $bn = $_->basename; my ($t) = split(/\./, $bn, 2); $t; } grep { "$_" =~ /\.bax\.h5$/ } @{$analysis->analysis_files}
    );
    $self->fatal_message('Expected one BAX file basename: %s', join(' ', @bax_basenames)) if @bax_basenames != 1;
    $self->_bam_output_directory->file( join('.', $bax_basenames[0], 'subreads', 'bam') );
}

sub _bax_to_bam_command_for_analysis {
    my ($self, $analysis) = @_;

    my @bax_files = map { $_->stringify } grep { "$_" =~ /\.bax\.h5$/ } @{$analysis->analysis_files};
    $self->fatal_message('Incorrect number (%d) of BAX files for run analysis: %s', scalar(@bax_files), $analysis->alias) if not @bax_files or @bax_files != 3;

    # bsub -o /dir/%LOG bax2bam -o %OUT_BAM BAX_FILES
    my $cmd = $self->bam_to_bax_command;

    my $log_rex = qr/%LOG/;
    if ( $cmd =~ /$log_rex/ ) {
        my $log = join('.', $analysis->alias, 'out');
        $cmd =~ s/$log_rex/$log/;
    }

    join(' ', $cmd, join(' ', @bax_files));
}

1;
