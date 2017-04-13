#!/usr/bin/env perl

#** @file   test_vcf.pl
# @brief    Test reading VNTRs from a VNTRseek VCF file
# @author   Yözen Hernández
# @date     Apr 05, 2016
#*

use 5.010;
use strict;
use warnings;
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
# die "Usage: $0 <vcf file 1> ... <vcf file n>\n"
#     unless @ARGV > 0;

my $organism = "Homo sapiens";
my $study    = "Human VNTRs";
my $test_file = "t/test.vcf";

# Read in each VCF file from command line (when this is part of the webapp, from form)
my $vcf = VNTRseek::Reader->get_file_reader(
    reader => "vcf",
    file   => $test_file
);

# Check if this genome is in the DB
my $genome = $vcf->genome;

while ( my $tr = $vcf->next_var ) {

    # Get the TR and add to database if not found
    # Get all detected alleles, add to db if not found
    my $trid = $tr->Repeatid;
    my $refseq = $tr->get_refseq;
    my @allele_seqs = $tr->get_allele_seqs;
    my @cgl  = $tr->get_cgls;
    my @rc   = $tr->get_rcs;

    print "For tr $trid, found allele(s): ";
    for ( my ($v, $seqi) = (0, 0); $v < scalar @cgl; ++$v ) {
        my $seq = ($cgl[$v] == 0) ? $refseq : $allele_seqs[$seqi++];
        print $cgl[$v] . " (" . $rc[$v] . " reads, seq: '$seq') ";
    }
    print "\n";
}
