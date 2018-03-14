#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 5;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 3;

    %test = ( class => 'Tenx::Util::Loader' );
    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}, 'data dir exists');

    $test{log_file} = $test{data_dir}->file('_log');
    ok(-s $test{log_file}, 'log file exists');

};

subtest 'fails' => sub{
    plan tests => 2;

    throws_ok(sub{ $test{class}->new; }, qr/No location given/, 'fails w/o location');
    throws_ok(sub{ $test{class}->new('gs://gcloud/location'); }, qr/not know how to load 'gs/, 'fails w/o unknown location');

};

subtest 'new' => sub{
    plan tests => 1;

    $test{loader} = $test{class}->new($test{log_file});
    ok($test{loader}, 'created loader');

};

subtest 'attributes' => sub{
    plan tests => 2;

    is($test{loader}->location, $test{log_file}, 'loader location');
    ok($test{loader}->lines, 'loader lines');

};

subtest 'io' => sub{
    plan tests => 2;

    my $io = $test{loader}->io_handle;
    ok($io, 'got io_handle');
    is_deeply([ $io->getlines ], $test{loader}->lines, 'io and lines match');

};

done_testing();
