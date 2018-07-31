package Sx::Index::Fai;

use strict;
use warnings 'FATAL';

use Sx::Index::FaiReader;

sub ids_and_positions { $_[0]->{ids_and_positions} }
sub reader { $_[0]->{reader} }

sub new {
    my ($class, $file) = @_;

    my $position = 0;
    my %ids_and_positions;
    my $reader = Sx::Index::FaiReader->new($file);
    while ( my $e = $reader->read ) {
        $ids_and_positions{ $e->{id} } = $position;
        $position = $reader->tell;
    }

    my %self = (
        reader => $reader,
        ids_and_positions => \%ids_and_positions,
    );

    bless(\%self, $class);
}

sub entry_for_id {
    my ($self, $id) = @_;
    die "No id given to get entry!" if not defined $id;
    return if not exists $self->ids_and_positions->{$id};
    $self->reader->seek($self->ids_and_positions->{$id});
    $self->reader->read;
}

1;
