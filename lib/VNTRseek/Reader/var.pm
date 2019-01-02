#** @file var.pm
# @brief    Module for variant records in a VNTRseek VCF file
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

use strict;

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
    my $self    = shift;
    my $out_str = "$self->{Repeatid}\t$self->{RefSeq}\t";
    $out_str .= $self->get_altseqs . "\t";
    my $format = "GT:SP:CGL";
    $format .= ( $self->has_zslabels )        ? "" : ":ZL";
    $format .= ( $self->has_mllabel )         ? "" : ":MLZ";
    $format .= ( $self->has_mlconfidence )    ? "" : ":MLC";
    $format .= ( $self->has_treenodepercent ) ? "" : ":MLN";
    $out_str .= "$format\t";
    $out_str .= join( ":",
        "" . $self->get_alleles,
        "" . $self->get_cgls,
        "" . $self->get_rcs );
    $out_str .= ( $self->has_zslabels )     ? "" : ":" . $self->get_zslabels;
    $out_str .= ( $self->has_mllabel )      ? "" : ":" . $self->MLLabel;
    $out_str .= ( $self->has_mlconfidence ) ? "" : ":" . $self->MLConfidence;
    $out_str
        .= ( $self->has_treenodepercent ) ? "" : ":" . $self->TreeNodePercent;
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

has 'AltAlleleSeqs' => (
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

has 'ZSLabels' => (
    is        => 'ro',
    isa       => 'Maybe[ArrayRef[Str]]',
    predicate => 'has_zslabels',
);

has 'MLLabel' => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_mllabel',
);

has 'MLConfidence' => (
    is        => 'ro',
    isa       => 'Maybe[Num]',
    predicate => 'has_mlconfidence',
);

has 'TreeNodePercent' => (
    is        => 'ro',
    isa       => 'Maybe[Num]',
    predicate => 'has_treenodepercent',
);

has 'Filter' => (
    is  => 'ro',
    isa => 'HashRef[Str]',
);

has 'IsVNTR' => (
    is  => 'rw',
    isa => 'Bool',
);

has 'IsMulti' => (
    is  => 'rw',
    isa => 'Bool',
);

has 'IsHomozygous' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;

        # If there are several alleles, this is a "multi" TR
        return ( $self->Alleles->[0] == $self->Alleles->[1] );
    }
);

has 'IsHeterozygous' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;

        # If there are several alleles, this is a "multi" TR
        return !( $self->IsHomozygous );
    }
);

has 'RefTyped' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return ( $self->Alleles->[0] == 0 );
    }
);

has 'NumAlleles' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return scalar( @{ $self->CopyGainLoss } );
    }
);

sub filter_passed {
    my $self = shift;

    # If there are several alleles, this is a "multi" TR
    return ( defined $self->Filter->{PASS} );
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

sub get_altseqs {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : ",";

    return ( @{ $self->AltAlleleSeqs } )
        if (wantarray);

    # if ( $self->IsHomozygous ) {
    #     $concat = $self->AltAlleleSeqs->[0];
    # }
    # else {
    #     my @tmp;
    #     for my $aseq ( @{ $self->AltAlleleSeqs } ) {
    #         push @tmp, sprintf( "%s", $aseq );
    #     }
    #     $concat .= join "$sep", @tmp;
    # }

    return ( join "$sep", @{ $self->AltAlleleSeqs } );
}

sub get_alleles {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : "/";

    return ( @{ $self->Alleles } )
        if (wantarray);

    if ( $self->IsHomozygous ) {
        $concat
            = sprintf( "%d$sep%d", $self->Alleles->[0], $self->Alleles->[0] );
    }
    else {
        # my @tmp;
        # for my $a ( @{ $self->Alleles } ) {
        #     push @tmp, sprintf( "%d", $a );
        # }
        $concat = join "$sep", @{ $self->Alleles };
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

    if ( $self->IsHomozygous ) {
        $concat = sprintf( "%+d$sep%+d",
            $self->CopyGainLoss->[0],
            $self->CopyGainLoss->[0] );
    }
    else {
        my @tmp;
        for my $cgl ( @{ $self->CopyGainLoss } ) {
            push @tmp, sprintf( "%+d", $cgl );
        }
        $concat = join "$sep", @tmp;
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

    if ( $self->IsHomozygous ) {
        $concat = sprintf( "%d$sep%d",
            $self->ReadCounts->[0],
            $self->ReadCounts->[0] );
    }
    else {
        # my @tmp;
        # for my $rc ( @{ $self->ReadCounts } ) {
        #     push @tmp, sprintf( "%d", $rc );
        # }
        $concat = join "$sep", @{ $self->ReadCounts };
    }

    return $concat;
}

sub get_zslabels {
    my $self   = shift;
    my %args   = @_;
    my $concat = "";
    my $sep    = ( $args{'sep'} ) ? $args{'sep'} : ",";

    return ( @{ $self->ZSLabels } )
        if (wantarray);

    if ( $self->IsHomozygous ) {
        $concat
            = sprintf( "%d$sep%d", $self->ZSLabels->[0],
            $self->ZSLabels->[0] );
    }
    else {
        # my @tmp;
        # for my $a ( @{ $self->ZSLabels } ) {
        #     push @tmp, sprintf( "%d", $a );
        # }
        $concat = join "$sep", @{ $self->ZSLabels };
    }

    return $concat;
}

sub print_gt_tab {
    my $self    = shift;
    my %args    = @_;
    my $out_str = "";

    next
        if ( $args{'vntr_only'} && !$self->is_vntr );

    my @alleles = $self->get_alleles;

    for ( my ( $a, $seq_i ) = ( 0, 0 ); $a < scalar @alleles; ++$a ) {
        my $seq
            = ( $self->Alleles->[$a] == 0 )
            ? "."
            : $self->AltAlleleSeqs->[ $seq_i++ ];
    }
}

__PACKAGE__->meta->make_immutable;

1;
