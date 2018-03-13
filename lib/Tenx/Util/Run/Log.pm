package Tenx::Util::Run::Log;

use strict;
use warnings 'FATAL';

use DateTime;
use File::stat 'stat';
use List::MoreUtils 'firstval';
use Path::Class;
use Tenx::Util::Loader;

class Tenx::Util::Run::Log {
    has => {
        directory => {
            is => 'Path::Class::Dir',
            doc => 'Log file to analyze.',
        },
        time_zone => {
            is => 'String',
            default_value => 'UTC', # America/Chicago
            doc => 'Time zone where the log file was generated.'
        },
    },
    has_optional_transient => {
        infos => { is => 'Array', },
        run_status => { is => 'Text', },
        stages => { is => 'Array', },
        loader => { is => 'Tenx::Util::Loader', },
    },
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;
    
    $self->_load_log;
    $self->_parse_log;
    $self->_process_log_info;
    $self->_resolve_status;

    $self;
}

sub _load_log {
    my ($self) = @_;

    my $directory = $self->directory;
    $self->fatal_message("No directory file given!") if not $directory;
    $self->fatal_message("Directory does not exist! $directory") if not -d "$directory";

    my $log_file = $directory->file('_log');
    $self->fatal_message("Log file does not exist! $log_file") if not -s "$log_file";

    $self->loader( Tenx::Util::Loader->new("$log_file") );
}

sub _parse_log {
    my ($self) = @_;

    my @infos;
    foreach my $line ( @{$self->loader->lines} ) {
        my $info = _parse_line($line);
        next if not $info;
        push @infos, $info;
    }


    $self->infos(\@infos);
}

sub _parse_line {
    my ($line) = @_;

    return if $line !~ /^\d\d\d\d\-/;

    my (%info, $rest);
    chomp $line;
    ($info{date}, $info{time}, $rest) = split(/\s+/, $line, 3);
    ($info{program}, $rest) = split(/\s+/, $rest, 2);
    $info{program} =~ s/[\[\]]//g;

    return if $info{program} ne 'runtime';

    ($info{status}, $rest) = split(/\s+/, $rest, 2);
    return if not $info{status} =~ s/[\(\)]//g;

    # ID.H_VL-MI-00412-FR04507719.ASSEMBLER_CS._ASSEMBLER._ASSEMBLER_PREP._FASTQ_PREP_NEW.BUCKET_FASTQS.fork0 chunks running (0/6 completed)
    ($info{stage_str}, $rest) = split(/\s+/, $rest, 1);
    my @stage = split(/\./, $info{stage_str});
    shift @stage; # 'ID'
    shift @stage; # RUN ID
    shift @stage; # MAIN STAGE
    for my $step ( @stage ) {
        last if $step =~ /^fork/;
        $step =~ s/^_//;
        push @{$info{stage}}, $step;
    }

    \%info;
}

sub _process_log_info {
    my ($self) = @_;

    my @stages;
    my $order = 0;
    for my $info ( @{$self->infos} ) {
        my $name = join(' ', @{$info->{stage}});
        my $stage = firstval { $_->{name} eq $name } @stages;
        if ( not $stage ) {
            $stage = {
                name => $name,
                order => ++$order,
                status => 'run',
            };
            push @stages, $stage;
        }
        if ( $info->{status} eq 'ready' ) {
            $stage->{start} = $self->_parse_date_time($info->{date}, $info->{time});
        }
        elsif ( $info->{status} eq 'chunks_complete' ) {
            $stage->{stop} = $self->_parse_date_time($info->{date}, $info->{time});
            $stage->{status} = 'done';
        }
        elsif ( $info->{status} eq 'failed' ) {
            $stage->{status} = 'fail';
        }
    }
    
    $self->stages(\@stages);
}

sub _parse_date_time {
    my ($self, $date, $time) = @_;

    # 2018-02-27 && 08:02:43
    my ($year, $month, $day) = split(/\-/, $date);
    my ($hour, $min, $sec) = split(/:/, $time);

    DateTime->new(
        year       => $year,
        month      => $month,
        day        => $day,
        hour       => $hour,
        minute     => $min,
        second     => $sec,
        time_zone  => $self->time_zone,
    );
}

sub _resolve_status {
    my ($self) = @_;

    my @lines = @{$self->loader->lines};
    my $last = $#lines;
    my $start = $last - 10;
    my $status;
    foreach my $line ( @lines[$start .. $last] ) {
        if ( $line =~ /Pipestance completed successfully/ ) {
            return $self->run_status('success');
        }
        elsif ( $line =~ /error/i ) {
            return $self->run_status('failed');
        }
    }

    my $journal_path = $self->directory->subdir('journal');
    return $self->run_status('unknown') if not -d "$journal_path";

    my $journal_st = stat($journal_path);
    if ( not $journal_st ) {
        return $self->run_status('unknown');
    }

    my $journal_access_diff = ((time() - $journal_st->mtime) / 60);
    #$self->journal_access_diff($journal_access_diff);
    return $self->run_status('running') if $journal_access_diff < 10;

    return $self->run_status('zombie');
}

1;
