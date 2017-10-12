package Tenx::DataSource::MySQL;

use strict;
use warnings 'FATAL';

class Tenx::DataSource::MySQL {
    is => [qw/ UR::DataSource::RDBMSRetriableOperations UR::DataSource::MySQL /],
    has_classwide_constant => [
        server => { default_value => Tenx::Config::get('ds_tenx_server') },
        owner => { default_value => Tenx::Config::get('ds_tenx_owner') },
        database => { default_value => Tenx::Config::get('ds_tenx_database') },
        login => { default_value => Tenx::Config::get('ds_tenx_login') },
        auth => { default_value => Tenx::Config::get('ds_tenx_auth') },
    ],
};

1;
