#** @file vcfF.pm
# @brief    Reader module for .vcf files
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

package VNTRseek::Reader::vcfF;

#** @class VNTRseek::Reader::vcfF
# A class for reading .vcf files produced as output by VNTRseek.
#
# Example use:
#
#     my $vcf_reader = VNTRseek::Reader->get_file_reader("vcf", $file);
#     while (my $entry = $vcf_reader->next_var) { ... }
#
# You can also call this module directly, without needing to use
# VNTRseek::Reader, but that is simply more convenient. Here's how a
# direct call to this module would look:
#
#     my $vcf_reader = VNTRseek::Reader::vcfF->new(fh => $fh);
#
# where $fh is an IO::File file handle.

use Carp;
use Moose;
use IO::File;
use VCF;
use namespace::autoclean;

# use Vcf;

my @fieldnames = qw( Repeatid    RefSeq
    AltAlleleSeqs   Alleles     ReadCounts
    CopyGainLoss   ZSLabels MLLabel
    MLConfidence   TreeNodePercent  Filter
);

has 'fh' => (
    is       => 'rw',
    isa      => 'FileHandle',
    required => 1
);

has 'prefix' => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'VNTRPIPE_',
    required => 0
);

has 'vcf' => (
    is     => 'ro',
    writer => '_set_vcf',
    isa    => 'VCF'
);

has 'genome' => (
    is     => 'ro',
    writer => '_set_genome'
);

has 'ploidy' => (
    is     => 'ro',
    writer => '_set_ploidy'
);

has 'num_trs' => (
    is     => 'ro',
    writer => '_set_num_trs'
);

has 'num_vntrs' => (
    is     => 'ro',
    writer => '_set_num_vntrs'
);

has 'col_idx' => (
    is     => 'ro',
    isa    => 'HashRef',
    writer => '_set_col_idx'
);

has 'mlz' => (
    is     => 'ro',
    default => 0,
    writer => '_set_mlz'
);

sub BUILD {
    my $self = shift;

    my $vcf = VCF->new( fh => $self->fh );
    $self->_set_vcf($vcf);
    $self->vcf->parse_header();
    my $genome = $self->vcf->get_header_line( key => 'database' );
    croak "Bad Vcf format? Database line not found."
        unless ( @$genome == 1 );
    my $prefix = $self->prefix;
    $genome = $genome->[0]->[0]->{value};
    $genome =~ s/${prefix}(\w+)//;
    croak
        "Error getting genome/sample name. Do you need to set a prefix? ('prefix' currently set to '${prefix}')."
        unless ($genome);
    $self->_set_genome($1);

    my $num_trs = $self->vcf->get_header_line( key => 'numTRsWithSupport' );
    croak "Bad Vcf format? numTRsWithSupport line not found."
        unless ( @$num_trs == 1 );
    $num_trs = $num_trs->[0]->[0]->{value};
    $num_trs =~ s/"//g;
    $self->_set_num_trs($num_trs);

    my $num_vntrs = $self->vcf->get_header_line( key => 'numVNTRs' );
    croak "Bad Vcf format? numVNTRs line not found."
        unless ( @$num_vntrs == 1 );
    $num_vntrs = $num_vntrs->[0]->[0]->{value};
    $num_vntrs =~ s/"//g;
    $self->_set_num_vntrs($num_vntrs);

    unless ( $self->ploidy ) {
        my $ploidy = $self->vcf->get_header_line( key => 'ploidy' );

        if ( @$ploidy == 1 ) {
            $ploidy = $ploidy->[0]->[0]->{value};
            $ploidy =~ s/"//g;
            $self->_set_ploidy($ploidy);
        }
        else {
            # Set default ploidy of 2
            $self->_set_ploidy(2);
        }
    }

    my $is_mlz_processed = @{$self->vcf->get_header_line( key => 'FILTER', ID => 'ALE' )} > 0;
    if ( $is_mlz_processed ) {
        $self->_set_mlz(1);
    }

    my %col_idxs = (
        ID     => $self->vcf->get_column_index('ID'),
        REF    => $self->vcf->get_column_index('REF'),
        ALT    => $self->vcf->get_column_index('ALT'),
        FILTER => $self->vcf->get_column_index('FILTER'),
        FORMAT => $self->vcf->get_column_index('FORMAT'),
        GTYPE  => $self->vcf->get_column_index( $self->genome ),
    );
    $self->_set_col_idx( \%col_idxs );

    # # Skip until line 26 where the 1st record is.
    # until ( $self->fh->input_line_number() == 25 ) {
    #     $self->fh->getline;
    # }
}

sub next_var {
    my ( $self, %opts ) = @_;

    # return unless my $d_arr = $self->vcf->next_data_array;
    return unless my $line = $self->fh->getline;
    my $vcf_arr = $self->vcf->next_data_array($line);

    # For validating
    if ( $opts{validate} ) {
        my $x = $self->vcf->next_data_hash($line);
        my $gtype_err
            = $self->vcf->validate_gtype_field(
            $x->{gtypes}->{ $self->genome },
            $x->{ALT}, $x->{FORMAT}, );
        if ($gtype_err) {
            die "Genotype field validation error at line "
                . $self->fh->input_line_number()
                . ": $gtype_err\n";
        }

        my $filter_err = $self->vcf->validate_filter_field( $x->{FILTER} );
        if ($filter_err) {
            die "FILTER field validation error at line "
                . $self->fh->input_line_number()
                . ": $filter_err\n";
        }
    }

    my ( $trid, $refseq, $alt_seqs, $filter, $format, $gtype ) = (
        $vcf_arr->[ $self->col_idx->{ID} ],
        $vcf_arr->[ $self->col_idx->{REF} ],
        $vcf_arr->[ $self->col_idx->{ALT} ],
        $vcf_arr->[ $self->col_idx->{FILTER} ],
        $vcf_arr->[ $self->col_idx->{FORMAT} ],
        $vcf_arr->[ $self->col_idx->{GTYPE} ],
    );

    # Mandatory genotype tags
    # For now, genotypes are always unphased in VNTRseek output
    my @allele_seqs = split( ",", $alt_seqs );
    my @alleles = split(
        "/",
        $self->vcf->get_field(
            $gtype, $self->vcf->get_tag_index( $format, 'GT' )
        )
    );
    my @num_reads = split(
        ",",
        $self->vcf->get_field(
            $gtype, $self->vcf->get_tag_index( $format, 'SP' )
        )
    );
    my @num_copies = split(
        ",",
        $self->vcf->get_field(
            $gtype, $self->vcf->get_tag_index( $format, 'CGL' )
        )
    );

    # For MLZ-processed files
    my ( @zl, $mlz, $mlc, $mln, );

    if ( $self->mlz ) {
        my ( $zl_idx, $mlz_idx, $mlc_idx, $mln_idx ) = (
            $self->vcf->get_tag_index( $format, 'ZL' ),
            $self->vcf->get_tag_index( $format, 'MLZ' ),
            $self->vcf->get_tag_index( $format, 'MLC' ),
            $self->vcf->get_tag_index( $format, 'MLN' ),
        );

        @zl
            = ( $zl_idx == -1 )
            ? ()
            : split( ',', $self->vcf->get_field( $gtype, $zl_idx ) );
        $mlz
            = ( $mlz_idx == -1 )
            ? undef
            : $self->vcf->get_field( $gtype, $mlz_idx );
        $mlc
            = ( $mlc_idx == -1 )
            ? undef
            : $self->vcf->get_field( $gtype, $mlc_idx );
        $mln
            = ( $mln_idx == -1 )
            ? undef
            : $self->vcf->get_field( $gtype, $mln_idx );

        # If $mlz is set to '.' (missing value),
        # set all these values to undefined.
        if ( $mlz eq "." ) {
            ( $mlz, $mlc, $mln ) = (undef) x 3
        };
    }

    $trid =~ s/td//;

    # VNTRseek::Reader::var doesn't accept '.' in arrays
    # (this is by design)
    if ( $alleles[0] != 0 ) {
        shift @num_reads;
        shift @num_copies;
        shift @zl;
    }

    # use Data::Dumper;
    my %filter_hash = map { $_ => 1 } split( ";", $filter );

    # print Dumper(\%filter_hash) . "\n";

    my %args;
    @args{@fieldnames} = (
        $trid,
        $refseq,
        \@allele_seqs,
        \@alleles,
        \@num_reads,
        \@num_copies,
        \@zl,
        $mlz,
        $mlc,
        $mln,
        \%filter_hash
    );

    my $module = "VNTRseek::Reader::var";
    my $load = File::Spec->catfile( ( split( /::/, "$module.pm" ) ) );

    eval {
        require $load;
        1;
    } or do {
        croak "Could not load module '$module': $@\n" . "Exiting...\n";
    };
    my $var = $module->new(%args);
    $var->IsVNTR( @alleles > 2 || $alleles[1] > 0 );
    $var->IsMulti( @alleles > $self->ploidy );
    return $var;
}

__PACKAGE__->meta->make_immutable;

1;
