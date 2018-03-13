#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 3;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Util::Run' );
    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}, 'data dir exists');

    $test{object} = $test{class}->new($test{data_dir}->subdir('supernova-success'));
};

subtest 'log' => sub{
    plan tests => 2;

    is($test{object}->log_file, $test{object}->location->file('_log'), 'log_file');
    isa_ok($test{object}->log, 'Tenx::Util::Run::Log');

};

subtest 'summary csv' => sub{
    plan tests => 1;

    is($test{object}->summary_csv, $test{object}->location->subdir('outs')->file('summary.csv'), 'summary_csv');

};

done_testing();
