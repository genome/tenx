#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 3;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Util::Loader' );
    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}, 'data dir exists');

};

subtest 'fails' => sub{
    plan tests => 2;

    throws_ok(sub{ $test{class}->new; }, qr/No location given/, 'fails w/o location');
    throws_ok(sub{ $test{class}->new('gs://gcloud/location'); }, qr/Do not know how to load 'gs/, 'fails w/o unknown location');

};

subtest 'load file' => sub{
    plan tests => 3;

    my $file = $test{data_dir}->file('_log');
    my $loader = $test{class}->new($file);
    ok($loader, 'created loader');
    is($loader->location, $file, 'loader location');
    ok($loader->lines, 'loader lines');

};

done_testing();
