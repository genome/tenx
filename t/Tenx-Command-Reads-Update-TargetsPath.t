#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test;
subtest "setup" => sub{
    plan tests => 1;

    $test{pkg} = 'Tenx::Command::Reads::Update::TargetsPath';
    use_ok($test{pkg}) or die;

    $test{reads} = Tenx::Reads->__define__(sample_name => 'TEST', directory => 'blah');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $test{pkg}->execute( reads => [ $test{reads}, ], value => 'tmp'); }, qr//, 'fails w/ invalid targets_path');

};

subtest 'update' => sub{
    plan tests => 2;

    my $update = $test{pkg}->execute(
        reads => [ $test{reads}, ],
        value => '/tmp',
    );
    ok($update->result, 'execute');

    is($test{reads}->targets_path, '/tmp', 'set reads targets_path');

};

done_testing();
