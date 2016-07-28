#** @file seqF.pm
# @brief    Reader module for .seq files
# @author   Yözen Hernández
# @date     Oct 20, 2014
#*

package VNTRseek::Reader::seqF;

#** @class VNTRseek::Reader::seqF
# A class for reading .seq files used as input for VNTRseek.
#
# Example use:
#
#     my $seq_reader = VNTRseek::Reader->get_file_reader("seq", $file);
#     while (my $entry = $seq_reader->next_seq) { ... }
#
# You can also call this module directly, without needing to use
# VNTRseek, but that is simply more convenient. Here's how a
# direct call to this module would look:
#
#     my $seq_reader = VNTRseek::Reader::seqF->new(fh => $fh);
#
# where $fh is an IO::File file handle.

use strict;
use warnings;
use 5.010;
use Carp;
use Moose;
use IO::File;
use namespace::autoclean;

my @fieldnames = qw( Repeatid FirstIndex
    LastIndex         CopyNumber
    FastaHeader       FlankingLeft1000
    Pattern           ArraySequence
    FlankingRight1000 Conserved
);

has 'fh' => (
    is       => 'rw',
    isa      => 'FileHandle',
    required => 1
);

sub BUILD {
    my $self = shift;
    my $expected_header
        = "Repeatid,FirstIndex,LastIndex,CopyNumber,FastaHeader,FlankingLeft1000,Pattern,ArraySequence,FlankingRight1000,Conserved";

    # Advance one line to pass header
    my $header = $self->fh->getline;
    chomp $header;
    croak "Invalid seq file format: unexpected header."
        unless $header =~ /$expected_header/;
}

sub next_seq {
    my $self = shift;
    return unless my $line = $self->fh->getline;
    $line =~ s/[\r\n]+/\n/;
    chomp $line;
    my @fields = split ",", $line;
    my %args;
    @args{@fieldnames} = @fields;

    my $module = "VNTRseek::Reader::seq";
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
