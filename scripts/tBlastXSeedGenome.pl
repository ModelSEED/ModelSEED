#!/usr/bin/perl -w
$|++;
use strict;
use SeedUtils;
use File::Path;
use ModelSEED::Client::SAP;
my $genome = $ARGV[0];
my $directory = $ARGV[1];
my $queryfile = $ARGV[2];
my $output = $ARGV[3];
my $sap = ModelSEED::Client::SAP->new();
File::Path::mkpath $directory."/temp/";
my ($in, $filename) = File::Temp::tempfile("XXXXXXX",DIR => $directory."/temp/");
open (ONE, "<", $queryfile);
while (my $Line = <ONE>) {
	my $queryLine = [split(/\t/,$Line)];
	my $fastaString = SeedUtils::create_fasta_record($queryLine->[0],undef, $queryLine->[1]);
	print $in $fastaString;
}
close(ONE);
close($in);
my $genomes = [$genome];
if ($genome eq "ALL") {
	my $genomeHash = $sap->all_genomes({
		-complete => 1,
		-prokaryotic => 1
	});
	foreach my $genome (keys(%{$genomeHash})) {
		push(@{$genomes},$genome);
	}
}
open (FOUR, "<", $output);
print FOUR "Query\tContig\tIdentity\tLength\tMismatchCount\tGapCount\tQStart\tQEnd\tTStart\tTEnd\tEValue\tBitScore\n";
for (my $i=0; $i < @{$genomes}; $i++) {
	my ($out, $fileout) = File::Temp::tempfile("XXXXXXX",DIR => $directory."/temp/");
	close($out);
	system("/vol/rast-bcr/2010-1124/linux-rhel5-x86_64/bin/blastall -i ".$filename." -d ".$directory."/".$genomes->[$i]."/fasta -p tblastn -FF -e 1.0e-3 -m 8 -o ".$fileout);
	open (FOUR, "<", $fileout);
	while (my $Line = <FOUR>) {
		$Line =~ s/\r//;
		chomp($Line);
		print $Line."\n";
	}
}
close(FOUR);