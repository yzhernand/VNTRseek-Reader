# VNTRseekHelpers

Helper modules for reading input/output files produced by the VNTRseek
pipeline.

So far, these modules are only used for reading .seq (input) and .vcf
(output) files.

# Basic usage

## VNTRseekHelpers::Reader

Class used by a client to access one of [possibly] many
file readers. A call to this class looks like:

```perl
my $file_reader = VNTRseekHelpers::Reader->get_file_reader($format, $file)
```

where $format is a string denoting the format (currently only "seq"
and "vcf" are supported) and $file is the full or relative path to a
file of that format. The file reader can then be used to access the
file contents.

## VNTRseekHelpers::Reader::seqF

```perl
my $seq_reader = VNTRseekHelpers::Reader->get_file_reader("seq", $file);
while (my $entry = $seq_reader->next_seq) {
    #...
    # See documentation on VNTRseekHelpers::Reader::seq
}
```

You can also call this module directly, without needing to use
VNTRseekHelpers, but that is simply more convenient. Here's how a
direct call to this module would look:

```perl
    my $seq_reader = VNTRseekHelpers::Reader::seqF->new(fh => $fh);
```

where `$fh` is an `IO::File` file handle.

## VNTRseekHelpers::Reader::seq

This class is meant to be accessed via the `VNTRseekHelpers::Reader::seqF`
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

## VNTRseekHelpers::Reader::vcfF

```perl
my $vcf_reader = VNTRseekHelpers::Reader->get_file_reader("vcf", $file);
while (my $entry = $vcf_reader->next_var) {
    #...
    # See documentation on VNTRseekHelpers::Reader::var
}
```

You can also call this module directly, without needing to use
VNTRseekHelpers::Reader, but that is simply more convenient. Here's how a
direct call to this module would look:

```perl
    my $vcf_reader = VNTRseekHelpers::Reader::vcfF->new(fh => $fh);
```

where `$fh` is an `IO::File` file handle.

## VNTRseekHelpers::Reader::var

This class is meant to be accessed via the `VNTRseekHelpers::Reader::vcfF`
module, but can be accessed directly to build such entries.

Apart from having built in accessors for the various fields in a
.vcf file record, you can also print a whole record at once,
in a CSV format as follows:

```perl
# Prints line to STDOUT
print $vcf_record;
# Prints line to file handle pointed to by $fh
print $fh $vcf_record;
```

You can access specific parts of the record. Examples:

```perl
my $rid = $self->Repeatid;
my @alleles = @{ $self->Alleles };
my @rcounts = @{ $self->ReadCounts };
my @cgl = @{ $self->CopyGainLoss };
```
