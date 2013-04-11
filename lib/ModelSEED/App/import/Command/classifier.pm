package ModelSEED::App::import::Command::classifier;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use Cwd;
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Classifier
);
sub abstract { return "Import a classifier from a file"; }
sub usage_desc { return "ms import classifier [filename] [name] [mapping] [options]"; }
sub description { return "Imports classifier from file"; }
sub options {
    return (
    	["typeclassifier|t", "Use as genome type classifier"],
    	["mapping|m:s", "Select the preferred mapping object to use when importing the classifier"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must specify filename with classifier information") unless(defined($args->[0]));
    $self->usage_error("Must specify name for the classifier") unless(defined($args->[1]));
    if(defined($opts->{mapping})) {
    	$map = $self->get_object({
	    	type => "Mapping",
	    	reference => $opts->{mapping}
	    });
   	else {
   		$map = $self->store()->defaultMapping();
   	}
   	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
   	my ($classifier,$map)  = $exchange_factory->buildClassifier({
		filename => $args->[0],
		name => $args->[1],
		mapping => $map
	});
   	if ($opts->{typeclassifier}) {
    	$map->typeClassifier_uuid($classifier->uuid());
    }
    $self->save_object({
    	object => $map,
    	type => "Mapping",
    	reference => $map->msStoreID()
    });
	$self->save_object({
    	object => $classifier,
    	type => "Classifier",
    	reference => $args->[1]
    });
}

1;
