#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use File::Find 'find';
use File::Spec;

my $assembly_id = $ARGV[0];
die "No assembly id given!" if not $assembly_id;
print STDERR "Assembly id: $assembly_id\n";
my $rassembly_id = ( $ARGV[1] ) ? $ARGV[1] : $assembly_id;
print STDERR "Remote assembly id: $assembly_id\n";

my $adir = File::Spec->join('', 'mnt', 'disks', 'linked-reads-pilot', 'assembly', $assembly_id);
my $local = _build_local($adir);
die "No local paths found\n" if not %$local;
my $rdir = File::Spec->join('mgi-rg-linked-reads-ccdg-pilot', 'assembly', $rassembly_id);
my $remote = _build_remote($rdir);
die "No remote paths found\n" if not %$remote;

my @missing;
for my $lpath ( keys %$local ) {
    push @missing, $lpath if not exists $remote->{$lpath};
}

if ( @missing ) {
    die "ERROR Found @missing files!";
}
else {
    print STDERR "All local files found on remote!\n";
}

###

sub _build_local {
    my ($dir) = @_;
    die "No directory given." if not $dir;
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
    my ($rdir) = @_;
    die "No url given." if not $rdir;
    print STDERR "Find remote paths for $rdir\n";

    my $url = 'gs://'.$rdir.'**';
    print "Run: gsutil ls -l $url\n";
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
