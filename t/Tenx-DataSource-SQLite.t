#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 1;

Tenx::Config::set('ds_sqlite_server', 'server');
use_ok('Tenx::DataSource::TestDb');

done_testing();
