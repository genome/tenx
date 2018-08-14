#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Slurp;
use Test::Exception;
use Test::More tests => 4;

my %test = ( class => 'Pacbio::Command::Assembly::BaxToBam::GenerateCommands', );
subtest 'setup' => sub{
    plan tests => 3;

    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}->stringify, 'data dir exists');
    $test{tempdir} = File::Temp::tempdir(CLEANUP => 1);

    $test{run_directories} = TenxTestEnv::test_data_directory_for_class('Pacbio::Run');
    ok(-d $test{run_directories}->stringify, 'run dirs exists');

};

subtest 'execute' => sub{
    plan tests => 4;

    my $cmd = $test{class}->create(
        run_directories => [ $test{data_dir}->file('6U00E3')->stringify, ],
        bam_to_bax_command => 'bsub -q long -o %LOG bam2bax',
    );
    ok($cmd, 'create command');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $expected_output = File::Slurp::slurp( $test{data_dir}->file('expected.out')->stringify );
    my $base_test_data_dir = TenxTestEnv::test_data_directory();
    $expected_output =~ s/\%TDD/$base_test_data_dir/g;
    is($output, $expected_output, 'output commands matches');

};

subtest 'execute with library name' => sub{
    plan tests => 4;

    my $library_name = 'EEAI';
    my $cmd = $test{class}->create(
        run_directories => [ $test{data_dir}->file('6U00E3')->stringify, ],
        bam_to_bax_command => 'bsub -q long -o %LOG bam2bax',
        library_name => $library_name,
    );
    ok($cmd, 'create command');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $expected_output = File::Slurp::slurp( $test{data_dir}->file( join('.', 'expected', $library_name, 'out') )->stringify );
    my $base_test_data_dir = TenxTestEnv::test_data_directory();
    $expected_output =~ s/\%TDD/$base_test_data_dir/g;
    is($output, $expected_output, 'output commands matches');

};

subtest 'execute with some bams completed' => sub{
    plan tests => 4;

    my $cmd = $test{class}->create(
        run_directories => [ $test{data_dir}->file('6U00E3')->stringify, ],
        bam_to_bax_command => 'bsub -q long -o %LOG bam2bax',
        bam_output_directory => $test{data_dir}->stringify,
    );
    ok($cmd, 'create command');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $expected_output = File::Slurp::slurp( $test{data_dir}->file('expected.some-done.out')->stringify );
    my $base_test_data_dir = TenxTestEnv::test_data_directory();
    $expected_output =~ s/\%TDD/$base_test_data_dir/g;
    is($output, $expected_output, 'output commands matches');

};

done_testing();
