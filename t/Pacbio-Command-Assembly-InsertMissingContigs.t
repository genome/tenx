#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Slurp;
use Test::Exception;
use Test::More tests => 3;

my %test = ( class => 'Pacbio::Command::Assembly::InsertMissingContigs', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class});
    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}->stringify, 'data dir exists');

};

subtest 'execute' => sub{
    plan tests => 6;

    my $cmd = $test{class}->create(
        primary_fasta => $test{data_dir}->file('p_ctg.fasta')->stringify,
        haplotigs_fasta => $test{data_dir}->file('h_ctg.fasta')->stringify,
    );
    ok($cmd, 'create command');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $got = $test{data_dir}->file('got.fasta')->stringify;
    unlink $got;
    File::Slurp::write_file($got, $output);

    my $expected_output = File::Slurp::slurp( $test{data_dir}->file('p.expected.fasta')->stringify );
    is($output, $expected_output, 'output fasta matches');

    is($cmd->primary_fai, $cmd->primary_fasta.'.fai', 'set primary fai');
    is($cmd->haplotigs_fai, $cmd->haplotigs_fasta.'.fai', 'set haplotigs fai');

};

subtest 'primary id for haplotig id' => sub{
    plan tests => 3;

    throws_ok(sub{ $test{class}->primary_contig_id_for_haplotig_id(); } , qr/No haplotig id/, 'fails w/o haplotig id');
    throws_ok(sub{ $test{class}->primary_contig_id_for_haplotig_id('000200F|arrow'); } , qr/Could not find haplotig number/, 'fails w/o invalid haplotig id');
    is($test{class}->primary_contig_id_for_haplotig_id('000200F_002|arrow'), '000200F|arrow', 'correct primary id');

};

done_testing();
