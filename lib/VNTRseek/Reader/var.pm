#** @file var.pm
# @brief    Module for variant records in a VNTRseek VCF file
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

package VNTRseek::Reader::var;

#** @class VNTRseek::Reader::var
# Class representing one record in a .vcf VNTRseek output file.
# This class is meant to be accessed via the VNTRseek::Reader::vcfF
# module, but can be accessed directly to build such entries.
#
# Apart from having built in accessors for the various fields in a
# .vcf file record, you can also print a whole record at once,
# in a CSV format as follows:
#
#     # Prints line to STDOUT
#     print $vcf_record;
#     # Prints line to file handle pointed to by $fh
#     print $fh $vcf_record;

use Carp;
use Moose;
use overload q("") => sub {
    my $self = shift;
    return join( ",",
        $self->Repeatid,
        $self->get_allele_str(sep => ","),
        $self->get_cgl_str(sep => ","),
        $self->get_rc_str(sep => ",") );
};
use namespace::autoclean;

has 'Repeatid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'Alleles' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1
);

has 'ReadCounts' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1
);

has 'CopyGainLoss' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1
);

sub is_vntr {
    my $self = shift;
    # If there are several alleles (rare) or the second
    # allele is greater than 0, this is a VNTR
    return ( scalar @{$self->Alleles} > 2 ) || ( $self->Alleles->[1] > 0 );
}

sub is_multi {
    my $self = shift;
    # If there are several alleles, this is a "mult" TR
    return ( scalar @{$self->Alleles} > 2 );
}

sub print_line {
    my $self = shift;
    my $fh = shift // *STDOUT;

    print $fh $self;
}

sub print_brief {
    my $self = shift;
    my $fh = shift // *STDOUT;

    $self->print_line( $self, $fh );
}

sub get_allele_str {
    my $self     = shift;
    my %args     = @_;
    my $concat = "";
    my $sep      = ($args{'sep'}) ? $args{'sep'} : "/";

    if ( $self->Alleles->[0] == $self->Alleles->[1] ) {
        $concat = sprintf( "%d$sep%d",
            $self->CopyGainLoss->[0],
            $self->CopyGainLoss->[0] );
    }
    else {
        my @tmp;
        for my $cgl ( @{ $self->CopyGainLoss } ) {
            push @tmp, sprintf( "%d", $cgl );
        }
        $concat .= join "$sep", @tmp;
    }

    return $concat;
}

sub get_cgl_str {
    my $self     = shift;
    my %args     = @_;
    my $concat = "";
    my $sep      = ($args{'sep'}) ? $args{'sep'} : "/";

    if ( $self->Alleles->[0] == $self->Alleles->[1] ) {
        $concat = sprintf( "%+d$sep%+d",
            $self->CopyGainLoss->[0],
            $self->CopyGainLoss->[0] );
    }
    else {
        my @tmp;
        for my $cgl ( @{ $self->CopyGainLoss } ) {
            push @tmp, sprintf( "%+d", $cgl );
        }
        $concat .= join "$sep", @tmp;
    }

    return $concat;
}

sub get_rc_str {
    my $self     = shift;
    my %args     = @_;
    my $concat = "";
    my $sep      = ($args{'sep'}) ? $args{'sep'} : "/";

    if ( $self->Alleles->[0] == $self->Alleles->[1] ) {
        $concat = sprintf( "%d$sep%d",
            $self->ReadCounts->[0],
            $self->ReadCounts->[0] );
    }
    else {
        my @tmp;
        for my $rc ( @{ $self->ReadCounts } ) {
            push @tmp, sprintf( "%d", $rc );
        }
        $concat .= join "$sep", @tmp;
    }

    return $concat;
}

__PACKAGE__->meta->make_immutable;

1;
