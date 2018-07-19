package Tenx::Reads::Command::UploadToCloud::Base;

use strict;
use warnings 'FATAL';

use IPC::Open3;
use Symbol 'gensym';

class Tenx::Reads::Command::UploadToCloud::Base {
    is => 'Command::V2',
    is_abstract => 1,
    has_input => {
        directory => {
            is => 'Text',
            shell_args_position => 1,
        },
        cloud_url => {
            is => 'Text',
            shell_args_position => 2,
            doc => 'Cloud URL to put reads.',
        },
    },
    has_optional_input => {
        dry_run => {
            is => 'Boolean',
            doc => 'Do not run commands, just print to STDOUT.',
        },
    },
    doc => 'upload fastqs to the cloud',
};

sub help_detail { $_[0]->__meta__->doc }

sub get_upload_command {
    my ($self, $ldir) = @_; 
    [ 'gsutil', '-m', 'rsync', '-R', $ldir, $self->cloud_url ];
}

sub run_command {
    my ($self, $ldir) = @_;

    my $cmd = $self->get_upload_command($ldir);
    if ( $self->dry_run ) {
        $self->status_message( join(' ', @$cmd) );
        return;
    }
    $self->status_message( join(' ', 'RUNNING', @$cmd) );
    my $rv = system(@$cmd);
    if ( $rv != 0 ) {
        #$self->fatal_message("Failed to run command!");
    }
    return 1;

    my ($wtr, $rdr);
    my $err = gensym;
    my $pid = open3($wtr, $rdr, $err, @$cmd);
    waitpid( $pid, 0 );
    my $child_exit_status = $? >> 8;
    if ( $child_exit_status ) {
        $self->status_message($err);
        $self->fatal_message("Failed to run command!");
    }
}

1;
