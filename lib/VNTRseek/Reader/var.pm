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
        $self->Repeatid,    $self->get_refseq, $self->get_allele_seqs,
        $self->get_alleles, $self->get_cgls,   $self->get_rcs );
};
use namespace::autoclean;

has 'Repeatid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'RefSeq' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'AlleleSeqs' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1
);

has 'Alleles' => (
    is       => 'ro',
    isa      => 'ArrayRef[Int]',
    required => 1
);

has 'ReadCounts' => (
    is       => 'ro',
    isa      => 'ArrayRef[Int]',
    required => 1
);

has 'CopyGainLoss' => (
    is       => 'ro',
    isa      => 'ArrayRef[Int]',
    required => 1
);

sub is_vntr {
    my $self = shift;

    # If there are several alleles (rare) or the second
    # allele is greater than 0, this is a VNTR
    return ( scalar @{ $self->Alleles } > 2 ) || ( $self->Alleles->[1] > 0 );
}

sub is_multi {
    my $self = shift;

    # If there are several alleles, this is a "mult" TR
    return ( scalar @{ $self->Alleles } > 2 );
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

sub get_refseq {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : ",";
    my @tmp;

    return ( $self->RefSeq );
}

sub get_allele_seqs {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : ",";
    my @tmp;

    return ( @{ $self->AlleleSeqs } )
        if (wantarray);

    if ( $self->Alleles->[0] == $self->Alleles->[1] ) {
        $concat = $self->AlleleSeqs->[0];
    }
    else {
        my @tmp;
        for my $aseq ( @{ $self->AlleleSeqs } ) {
            push @tmp, sprintf( "%s", $aseq );
        }
        $concat .= join "$sep", @tmp;
    }

    return $concat;
}

sub get_alleles {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : "/";

    return ( @{ $self->Alleles } )
        if (wantarray);

    if ( $self->Alleles->[0] == $self->Alleles->[1] ) {
        $concat
            = sprintf( "%d$sep%d", $self->Alleles->[0], $self->Alleles->[0] );
    }
    else {
        my @tmp;
        for my $a ( @{ $self->Alleles } ) {
            push @tmp, sprintf( "%d", $a );
        }
        $concat .= join "$sep", @tmp;
    }

    return $concat;
}

sub get_cgls {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : "/";

    return ( @{ $self->CopyGainLoss } )
        if (wantarray);

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

sub get_rcs {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : "/";

    return ( @{ $self->ReadCounts } )
        if (wantarray);

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

sub print_gt_tab {
    my $self    = shift;
    my %args    = @_;
    my $out_str = "";

    next
        if($args{'vntr_only'} && !$self->is_vntr);

    my @alleles = $self->get_alleles;

    for ( my ($a, $seq_i) = (0, 0); $a < scalar @alleles; ++$a ) {
        my $seq = ($self->Alleles->[$a] == 0) ? "." : $self->AlleleSeqs->[$seq_i++] ;
    }
}

__PACKAGE__->meta->make_immutable;

1;
