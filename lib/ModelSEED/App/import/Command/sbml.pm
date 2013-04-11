package ModelSEED::App::import::Command::sbml;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use Class::Autouse qw(
    ModelSEED::MS::Factories::SBMLFactory
);
sub abstract { return "Import model and biochemistry from SBML"; }
sub usage_desc { return "ms import sbml [filename] [save model as]"; }
sub description { return <<END;
Imports a biochemistry and model from an SBML file
END
}
sub options {
    return (
        ["namespace|n:s", "Name space of database (default is 'ModelSEED')"],
        ["annotation|a:s", "Annotation to use when importing the model"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    my $filename = $args->[0];
    my $modelid = $args->[1];
    $self->usage_error("Filename of SBML file not specified!") unless(defined($filename));
	$self->usage_error("SBML file not found!") unless (-e $filename);
	$self->usage_error("Alias for new model and biochemistry not specified!") unless(defined($modelid));
	my $input = {
		filename => $filename,
		verbose => 0
	};
	if (defined($opts->{namespace})) {
		$input->{namespace} = $opts->{namespace};
	}
	(my $biochemistry,my $model,my $anno,my $mapping) = $factory->parseSBML($input);
	if (defined($model) && defined($anno) && defined($mapping) && defined($biochemistry)) {
		$self->save_object({
	    	object => $biochemistry,
	    	type => "Biochemistry",
	    	reference => $modelid
	    });
	    $self->save_object({
	    	object => $mapping,
	    	type => "Mapping",
	    	reference => $modelid
	    });
	    $self->save_object({
	    	object => $anno,
	    	type => "Annotation",
	    	reference => $modelid
	    });
		$self->save_object({
	    	object => $model,
	    	type => "Model",
	    	reference => $modelid
	    });
    }
}

1;
