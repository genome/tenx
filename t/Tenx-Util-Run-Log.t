#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 5;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Util::Run::Log' );

    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Run');
    ok(-d $test{data_dir}, 'data dir exists');

};

subtest 'fails' => sub{
    plan tests => 3;

    throws_ok(sub{ $test{class}->create; }, qr//, 'fails w/o directory');
    throws_ok(sub{ $test{class}->create(directory => $test{data_dir}->subdir('blah')); }, qr/Directory does not exist/, 'fails w/o invalid directory');
    throws_ok(sub{ $test{class}->create(directory => $test{data_dir}); }, qr/Log file does not exist/, 'fails w/o log in directory');

};

subtest 'success log' => sub{
    plan tests => 2;

    my $log = $test{class}->create(directory => $test{data_dir}->subdir('supernova-success'));
    ok($log, 'created log');
    is($log->run_status, 'success', 'run status');

};

subtest 'zombie log' => sub{
    plan tests => 2;

    my $log = $test{class}->create(directory => $test{data_dir}->subdir('supernova-zombie'));
    ok($log, 'created log');
    is($log->run_status, 'zombie', 'run status');

};

subtest 'fail log' => sub{
    plan tests => 2;

    my $log = $test{class}->create(directory => $test{data_dir}->subdir('longranger-fail'));
    ok($log, 'created log');
    is($log->run_status, 'failed', 'run status');

};

done_testing();
