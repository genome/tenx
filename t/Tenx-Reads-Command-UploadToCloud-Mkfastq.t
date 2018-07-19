#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = (
        pkg => 'Tenx::Reads::Command::UploadToCloud::Mkfastq',
    );
    use_ok($test{pkg}) or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Reads');
    $test{expected_sample_names} = [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /];

};

subtest 'create' => sub{
    plan tests => 2;

    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                directory => $test{data_dir}->subdir('sample-sheet')->stringify,
                cloud_url => 'gs://bucket',
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(
        sub{ $test{pkg}->execute(directory => $test{data_dir}->subdir('no-sample')->stringify, cloud_url => 'gs://bucket'); },
        qr/No sample name found/,
        'fails ',
    );

};

done_testing();
