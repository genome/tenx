#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Slurp;
use Test::Exception;
use Test::More tests => 2;

my %test = ( class => 'Pacbio::Command::Assembly::InsertMissingContigs', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class});
    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}->stringify, 'data dir exists');

};

subtest 'execute' => sub{
    plan tests => 6;

    #my $output = $test{data_dir}->file('got.fasta')->stringify;
    #unlink $output;

    my $cmd = $test{class}->create(
        primary_fasta => $test{data_dir}->file('p_ctg.fasta')->stringify,
        haplotigs_fasta => $test{data_dir}->file('h_ctg.fasta')->stringify,
        #output_fasta => $output,
    );
    ok($cmd, 'create command');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $expected_output = File::Slurp::slurp( $test{data_dir}->file('expected.fasta')->stringify );
    is($output, $expected_output, 'output fasta matches');

    is($cmd->primary_fai, $cmd->primary_fasta.'.fai', 'set primary fai');
    is($cmd->haplotigs_fai, $cmd->haplotigs_fasta.'.fai', 'set haplotigs fai');

};

done_testing();
