#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;
use Test::More tests => 1;

Tenx::Config::set('ds_mysql_server', 'server');
Tenx::Config::set('ds_mysql_owner', 'owner');
Tenx::Config::set('ds_mysql_login', 'login');
Tenx::Config::set('ds_mysql_auth', 'auth');
Tenx::Config::set('ds_mysql_database', 'database');

use_ok('Tenx::DataSource::MySQL');

done_testing();
