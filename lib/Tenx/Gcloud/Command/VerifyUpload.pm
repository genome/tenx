package Tenx::Gcloud::Command::VerifyUpload;

use strict;
use warnings 'FATAL';

use File::Find 'find';
use File::Spec;
use IO::File

class Tenx::Gcloudy::Command::VerifyUpload {
    is => 'Command::V2',
    has => {
        ldir => {
            is => 'Text',
            doc => 'Local directory to verify.',
        },
        rdir => {
            is => 'Text',
            doc => 'Remote gcloud directory. Do not include gs:/ protocol.',
        },
    },
};

sub execute {
    my ($self) = @_;

    # FIXME
    my $assembly_id = $ARGV[0];
    $self->fatal_message("No assembly id given!") if not $assembly_id;

    $self->status_message("Assembly id: $assembly_id");
    my $rassembly_id = ( $ARGV[1] ) ? $ARGV[1] : $assembly_id;
    $self->status_message("Remote assembly id: $assembly_id");

    my $adir = File::Spec->join('', 'mnt', 'disks', 'linked-reads-pilot', 'assembly', $assembly_id);
    my $local = $self->_build_local($adir);
    $self->fatal_message( "No local paths found") if not %$local;
    my $rdir = File::Spec->join('mgi-rg-linked-reads-ccdg-pilot', 'assembly', $rassembly_id);
    my $remote = $self->_build_remote($rdir);
    $self->fatal_message( "No remote paths found)" if not %$remote;

    my @missing;
    for my $lpath ( keys %$local ) {
        push @missing, $lpath if not exists $remote->{$lpath};
    }

    if ( @missing ) {
        $self->fatal_message( "ERROR Found @missing files!";
    }
    else {
        $self->status_message("All local files found on remote!");
    }
}

sub _build_local {
    my ($self, $dir) = @_;
    $self->fatal_message( "No directory given." if not $dir;
    print STDERR "Find local paths for $dir\n";

    my (%local);
    find(
        {
            wanted => sub{
                if ( -f $File::Find::name ) {
                    my $path = $File::Find::name;
                    $path =~ s#$dir/##;
                    $local{$path} = 1;
                }
            },
        },
        glob($dir),
    );

    \%local;
}

sub _build_remote {
    my ($self) = @_;

    my $rdir = $self->rdir;
    $self->status_message("Find remote paths for $rdir");

    my $url = 'gs://'.$rdir.'**';
    $self->status_message("Run: gsutil ls -l $url");
    my $fh = IO::File->new("gsutil ls -l $url |");
    my %remote;
    while ( my $line = $fh->getline ) {
        chomp $line;
        $line =~ s/^\s+//;
        my @tokens = split(/\s+/, $line);
        if ( @tokens > 1 ) {
            my ($sz, $ts, $rpath) = split(/\s+/, $line);
            $tokens[2] =~ s#gs://$rdir/##;
            $remote{$tokens[2]} = [ @tokens[0..1] ];
        }
    }

    \%remote
}

1;
