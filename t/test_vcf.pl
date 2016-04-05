#!/usr/bin/env perl

#** @file   test_vcf.pl
# @brief    Test reading VNTRs from a VNTRseek VCF file
# @author   Yözen Hernández
# @date     Apr 05, 2016
#*

use Modern::Perl;
use Moose;
use FindBin;
use lib ".";
use Test::More tests => 2;

BEGIN {
    use_ok('VNTRseek::Reader');
}
require_ok('VNTRseek::Reader');

########
# Main #
########
die "Usage: $0 <vcf file 1> ... <vcf file n>\n"
    unless @ARGV > 0;

my $organism = "Homo sapiens";
my $study    = "Human VNTRs";

# Read in each VCF file from command line (when this is part of the webapp, from form)
while ( my $vcf_file = shift ) {
    my $vcf = VNTRseek::Reader->get_file_reader(
        reader => "vcf",
        file   => $vcf_file
    );

    # Check if this genome is in the DB
    my $genome = $vcf->genome;

    while ( my $tr = $vcf->next_var ) {

        # Get the TR and add to database if not found
        # Get all detected alleles, add to db if not found
        my $trid = $tr->Repeatid;
        my @cgl  = @{ $tr->CopyGainLoss };
        my @rc   = @{ $tr->ReadCounts };

        print "For tr $trid, found allele(s): ";
        for ( my $v = 0; $v < scalar @cgl; ++$v ) {
            print $cgl[$v] . " (" . $rc[$v] . " reads) ";
        }
        print "\n";
    }
}