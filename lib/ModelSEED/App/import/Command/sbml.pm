package ModelSEED::App::import::Command::sbml;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::MS::Factories::SBMLFactory
    ModelSEED::Database::Composite
    ModelSEED::Reference
    ModelSEED::App::Helpers
);

sub abstract { return "Import model and biochemistry from SBML"; }

sub usage_desc { return "ms import sbml [filename] [alias]"; }
sub description { return <<END;
Imports a biochemistry and model from an SBML file
END
}

sub opt_spec {
    return (
        ["annotation|a:s", "Annotation to use when importing the model"],
        ["namespace|n:s", "Namespace for IDs in SBML file"],
        ["verbose|v", "Print detailed output of import status"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    $self->usage_error("Filename of SBML file not specified!") unless(defined($args->[0]));
	$self->usage_error("Alias for new model and biochemistry not specified!") unless(defined($args->[1]));
    my $filename = $args->[0];
    my $alias = $args->[1];
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my $factory = ModelSEED::MS::Factories::SBMLFactory->new();
	my $input = {
		filename => $filename,
		verbose => 0
	};
	if (defined($opts->{verbose})) {
		$input->{verbose} = $opts->{verbose};
	}
	if (defined($opts->{namespace})) {
		$input->{namespace} = $opts->{namespace};
	}
	if (defined($opts->{annotation})) {
		(my $annotation,my $ref) = $helper->get_object("annotation",$opts->{annotation},$store);
		$self->usage_error("Specified annotation ".$opts->{annotation}." not found!") unless(defined($annotation));
		$input->{annotation} = $annotation;
	}
	(my $biochemistry,my $model) = $factory->parseSBML($input);
	unless($opts->{dry}) {
        if (defined($model)) {
        	my $ref = $helper->process_ref_string($alias, "model", $auth->username);
        	$store->save_object($ref, $model);
        	print "Saved model to ".$ref."!\n" if(defined($opts->{verbose}));
        }
        if (defined($biochemistry)) {
        	my $ref = $helper->process_ref_string($alias, "biochemistry", $auth->username);
        	$store->save_object($ref, $biochemistry);
        	print "Saved biochemistry to ".$ref."!\n" if(defined($opts->{verbose}));
        }
    }
}

1;
