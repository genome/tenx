package TenX::DataSource::MySQL;

use strict;
use warnings 'FATAL';

class TenX::DataSource::MySQL {
    is => [qw/ UR::DataSource::RDBMSRetriableOperations UR::DataSource::MySQL /],
    has_classwide_constant => [
        server => { default_value => Tenx::Config::get('ds_mysql_server') },
        owner => { default_value => Tenx::Config::get('ds_mysql_owner') },
        database => { default_value => Tenx::Config::get('ds_mysql_database') },
        login => { default_value => Tenx::Config::get('ds_mysql_login') },
        auth => { default_value => Tenx::Config::get('ds_mysql_auth') },
    ],
};

1;
