#!/usr/bin/perl -w
use strict;
use IPC::Open3;

my $SourcePath = $ARGV[0];
my $DestinationPath = $ARGV[1];
my $MarvinBeansPath = $ARGV[2];
my $OutputFormat = $ARGV[3];
$MarvinBeansPath .= "bin/cxcalc";

if(!$SourcePath || !-d $SourcePath || !$DestinationPath || !-d $DestinationPath || !$MarvinBeansPath){
    print "./ChargeMolfiles.pl <directory of mol files> <Directory for output files> <Path for MarvinBeans Software (ie ~/Software/MarvinBeans/)> <Output format [mol|inchi]>\n";
    exit(0);
}

if(!-f $MarvinBeansPath){
    print "./ChargeMolfiles.pl <directory of mol files> <Directory for output files> <Path for MarvinBeans Software (ie ~/Software/MarvinBeans/)> <Output format [mol|inchi]>\n";
    print STDERR "Cannot find cxcalc executable, double-check path for MarvinBeans software:\n".$MarvinBeansPath."\n";
    exit(0);
}

if(!$OutputFormat || ($OutputFormat ne "mol" && $OutputFormat ne "inchi")){
    print STDERR "No output format determined, or usable, reverting to generating mol files by default\n";
    $OutputFormat="mol";
}

opendir(my $dh, $SourcePath) || die "can't opendir $SourcePath: $!";
my %Files = map {$SourcePath.$_=>1} grep { /\.$OutputFormat$/ } readdir($dh);
closedir $dh;

my($wtr, $rdr, $err, $pid);
use Symbol 'gensym'; $err = gensym;
my ($test,$out,$rdrstr,$errstr,$KEGG);

my $Command = $MarvinBeansPath." -N hi majorms -H 7 -f ".$OutputFormat.":-a ";

foreach my $file(sort keys %Files){
    my $stub=substr($file,rindex($file,'/')+1,(length($file)-rindex($file,'/'))-(length($file)-rindex($file,'.')+1));
    print $stub,"\n";

    #Run generating Mol files
    $pid=open3($wtr, $rdr, $err,$Command.$file);
    waitpid($pid, 0);

    $rdrstr="";
    while(<$rdr>){
	$rdrstr.=$_;
    }
    $errstr="";
    while(<$err>){
	$errstr.=$_;
    }

    if(length($rdrstr)>0){
	open(OUT, "> ".$DestinationPath.$stub.".".$OutputFormat);
	print OUT $rdrstr;
	close OUT;
    }

    if(length($errstr)>0){
	open(OUT, "> ".$DestinationPath.$stub.".".$OutputFormat.".err");
	print OUT $errstr;
	close OUT;
    }
}
