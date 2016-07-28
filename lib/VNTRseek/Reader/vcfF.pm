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
use namespace::autoclean;

# use Vcf;

my @fieldnames = qw( Repeatid    Alleles
    ReadCounts    CopyGainLoss   IsVNTR
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

has 'vcf' => ( is => 'ro', writer => '_set_vcf' );

has 'genome' => ( is => 'ro', writer => '_set_genome' );

sub BUILD {
    my $self = shift;

    # my $vcf = Vcf->new( fh => $self->fh )
    #     or croak "Error reading VCF file: $!\n";

    # $self->_set_vcf($vcf);
    # $self->vcf->parse_header();
    # my $g = $self->vcf->get_header_line( key => 'database' );
    # $g = $g->[0]->[0]->{"value"};
    # my $prefix = $self->prefix;
    # $g =~ s/$prefix//;
    # $self->_set_genome($g);
    my $genome;

    while ( my $line = $self->fh->getline ) {
        chomp $line;
        next
            unless ( $line =~ /^##database="(.*)"/ );
        my $prefix = $self->prefix;
        my $g      = $1;
        $g =~ s/$prefix//;
        $self->_set_genome($g);
        last;
    }
    croak "Bad Vcf format? Database line not found."
        unless $self->genome;

    # Skip until line 26 where the 1st record is.
    until ( $self->fh->input_line_number() == 25 ) {
        $self->fh->getline;
    }
}

sub next_var {
    my $self = shift;

    # return unless my $d_arr = $self->vcf->next_data_array;
    return unless my $line = $self->fh->getline;
    chomp $line;
    my @fields = split( "\t", $line );
    croak "Bad format in Vcf record on line "
        . $self->fh->input_line_number() . "\n"
        unless @fields == 10;
    my ( $trid, $subj_info ) = @fields[ 2, 9 ];
    my ( $gt, $sp, $cgl ) = split( ":", $subj_info );
    my @alleles    = split( "/", $gt ); # For now, genotypes are always unphased in VNTRseek output
    my @num_reads  = split( ",", $sp );
    my @num_copies = split( ",", $cgl );
    $trid =~ s/td//;

    # warn "TRID: $trid\n";
    my %args;
    @args{@fieldnames}
        = ( $trid, \@alleles, \@num_reads, \@num_copies );

    my $module = "VNTRseek::Reader::var";
    my $load = File::Spec->catfile((split(/::/,"$module.pm")));

    eval {
        require $load;
        1;
    } or do {
        croak "Could not load module '$module': $@\n" . "Exiting...\n";
    };
    return $module->new(%args);
}

__PACKAGE__->meta->make_immutable;

1;
