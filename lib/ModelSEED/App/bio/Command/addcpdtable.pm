package ModelSEED::App::bio::Command::addcpdtable;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Reads in table of compound data and adds them to the database" }
sub usage_desc { return "bio addcpdtable [ biochemistry id ] [filename] [options]"; }
sub options {
    return (
        ["namespace|c=s", "Name space for aliases added"],
        ["mergeto|m=s@", "Name space of identifiers used for merging compounds. Comma delimiter accepted."],
        ["matchbyname|n", "Use search names to match compounds"],
        ["separator|t=s", "Column separator for file. Default is tab"],
        ["addmergealias|g", "Add identifiers to merging namespace."],
	["checkforduplicates|f", "Force a check to report whether multiple compounds from the same file were merged together.  This is typically undesirable"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify a valid filename for compound table") unless(defined($args->[0]) && -e $args->[0]);
    #load table
    my $separator="\\\t";
    $separator = $opts->{separator}  if exists $opts->{separator};
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[0],$separator);

    ModelSEED::utilities::verbose("Loading ".$args->[1]);

    if(scalar(@{$tbl->{data}->[0]})<2){
	$tbl = ModelSEED::utilities::LOADTABLE($args->[0],"\\\;");
#	$self->usage_error("Not enough columns in table, consider using a different separator");
    }

    #set namespace
    if (!defined($opts->{namespace})) {
	$opts->{namespace} = $bio->msStoreID();
	print STDERR "Warning: no namespace passed.  Using biochemistry name by default: ".$opts->{namespace}."\n";
    }

    #processing table
    my $mergeto = [];
    if (defined($opts->{mergeto})) {
	$mergeto = ModelSEED::utilities::translateArrayOptions({
	    option => $opts->{mergeto},
	    delimiter => ","});
    }

    #creating namespaces if they don't exist
    if(!$bio->queryObject("aliasSets",{name => $opts->{namespace},attribute=>"compounds"})){
	$bio->add("aliasSets",{
	    name => $opts->{namespace},
	    source => $opts->{namespace},
	    attribute => "compounds",
	    class => "Compound"});
    }

    foreach my $merge (@$mergeto){
	next if $bio->queryObject("aliasSets",{name => $merge, attribute=>"compounds"});
	$bio->add("aliasSets",{
	    name => $merge,
	    source => $merge,
	    attribute => "compounds",
	    class => "Compound"});
    }

    foreach my $common ("name","searchname"){
	next if $bio->queryObject("aliasSets",{name => $common, attribute=>"compounds"});
	$bio->add("aliasSets",{
	    name => $common,
	    source => $common,
	    attribute => "compounds",
	    class => "Compound"});
    }

    my $headingTranslation = {
    	name => "names",
	database => "id",
	uncharged_formula => "unchargedFormula",
    };
    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
        my $cpdData = {
        	namespace => $opts->{namespace},
        	matchbyname => $opts->{matchbyname},
        	mergeto => $mergeto,
		addmergealias => $opts->{addmergealias}
        };
        for (my $j=0; $j < @{$tbl->{headings}}; $j++) {
            my $heading = lc($tbl->{headings}->[$j]);
            if (defined($headingTranslation->{$heading})) {
            	$heading = $headingTranslation->{$heading};
            }
            if ($heading eq "names") {
            	$cpdData->{$heading} = [ map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } split(/\|/,$tbl->{data}->[$i]->[$j])];
            } else {
            	$cpdData->{$heading} = [ map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } $tbl->{data}->[$i]->[$j]];
            }
        }
        my $cpd = $bio->addCompoundFromHash($cpdData);
    }

    if(defined($opts->{checkforduplicates})){
	my $aliases = $bio->queryObject("aliasSets",{ name => $opts->{namespace}, attribute => "compounds" })->aliases();
	my %uuidAliasHash=();
	
	foreach my $alias (keys %$aliases){
	    foreach my $uuid (@{$aliases->{$alias}}){
		$uuidAliasHash{$uuid}{$alias}=1;
	    }
	}

	foreach my $uuid ( grep { scalar( keys %{$uuidAliasHash{$_}} )>1 } keys %uuidAliasHash ){
	    print STDERR "Multiple compounds merged to a single UUID (".$uuid."): ".join("|",keys %{$uuidAliasHash{$uuid}})."\n";
	}
    }

	$self->save_bio($bio);
}

1;
