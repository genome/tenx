package Tenx::Assembly::Command::Stats;

use strict;
use warnings 'FATAL';

use Bio::SeqIO;
use Data::Dumper;
use Path::Class;
use Text::CSV;
use YAML;

class Tenx::Assembly::Command::Stats {
    is => 'Command::V2',
    has_input => {
        fasta_file => {
            is => 'Text',
            doc => 'Fasta file to derive assembly stats.',
        },
    },
    has_optional_input => {
        min_gap_size => {
            is => 'Number',
            default_value => 1,
            doc => 'Minimum ',
        },
    },
    has_calculated_constant_optional => {
        _directory => { calculate_from => [qw/ directory /], calculate => q| Path::Class::dir($directory) |, },
        summary_file => { calculate_from => [qw/ _directory /], calculate => q| $_directory->subdir('outs')->file('summary.csv') |, },
    },
};

sub execute {
    my ($self) = @_;

    my $fasta_file = $self->fasta_file;
    $self->fatal_message('Fasta file does not exist! %s', $fasta_file) if not -f $fasta_file or not -s $fasta_file;
    my $reader = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => $fasta_file,
    );

    my $min_Ns_for_gap = $self->min_gap_size;
    my %metrics;
    my @scaf_lengths;
    my @ctg_lengths;
    my $max_scaffold_length = 0;
    my $max_contig_length = 0;
    while( my $seq = $reader->next_seq ) {
        #print 'Processing '.$seq->id."\n";
        my $scaffold_length = length $seq->seq;
        set_breakdown_length( \%metrics, $scaffold_length, 'SCAF' );
        $metrics{'SCAFFOLD_LENGTHS'} += $scaffold_length;
        $metrics{'SCAFFOLD_COUNT'}++;
        #push @{$metrics{'IND_SCAFFOLDS_LENGTHS'}}, $scaffold_length;
        push @scaf_lengths, $scaffold_length;
        if( $scaffold_length > $max_scaffold_length ) {
            $metrics{'MAX_SCAFFOLD_LENGTH'} = $scaffold_length;
            $max_scaffold_length = $scaffold_length;
            $metrics{'MAX_SCAFFOLD_ID'} = $seq->id;
            my $sequence = $seq->seq;
            $sequence =~ s/N//ig;
            $metrics{'MAX_SCAFFOLD_BASES_LENGTH'} = length $sequence;
        }
        my @contigs = split(/N{$min_Ns_for_gap,}+/i, $seq->seq);
        #print Dumper \@contigs;
        for my $contig( @contigs ) {
            my $contig_length = length $contig;
            set_breakdown_length( \%metrics, $contig_length, 'CTG' );
            push @ctg_lengths, $contig_length;
            $metrics{'CONTIG_LENGTHS'} += $contig_length;
            $metrics{'CONTIG_COUNT'}++;
            if( $contig_length > $max_contig_length ) {
                $metrics{'MAX_CONTIG_LENGTH'} = $contig_length;
                $max_contig_length = $contig_length;
            }
        }
    }

    #print YAML::Dump \%metrics;

    # CALCULATE n50 length
    @scaf_lengths = sort {$b<=>$a} @scaf_lengths;
    my $n50_length = 0;
    my $total_lengths;
    for( 0 .. $#scaf_lengths ) {
        my $length = $scaf_lengths[$_];
        $total_lengths += $length;
        if( $total_lengths > ( $metrics{'SCAFFOLD_LENGTHS'} * 0.5 ) ) {
            $n50_length = $scaf_lengths[ $_ - 1].' ('.$scaf_lengths[$_].') '.$scaf_lengths[ $_ + 1 ];
            last;
        }
    }

    @ctg_lengths = sort {$b<=>$a} @ctg_lengths;
    my $n50_ctg_length = 0;
    $total_lengths = 0;
    for( 0 .. $#ctg_lengths ) {
        my $length = $ctg_lengths[$_];
        $total_lengths += $length;
        if( $total_lengths > ( $metrics{'CONTIG_LENGTHS'} * 0.5 ) ) {
            $n50_ctg_length = $ctg_lengths[ $_ - 1 ].' ('.$ctg_lengths[$_].') '.$ctg_lengths[ $_ + 1 ];
            last;
        }
    }

    print "SCAFFOLDS\n";
    printf( "  %-10s%-15s\n", 'COUNT', $metrics{'SCAFFOLD_COUNT'} );
    printf( "  %-10s%-15s\n", 'LENGTH', $metrics{'SCAFFOLD_LENGTHS'} );
    printf( "  %-10s%-15s\n", 'AVG', int( $metrics{'SCAFFOLD_LENGTHS'} / $metrics{'SCAFFOLD_COUNT'} ) );
    printf( "  %-10s%-15s\n", 'N50', $n50_length);
    printf( "  %-10s%-15s\n", 'LARGEST', $metrics{'MAX_SCAFFOLD_LENGTH'} );
    print ' (ID: '.$metrics{'MAX_SCAFFOLD_ID'}.', BASES_ONLY_LENGTH: '.$metrics{'MAX_SCAFFOLD_BASES_LENGTH'}.")\n";
    print_length_bd( \%metrics, 'SCAF' );
    print "\nCONTIGS\n";
    printf( "  %-10s%-15s\n", 'COUNT', $metrics{'CONTIG_COUNT'} );
    printf( "  %-10s%-15s\n", 'LENGTH', $metrics{'CONTIG_LENGTHS'} );
    printf( "  %-10s%-15s\n", 'AVG', int( $metrics{'CONTIG_LENGTHS'} / $metrics{'CONTIG_COUNT'} ) );
    printf( "  %-10s%-15s\n", 'N50', $n50_ctg_length);
    printf( "  %-10s%-15s\n", 'LARGEST', $metrics{'MAX_CONTIG_LENGTH'} );
    print_length_bd( \%metrics, 'CTG' );
}

sub print_length_bd {
    my ($metrics, $type) = @_;
    my $subject = ( $type eq 'SCAF' )
    ? 'Scaffolds'
    : 'Contigs' ;
    my @len_types = ('> 1M', '250K--1M', '100K--250K', '10K--100K', '5K--10K', '2K--5K', '0--2K');
    for my $len_type( @len_types ) {
       my $length = ( exists $metrics->{'BD'}{$type}{$len_type}{'len'} )
	   ? $metrics->{'BD'}{$type}{$len_type}{'len'}
           : 0 ;
       my $count = ( exists $metrics->{'BD'}{$type}{$len_type}{'ct'} )
	   ? $metrics->{'BD'}{$type}{$len_type}{'ct'}
           : 0 ;
       print "  $subject $len_type: $count ( $length bp )\n";
    }
}

sub set_breakdown_length {
    my ($metrics, $length, $type) = @_;
    my @len_types = ('> 1M', '250K--1M', '100K--250K', '10K--100K', '5K--10K', '2K--5K', '0--2K');
    if( $length > 1000000 ) {
	$metrics->{'BD'}{$type}{$len_types[0]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[0]}{'ct'} ++;
    }
    elsif( $length > 250000 ) {
	$metrics->{'BD'}{$type}{$len_types[1]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[1]}{'ct'} ++;
    }
    elsif( $length > 100000 ) {
	$metrics->{'BD'}{$type}{$len_types[2]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[2]}{'ct'} ++;
    }
    elsif( $length > 10000 ) {
	$metrics->{'BD'}{$type}{$len_types[3]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[3]}{'ct'} ++;
    }
    elsif( $length > 5000 ) {
	$metrics->{'BD'}{$type}{$len_types[4]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[4]}{'ct'} ++;
    }
    elsif( $length > 2000 ) {
	$metrics->{'BD'}{$type}{$len_types[5]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[5]}{'ct'} ++;
    }
    elsif( $length > 0 ) {
	$metrics->{'BD'}{$type}{$len_types[6]}{'len'} += $length;
	$metrics->{'BD'}{$type}{$len_types[6]}{'ct'} ++;
    }
    else {
	# shouldn't happen
	die "TYPE: $type, LENGHT: $length\n";
    }
}

1;
