#!/usr/bin/perl -w
$|++;
use strict;
use SeedUtils;
use File::Path;
use ModelSEED::Client::SAP;

my $directory = $ARGV[0];
my $sap = ModelSEED::Client::SAP->new();
my $genomeHash = $sap->all_genomes({
	-complete => 1,
	-prokaryotic => 1
});
my $count = 0;
foreach my $genome (keys(%{$genomeHash})) {
	print "Processing ".$count." ".$genome." of ".keys(%{$genomeHash})."\n";
	$count++;
	if (-e $directory."/".$genome."/fasta.nsq") {
		my $genomeHash = $sap->genome_contigs({
			-ids => [$genome]
		});
		if (defined($genomeHash->{$genome})) {
			File::Path::mkpath $directory."/".$genome."/";
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
			unlink($directory."/".$genome."/fasta");
		}
	}
}
print "Complete!\n";