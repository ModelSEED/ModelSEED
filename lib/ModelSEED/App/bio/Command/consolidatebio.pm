package ModelSEED::App::bio::Command::consolidatebio;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
use ModelSEED::utilities qw( verbose set_verbose );
sub abstract { return "Consolidates a single biochemistry into a nonredundant set" }
sub usage_desc { return "bio consolidatebio [ < biochemistry | biochemistry ]"; }
sub opt_spec {
    return (
	["mergevia|m:s", "Name of aliases used to merge compounds"],
	["namespace|n:s", "Default namespace for printing identifiers"],
    	["noaliastransfer|t", "Do not transfer aliases to merged compound"],
    	["verbose|v", "Print messages with progress"],
        ["saveas|a:s", "New name the merged biochemistry should be saved to"],
        ["saveover|s", "Save results as original biochemistry"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Must specify a biochemistry to use") unless(defined($args->[0]));

    $|=1;

    if ($opts->{verbose}) {
        set_verbose(1);
    	delete $opts->{verbose};
    }

    if (!defined($opts->{saveas}) && !defined($opts->{saveover})){
	verbose("Neither the saveas or saveover options were used\nThis run will therefore be a dry run and the biochemistry will not be saved\n");
    }

    if(!defined($opts->{namespace})){
	verbose("A namespace was not passed, and therefore compounds will be compared directly based on their names\n");
    }

    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);

    my $new_name="Test";
    $new_name = $opts->{saveas} if defined($opts->{saveas});
    my $new_biochemistry=$store->create("Biochemistry",{name => $new_name});

    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,$ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);

    print "Using: ",$biochemistry->name(),"\n";

    #Add empty aliasSets
    if(!defined($opts->{noaliastransfer})){
	#check to see if desired matching namespace actually exists
	my $has_namespace=0;
	foreach my $set (@{$biochemistry->aliasSets()}){
	    my $new_set=ModelSEED::MS::AliasSet->new({name=>$set->name(),source=>$set->source(),attribute=>$set->attribute(),class=>$set->class()});
	    $new_biochemistry->add("aliasSets",$new_set);
	    if($set->name() eq $opts->{namespace}){
		$has_namespace=1;
	    }
	}
	$self->usage_error("Namespace ".$opts->{namespace}." not found") unless $has_namespace;
    }

    $biochemistry->defaultNameSpace($opts->{namespace}) if defined($opts->{namespace});
    $new_biochemistry->defaultNameSpace($opts->{namespace}) if defined($opts->{namespace});

    $new_biochemistry->mergeBiochemistry($biochemistry,$opts);

    if (defined($opts->{saveas})) {
	my $new_ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
	verbose("Saving biochemistry with merged compounds as ".$new_ref."...\n");
	$store->save_object($new_ref,$new_biochemistry);
    }elsif (defined($opts->{saveover})) {
	verbose("Saving over original biochemistry with merged biochmistry...\n");
	$new_biochemistry->name($biochemistry->name());
	$store->save_object($ref,$new_biochemistry);
    }
}

1;
