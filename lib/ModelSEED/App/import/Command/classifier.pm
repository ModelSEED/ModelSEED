package ModelSEED::App::import::Command::classifier;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Cwd;
use ModelSEED::utilities qw( args verbose set_verbose translateArrayOptions );
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Classifier
    ModelSEED::Reference
    ModelSEED::App::Helpers
);

sub abstract { return "Import a classifier from a file"; }

sub usage_desc { return "ms import classifier [filename] [name] [mapping] [options]"; }
sub description { return "Imports classifier from file"; }

sub opt_spec {
    return (
        ["typeclassifier|t", "Use as genome type classifier"],
        ["verbose|v", "Print detailed output of import status"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $auth = ModelSEED::Auth::Factory->new->from_config();
    my $helpers = ModelSEED::App::Helpers->new;
    $self->usage_error("Must specify filename with classifier information") unless(defined($args->[0]));
    $self->usage_error("Must specify name for the classifier") unless(defined($args->[1]));
    $self->usage_error("Must specify the mapping the classifier is linked to") unless(defined($args->[2]));
    if (defined($opts->{verbose}) && $opts->{verbose} == 1) {
    	set_verbose(1);
    }
    # Initialize the store object
    my $store = ModelSEED::Store->new(auth => $auth);
    #Retrieving mapping object
    my $mapref = $helpers->process_ref_string($args->[2], "mapping", $auth->username);
    my $map = $store->get_object($mapref);
    my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my ($classifier,$mapping)  = $exchange_factory->buildClassifier({
		filename => $args->[0],
		name => $args->[1],
		mapping => $map
	});
	my $classref = $helpers->process_ref_string($args->[1], "classifier", $auth->username);
    if ($opts->{typeclassifier}) {
    	$map->typeClassifier_uuid($classifier->uuid());
    }
	#Saving model in database
    unless($opts->{dry}) {
        $store->save_object($mapref, $map);
        $store->save_object($classref, $classifier);
        verbose("Saved classifier to $classref!");
    }
}

1;
