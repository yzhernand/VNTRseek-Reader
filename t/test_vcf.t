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
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use lib "lib";
use Test::More tests => 10;

BEGIN {
    use_ok('VNTRseek::Reader');
}
require_ok('VNTRseek::Reader');

########
# Main #
########

say "***** Simple VCF test *****";

my $organism  = "Homo sapiens";
my $study     = "Human VNTRs";
my $test_file = "t/test.vcf";

# Read in each VCF file from command line (when this is part of the webapp, from form)
my $vcf = VNTRseek::Reader->get_file_reader(
    reader => "vcf",
    file   => $test_file,
    ploidy => 2
);

# Check if this genome is in the DB
my $genome = $vcf->genome;
is( $genome, "test_results", 'simple_genome_name' );

my ( $tr_count, $vntr_count ) = ( 0, 0 );

# TODO Add tests!
# while ( my $tr = $vcf->next_var(refseq => 1) ) {
while ( my $tr = $vcf->next_var() ) {
    $tr_count++;
    $vntr_count += $tr->IsVNTR;

    # print "$tr\n";

    # Get the TR and add to database if not found
    # Get all detected alleles, add to db if not found
    # my $trid = $tr->Repeatid;
    # my $refseq = $tr->get_refseq;
    # my @allele_seqs = $tr->get_altseqs;
    # my @cgl  = $tr->get_cgls;
    # my @rc   = $tr->get_rcs;
    # my @zsl  = $tr->get_zslabels;

# print "For tr $trid, found allele(s): ";
# for ( my ($v, $seqi) = (0, 0); $v < scalar @cgl; ++$v ) {
#     my $seq = ($cgl[$v] == 0) ? $refseq : $allele_seqs[$seqi++];
#     print $cgl[$v] . " (" . $rc[$v] . " reads, seq: '" . $seq . "') ";
# }
# print $tr . "\n";
# print "Reference seen?: " . (($tr->RefTyped) ? "Yes" : "No" ) . "\n";
# print "Filter passed?: " . (($tr->filter_passed) ? "Yes" : "No, failed: " . $tr->Filter ) . "\n";
# print "Is multi?: " . (($tr->IsMulti) ? "Yes" : "No" ) . "\n";
}

is( $tr_count,   $vcf->num_trs,   'simple_tr_count' );
is( $vntr_count, $vcf->num_vntrs, 'simple_vntr_count' );

say "***** Large VCF test *****";
my $large_fh = new IO::Uncompress::Gunzip "t/large.vcf";
ok( $large_fh, "large_vcf_opened" );

$vcf = VNTRseek::Reader->get_file_reader(
    reader => "vcf",
    fh     => $large_fh,
    ploidy => 2
);

( $tr_count, $vntr_count ) = ( 0, 0 );
my $singleton_count = 0;
while ( my $tr = $vcf->next_var() ) {
    $tr_count++;
    $vntr_count += $tr->IsVNTR;
    next unless ( $tr->filter_passed );
    $singleton_count++;

    # print "$tr\n"

    # Get the TR and add to database if not found
    # Get all detected alleles, add to db if not found
    # my $trid = $tr->Repeatid;
    # my $refseq = $tr->get_refseq;
    # my @allele_seqs = $tr->get_altseqs;
    # my @cgl  = $tr->get_cgls;
    # my @rc   = $tr->get_rcs;
    # my @zsl  = $tr->get_zslabels;

# print "For tr $trid, found allele(s): ";
# for ( my ($v, $seqi) = (0, 0); $v < scalar @cgl; ++$v ) {
#     my $seq = ($cgl[$v] == 0) ? $refseq : $allele_seqs[$seqi++];
#     print $cgl[$v] . " (" . $rc[$v] . " reads, seq: '" . $seq . "') ";
# }
# print $tr . "\n";
# print "Reference seen?: " . (($tr->RefTyped) ? "Yes" : "No" ) . "\n";
# print "Filter passed?: " . (($tr->filter_passed) ? "Yes" : "No, failed: " . $tr->Filter ) . "\n";
# print "Is multi?: " . (($tr->IsMulti) ? "Yes" : "No" ) . "\n";
}

is( $tr_count,        $vcf->num_trs,   'large_tr_count' );
is( $vntr_count,      $vcf->num_vntrs, 'large_vntr_count' );
is( $singleton_count, "164994",        'large_singleton_count' );

say "***** MLZ VCF test *****";
my $mlz_fh = new IO::Uncompress::Gunzip "t/mlZ.vcf";
ok( $mlz_fh, "mlz_vcf_opened" );

$vcf = VNTRseek::Reader->get_file_reader(
    reader => "vcf",
    fh     => $mlz_fh,
    ploidy => 2
);

( $tr_count, $vntr_count, $singleton_count ) = ( 0, 0, 0 );
my $err_count    = 0;
my $no_mlz_count = 0;
my %mlz_hash;
while ( my $tr = $vcf->next_var() ) {
    $tr_count++;
    $vntr_count += $tr->IsVNTR;
    $err_count++ if ( $tr->Filter->{ALE} );
    next if ( $tr->Filter->{SC} );
    $singleton_count++;
    if ( defined $tr->MLLabel ) {
        $mlz_hash{ $tr->MLLabel }++;
    }
    else {
        $no_mlz_count++;
    }

    # print "$tr\n"

    # Get the TR and add to database if not found
    # Get all detected alleles, add to db if not found
    # my $trid = $tr->Repeatid;
    # my $refseq = $tr->get_refseq;
    # my @allele_seqs = $tr->get_altseqs;
    # my @cgl  = $tr->get_cgls;
    # my @rc   = $tr->get_rcs;
    # my @zsl  = $tr->get_zslabels;

# print "For tr $trid, found allele(s): ";
# for ( my ($v, $seqi) = (0, 0); $v < scalar @cgl; ++$v ) {
#     my $seq = ($cgl[$v] == 0) ? $refseq : $allele_seqs[$seqi++];
#     print $cgl[$v] . " (" . $rc[$v] . " reads, seq: '" . $seq . "') ";
# }
# print $tr . "\n";
# print "Reference seen?: " . (($tr->RefTyped) ? "Yes" : "No" ) . "\n";
# print "Filter passed?: " . (($tr->filter_passed) ? "Yes" : "No, failed: " . $tr->Filter ) . "\n";
# print "Is multi?: " . (($tr->IsMulti) ? "Yes" : "No" ) . "\n";
}

# use Data::Dumper;
# print Dumper( \%mlz_hash );
# TODO Verify no_mlz count, indistinguishable/singleton
# counts, error/multi counts, and expected genotypes/results
is($mlz_hash{HOM}, "137357", 'mlz_homozygous_count');
is($mlz_hash{HET}, "20898", 'mlz_heterozygous_count')
