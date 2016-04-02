#** @file   seq.pm
# @brief    Module for a seq record in a VNTRseek .seq file
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

package VNTRseekHelpers::Reader::seq;

#** @class VNTRseekHelpers::Reader::seq
# Class representing one record in a .seq VNTRseek input file.
# This class is meant to be accessed via the VNTRseekHelpers::Reader::seqIO
# module, but can be accessed directly to build such entries.
#
# Apart from having built in accessors for the various fields in a
# .seq file record, you can also print a whole record at once,
# in a CSV format as follows:
#
#     # Prints line to STDOUT
#     print $seq_record;
#     # Prints line to file handle pointed to by $fh
#     print $fh $seq_record;
use strict;
use warnings;
use 5.010;
use Carp;
use Moose;
use overload q("") => sub {
    my $self = shift;
    return join( ",",
        $self->Repeatid,          $self->FirstIndex,
        $self->LastIndex,         $self->CopyNumber,
        $self->FastaHeader,       $self->FlankingLeft1000,
        $self->Pattern,           $self->ArraySequence,
        $self->FlankingRight1000, $self->Conserved ),
        "\n";
};

has 'Repeatid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'FirstIndex' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'LastIndex' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'CopyNumber' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1
);

has 'FastaHeader' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'FlankingLeft1000' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'Pattern' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'ArraySequence' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'FlankingRight1000' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'Conserved' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1
);

sub print_line {
    my $self = shift;
    my $fh = shift // *STDOUT;

    print $fh join( ",",
        $self->Repeatid,          $self->FirstIndex,
        $self->LastIndex,         $self->CopyNumber,
        $self->FastaHeader,       $self->FlankingLeft1000,
        $self->Pattern,           $self->ArraySequence,
        $self->FlankingRight1000, $self->Conserved ),
        "\n";
}

sub print_brief {
    my $self = shift;
    my $fh = shift // *STDOUT;

    print $fh join( ",",
        $self->Repeatid,   $self->FirstIndex,  $self->LastIndex,
        $self->CopyNumber, $self->FastaHeader, $self->Pattern ),
        "\n";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;