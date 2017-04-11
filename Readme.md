# VNTRseekHelpers

Helper modules for reading input/output files produced by the VNTRseek
pipeline.

So far, these modules are only used for reading .seq (input) and .vcf
(output) files.

# Basic usage

## VNTRseek::Reader

Class used by a client to access one of [possibly] many
file readers. A call to this class looks like:

```perl
my $file_reader = VNTRseek::Reader->get_file_reader($format, $file)
```

where $format is a string denoting the format (currently only "seq"
and "vcf" are supported) and $file is the full or relative path to a
file of that format. The file reader can then be used to access the
file contents.

## VNTRseek::Reader::seqF

```perl
my $seq_reader = VNTRseek::Reader->get_file_reader("seq", $file);
while (my $entry = $seq_reader->next_seq) {
    #...
    # See documentation on VNTRseek::Reader::seq
}
```

You can also call this module directly, without needing to use
VNTRseek, but that is simply more convenient. Here's how a
direct call to this module would look:

```perl
    my $seq_reader = VNTRseek::Reader::seqF->new(fh => $fh);
```

where `$fh` is an `IO::File` file handle.

## VNTRseek::Reader::seq

This class is meant to be accessed via the `VNTRseek::Reader::seqF`
module, but can be accessed directly to build such entries.

Apart from having built in accessors for the various fields in a
.seq file record, you can also print a whole record at once,
in a CSV format as follows:

```perl
# Prints line to STDOUT
print $seq_record;
# Prints line to file handle pointed to by $fh
print $fh $seq_record;
```

You can access specific parts of the record. Examples:

```perl
my $rid = $self->Repeatid;
my $start = $self->FirstIndex;
my $stop = $self->LastIndex;
my $cn = $self->CopyNumber;
my $name = $self->FastaHeader;
my $pattern = $self->Pattern;
my $percent_conserived = $self->Conserved;
```

## VNTRseek::Reader::vcfF

```perl
my $vcf_reader = VNTRseek::Reader->get_file_reader("vcf", $file);
while (my $entry = $vcf_reader->next_var) {
    #...
    # See documentation on VNTRseek::Reader::var
}
```

You can also call this module directly, without needing to use
VNTRseek::Reader, but that is simply more convenient. Here's how a
direct call to this module would look:

```perl
    my $vcf_reader = VNTRseek::Reader::vcfF->new(fh => $fh);
```

where `$fh` is an `IO::File` file handle.

## VNTRseek::Reader::var

This class is meant to be accessed via the `VNTRseek::Reader::vcfF`
module, but can be accessed directly to build such entries.

Apart from having built in accessors for the various fields in a
.vcf file record, you can also print a whole record at once,
in a CSV format as follows:

```perl
my $vcf_record = $vcf_reader->next_var;
# Prints line to STDOUT
print $vcf_record;
# Prints line to file handle pointed to by $fh
print $fh $vcf_record;
```

You can access specific parts of the record. Examples:

```perl
my $rid = $vcf_record->Repeatid;
my $refseq = $vcf_record->RefSeq;
my @allele_seqs = @{ $vcf_record->AlleleSeqs };
my @alleles = @{ $vcf_record->Alleles };
my @rcounts = @{ $vcf_record->ReadCounts };
my @cgl = @{ $vcf_record->CopyGainLoss };
```

Note that `AlleleSeqs` (or the corresponding `get_allele_seqs`) does not include the reference sequence. If the genotype is homozygous reference (0/0), it will contain one sequence, '.'.

For convenience, accessors are available that return a list or a scalar, depending on the calling context:

```perl
my @cgl = $vcf_record->get_cgls;                 # Get the copy gain/loss as an array
my $cgl_str = $vcf_record->get_cgls;             # Get as a comma-separated string
my $cgl_str = $vcf_record->get_cgls(sep => "\t"); # Same, but use "\t" as the separator
```

## Known issues

- VNTRseek::Reader::vcfF does not currently use the existing Perl VCF module, so it cannot properly validate VCF files. Really, this module should be a wrapper for VCF.pm.