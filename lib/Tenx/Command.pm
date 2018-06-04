package Tenx::Command;

use strict;
use warnings;

class Tenx::Command {
    is => 'Command::Tree',
    doc => '10X Genomics commands and utilites',
};

# set commands and classes instead of using the directory structure
my %command_map = (
    alignment => 'Tenx::Alignment::Command',
    gcloud => 'Tenx::Gcloud::Command',
    reads => 'Tenx::Reads::Command',
    reference => 'Tenx::Reference::Command',
);

1;
