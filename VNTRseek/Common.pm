#** @file Common.pm
# @brief    Perl module used by other classes for common functions
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

package VNTRseek::Common;

#** @class VNTRseek::Common
# Module used by other classes for common functions

use strict;
use warnings;
use 5.010;
use Carp;
use File::Spec;

sub _load_module {
	my $module = shift;
	my $load = File::Spec->catfile((split(/::/,"$module.pm")));

    eval {
        require $load;
        1;
    } or do {
        croak "Could not load module '$module': $@\n" . "Exiting...\n";
    };

    return 1;
}

1;
