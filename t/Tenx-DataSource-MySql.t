#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;
use Test::More tests => 1;

Tenx::Config::set('ds_tenx_server', 'server');
Tenx::Config::set('ds_tenx_owner', 'owner');
Tenx::Config::set('ds_tenx_login', 'login');
Tenx::Config::set('ds_tenx_auth', 'auth');
Tenx::Config::set('ds_tenx_database', 'database');

use_ok('Tenx::DataSource::MySQL');

done_testing();
