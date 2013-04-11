package ModelSEED::App::bio::Command::addcpdtable;
use strict;
use common::sense;
use ModelSEED::utilities qw( args verbose set_verbose translateArrayOptions);
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Reads in table of compound data and adds them to the database" }
sub usage_desc { return "bio addcpdtable [< biochemistry | biochemistry] [filename] [options]"; }
sub opt_spec {
    return (
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["namespace|c:s", "Name space for aliases added"],
        ["mergeto|m:s@", "Name space of identifiers used for merging compounds. Comma delimiter accepted."],
        ["matchbyname|n", "Use search names to match compounds"],
        ["verbose|v", "Print verbose status information"],
	["separator|t:s", "Column separator for file. Default is tab"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
	["addmergealias|g", "Add identifiers to merging namespace."],
	["checkforduplicates|f", "Force a check to report whether multiple compounds from the same file were merged together.  This is typically undesirable"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();

    $self->usage_error("Must specify a biochemistry to use") unless $args->[0];
    my ($biochemistry, $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);
    $self->usage_error("Must specify a valid filename for compound table") unless(defined($args->[1]) && -e $args->[1]);

    #verbosity
    set_verbose(1) if $opts->{verbose};

    #load table
    my $separator="\\\t";
    $separator = $opts->{separator}  if exists $opts->{separator};
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[1],$separator);

    if(scalar(@{$tbl->{data}->[0]})<2){
	$tbl = ModelSEED::utilities::LOADTABLE($args->[1],"\\\;");
#	$self->usage_error("Not enough columns in table, consider using a different separator");
    }

    #set namespace
    if (!defined($opts->{namespace})) {
	$opts->{namespace} = $args->[0];
	print STDERR "Warning: no namespace passed.  Using biochemistry name by default: ".$opts->{namespace}."\n";
    }

    #processing table
    my $mergeto = [];
    if (defined($opts->{mergeto})) {
	$mergeto = translateArrayOptions({
	    option => $opts->{mergeto},
	    delimiter => ","});
    }

    #creating namespaces if they don't exist
    if(!$biochemistry->queryObject("aliasSets",{name => $opts->{namespace},attribute=>"compounds"})){
	$biochemistry->add("aliasSets",{
	    name => $opts->{namespace},
	    source => $opts->{namespace},
	    attribute => "compounds",
	    class => "Compound"});
    }

    foreach my $merge (@$mergeto){
	next if $biochemistry->queryObject("aliasSets",{name => $merge, attribute=>"compounds"});
	$biochemistry->add("aliasSets",{
	    name => $merge,
	    source => $merge,
	    attribute => "compounds",
	    class => "Compound"});
    }

    foreach my $common ("name","searchname"){
	next if $biochemistry->queryObject("aliasSets",{name => $common, attribute=>"compounds"});
	$biochemistry->add("aliasSets",{
	    name => $common,
	    source => $common,
	    attribute => "compounds",
	    class => "Compound"});
    }

    my $headingTranslation = {
    	name => "names",
	database => "id"
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
        my $cpd = $biochemistry->addCompoundFromHash($cpdData);
    }

    if(defined($opts->{checkforduplicates})){
	my $aliases = $biochemistry->queryObject("aliasSets",{ name => $opts->{namespace}, attribute => "compounds" })->aliases();
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

    #Saving biochemistry
    if (defined($opts->{saveas})) {
        $ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
        verbose "Saving biochemistry with new compounds as ".$ref."...\n";
	$biochemistry->name($opts->{saveas});
    	$store->save_object($ref,$biochemistry);
    } elsif (!defined($opts->{dry}) || $opts->{dry} == 0) {
        verbose "Saving over original biochemistry with new compounds...\n";
        $store->save_object($ref,$biochemistry);
    }
}

1;
