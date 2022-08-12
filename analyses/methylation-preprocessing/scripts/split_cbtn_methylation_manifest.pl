#!/usr/bin/perl -w
use strict;
use File::Basename;

if (!$ARGV[1]) {
	print "\nsplit_cbtn_methylation_manifest.pl <manifest_file> <number of sample to split by>\n\n";
	exit(1);
}

my $manifest = $ARGV[0]; # file name: manifest_methylation_CBTN_20220410.csv
my $num_of_samples = $ARGV[1]; # example: 100

# manifest basename string without extension
my $basename = basename($manifest);
$basename =~ /(.*)\.csv$/;
$basename = $1;

# get unique sample IDs ("Kids First Biospecimen ID" column 13)
my %sample_ids;
open (IN, $manifest) or die $!;
while(<IN>) {
	chomp;
	if (/^id/) { 
		next;
	}
	my @F = split(/\,/, $_);
	$sample_ids{$F[12]} = $F[12];
}
close IN; 

# write sample IDs to file
my $sample_ids_file = "$basename.ids";
open (OUT, ">$sample_ids_file") or die $!;
foreach (keys %sample_ids) {
	print OUT "$_\n";
}
close OUT;

# split sample into segment files
system "split -l $num_of_samples $sample_ids_file segment";

# write split manifests into segment files
my $counter = 0;
foreach my $segment_file (<segment*>) {
	$counter++;
	my %segment_ids;
	open (IN, $segment_file) or die $!;
	while (<IN>) {
		chomp;
		$segment_ids{$_} = $_;
	}
	close IN;
	open (OUT, ">$basename.$counter.csv") or die $!;
	open(IN, $manifest) or die $!;
	while (<IN>) {
		chomp;
		if(/^id/) {
			print OUT "$_\n";
			next;
		}
		my @F = split(/\,/, $_);
		if ($segment_ids{$F[12]}) {
			print OUT "$_\n";
		}
	}
	close IN; 
	close OUT;
}

system "rm -f segment*";

exit(0);
