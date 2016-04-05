#** @file Reader.pm
# @brief    Perl module which loads the appropriate class to read
#           files used by the VNTRseek Pipeline
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

package VNTRseek::Reader;

#** @class VNTRseek::Reader
# Class used by a client to access one of [possibly] many
# file readers. A call to this class looks like:
#
#     my $file_reader = VNTRseek::Reader->get_file_reader($format, $file)
#
# where $format is a string denoting the format (currently only "seq"
# is supported) and $file is the full or relative path to a file of
# that format. The file reader can then be used to access the file
# contents.

use strict;
use warnings;
use 5.010;
use Carp;
use Moose;
use IO::File;

sub get_file_reader {
    my $self    = shift;
    my %args    = @_;
    my $reader  = $args{reader};
    my $package = "VNTRseek::Reader::$reader" . "F";
    my $fh;

    eval {
        require $package;
        1;
    } or do {
        croak "Could not load module '$package': $@\n" . "Exiting...\n";
    };

    if ( $args{file} ) {
        $fh = IO::File->new( $args{file}, "r" );
        unless ($fh) {
            croak "Error opening file " . $args{file} . ": $!\n";
        }
    }
    elsif ( $args{fh} ) {
        $fh = $args{fh};
        unless ($fh) {
            croak "Error opening file handle: file handle undefined\n";
        }
        unless ( ( ref $fh eq 'GLOB' )
            || ( UNIVERSAL::isa( $fh, 'IO::Seekable' ) ) )
        {
            croak "Error opening file handle: not a file handle?\n";
        }
    }
    else {
        $fh = *STDIN;
    }

    say @INC;

    return "$package"->new( fh => $fh, %args );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
