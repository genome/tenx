#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = (
        class => 'Tenx::Reads::Command::UploadToCloud::Sample',
        sample_name => 'TESTSAMPLE',
    );
    use_ok($test{class}) or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Reads');

};

subtest 'execute' => sub{
    plan tests => 3;

    my $cmd = $test{class}->create(
        directory => $test{data_dir}->subdir('sample-sheet')->subdir('M_FA-3CTLA4-aCTLA4_10x')->stringify,
        cloud_url => 'gs://bucket',
    );
    lives_ok( sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute successful');
    is($cmd->sample_name, 'M_FA-3CTLA4-aCTLA4_10x', 'resolved sample name');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(
        sub{ $test{class}->execute(directory => '/blah', cloud_url => 'gs://bucket'); },
        qr/Directory does not exist/,
        'fails w/ non existing directory',
    );

};

done_testing();
