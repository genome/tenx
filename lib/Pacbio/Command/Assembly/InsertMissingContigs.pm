package Pacbio::Command::Assembly::InsertMissingContigs;

use strict;
use warnings 'FATAL';

use Bio::SeqIO;
use List::MoreUtils;
use Set::Scalar;
use Sx::Index::Fai;

class Pacbio::Command::Assembly::InsertMissingContigs {
    is => 'Command::V2',
    has_input => {
        primary_fasta => {
            is => 'Text',
            doc => 'Primary contigs fasta file.',
        },
        haplotigs_fasta => {
            is => 'Text',
            doc => 'Haplotigs contigs fasta file.',
        },
    },
    has_optional_input => {
        primary_fai => {
            is => 'Text',
            doc => 'Primary contigs fasta index file. If not given, ".fai" will be appended to the primary contigs fasta file name.',
        },
        haplotigs_fai => {
            is => 'Text',
            doc => 'Haplotigs contigs fasta index file. If not given, ".fai" will be appended to the haplotigs contigs fasta file name.',
        },
    },
    has_optional_output => {
        output_fasta => {
            is => 'Text',
            default_value => '-',
            doc => 'Output fasta file. Defaults to STDOUT.',
        },
    },
    has_optional_transient => {
        _haplotigs_fai => { is => 'Sx::Index::Fai', },
    },
    doc => 'insert missing primary contigs from haplotigs',
};

sub __init__ {
    my ($self) = @_;

    for my $type (qw/ primary haplotigs /) {
        my $fasta_method = join('_', $type, 'fasta');
        $self->fatal_message("File $fasta_method does not exist!") if not -s $self->$fasta_method;
        my $fai_method = join('_', $type, 'fai');
        if ( not $self->$fai_method ) {
            $self->$fai_method( join('.', $self->$fasta_method, 'fai') );
        }
        $self->fatal_message("File $fai_method does not exist!") if not -s $self->$fai_method;
    }

    my $output_fasta = $self->output_fasta;
    if ( $output_fasta and $output_fasta ne '-' ) {
        $self->fatal_message("Output file exists: $output_fasta. Please change detination, or remove it.") if -s $output_fasta;
    }
}

sub execute {
    my ($self) = @_;

    $self->__init__;
    my $ctgs = $self->_get_primary_contigs_set_from_fai;
    my $haplotigs = $self->_get_haplotigs_set_from_fai;
    my $missing_ctgs = $haplotigs->difference($ctgs);
    $self->fatal_message("No missing contigs found!") if not $missing_ctgs->members;
    my $missing_haplotigs = $self->_get_missing_haplotigs($missing_ctgs);
    #print Data::Dumper::Dumper([sort $ctgs->members]);
    #print Data::Dumper::Dumper([sort $missing_ctgs->members]);
    #print Data::Dumper::Dumper([sort $missing_haplotigs->members]);
    $self->_write_contigs($ctgs->union($missing_haplotigs));
    1;
}

sub _get_primary_contigs_set_from_fai {
    my ($self) = @_;

    my $fai = Sx::Index::FaiReader->new($self->primary_fai);
    my $set = Set::Scalar->new;
    while ( my $e = $fai->read ) {
        $set->insert($e->{id});
    }

    $set;
}

sub _get_haplotigs_set_from_fai {
    my ($self) = @_;

    my $fai = Sx::Index::Fai->new($self->haplotigs_fai);
    $self->_haplotigs_fai($fai);
    $fai->reader->reset;

    my $set = Set::Scalar->new;
    while ( my $e = $fai->reader->read ) {
        my @t = split(/\|/, $e->{id});
        $t[0] =~ s/_\d+$//;
        $set->insert( join('|', @t) );
    }

    $set;
}

sub _get_missing_haplotigs {
    my ($self, $missing) = @_;

    my $fai = $self->_haplotigs_fai;
    my $set = Set::Scalar->new;
    for my $id ( $missing->members ) {
        my @t = split(/\|/, $id);
        my $entries = $fai->entries_for_id_regex("^$t[0]");
        $self->fatal_message("Failed to get haplotigs for id regex: $id") if not $entries;
        my ($max) = sort { $b->{length} <=> $a->{length} } @$entries;
        $set->insert($max->{id});
    }

    $set;
}

sub _write_contigs {
    my ($self, $contigs) = @_;

	my $pfh = IO::File->new($self->primary_fasta, 'r');
	$self->fatal_message('Failed to open primary fasta! %s', $self->primary_fasta) if not $pfh;
	my $pseqio = Bio::SeqIO->new(
		-fh => $pfh,
		-format => 'Fasta',
	);

	my $hfh = IO::File->new($self->haplotigs_fasta, 'r');
	$self->fatal_message('Failed to open haplotigs fasta! %s', $self->haplotigs_fasta) if not $hfh;
	my $hseqio = Bio::SeqIO->new(
		-fh => $hfh,
		-format => 'Fasta',
	);

	my $output_fasta = $self->output_fasta;
	my %seqio_params = ( $self->output_fasta eq '-' )
	? ( -fh => \*STDOUT )
	: ( -file => ">$output_fasta" );
	$seqio_params{'-format'} = 'Fasta';
	my $oseqio = Bio::SeqIO->new(%seqio_params);

    my $seq;
    for my $ctg_id ( sort { $a cmp $b } $contigs->members ) {
        my $entry = $self->_haplotigs_fai->entry_for_id($ctg_id);
        if ( defined $entry ) {
            my $pos = $entry->{offset} - length($ctg_id) - 2;
            $hfh->seek($pos, 0);
            $seq = $hseqio->next_seq;
        }
        else {
            $seq = $pseqio->next_seq;
        }
        $oseqio->write_seq($seq);
    }
}

1;
