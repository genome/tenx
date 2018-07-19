package Tenx::Reads::Command::UploadToCloud;

use strict;
use warnings 'FATAL';

class Tenx::Reads::Command::UploadToCloud {
    is => 'Command::Tree',
    doc => 'upload fastqs to the cloud',
};

sub help_detail { $_[0]->__meta__->doc }

1;
