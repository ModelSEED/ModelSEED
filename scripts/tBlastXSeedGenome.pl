#!/usr/bin/perl -w
$|++;
use strict;
use SeedUtils;
use File::Path;
use ModelSEED::Client::SAP;

my $genome = $ARGV[0];
my $directory = $ARGV[1];
my $queryfile = $ARGV[2];
my $sap = ModelSEED::Client::SAP->new();
my $genomeHash = $sap->genome_contigs({
	-ids => [$genome]
});
my $query = [];
open (ONE, "<", $queryfile);
while (my $Line = <ONE>) {
	$Line =~ s/\r//;
	chomp($Line);
	push(@{$query},[split(/\t/,$Line)]);
}
close(ONE);
my $results;
if (defined($genomeHash->{$genome})) {
	my $contigHash = $sap->contig_sequences({
		-ids => $genomeHash->{$genome}
	});
	File::Path::mkpath $directory."/".$genome."/";
	open ( TWO, ">", $directory."/".$genome."/fasta");
	foreach my $contig (keys(%{$contigHash})) {
		my $fastaString = SeedUtils::create_fasta_record($contig,0,$contigHash->{$contig});
		print TWO $fastaString;
	}
	close(TWO);
	system("/vol/rast-bcr/2010-1124/linux-rhel5-x86_64/bin/formatdb -i ".$directory."/".$genome."/fasta -p F"); 
	open(THREE, ">".$directory."/".$genome."/query");
	#for (my $i=0; $i < 1; $i++) {
	for (my $i=0; $i < @{$query}; $i++) {
		my $fastaString = SeedUtils::create_fasta_record($query->[$i]->[0],undef, $query->[$i]->[1]);
		print THREE $fastaString;
	}
	close(THREE);
	system("/vol/rast-bcr/2010-1124/linux-rhel5-x86_64/bin/blastall -i ".$directory."/".$genome."/query -d ".$directory."/".$genome."/fasta -p tblastx -FF -e 1.0e-5 -m 8 -o ".$directory."/".$genome."/query.out");
	my $output = [];
	open (FOUR, "<", $directory."/".$genome."/query.out");
	while (my $Line = <FOUR>) {
		$Line =~ s/\r//;
		chomp($Line);
		my $lineArray = [split(/\t/,$Line)];
		if (defined($lineArray->[11])) {
			$results->{$query->[$i]}->{$lineArray->[1]} = {
				identity => $lineArray->[2],
				"length" => $lineArray->[3],
				qstart => $lineArray->[6],
				qend => $lineArray->[7],
				tstart => $lineArray->[8],
				tend => $lineArray->[9],
				evalue => $lineArray->[10],
				bitscore => $lineArray->[11],
			}
		}
	}
	close(FOUR);
}