package ModelSEED::App::genome::Command::buildModel;
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::GenomeBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use Class::Autouse qw(
    ModelSEED::MS::Annotation
    ModelSEED::MS::Mapping
    ModelSEED::MS::ModelTemplate
    ModelSEED::MS::Biochemistry
);
sub abstract { return "Construct a model using this annotated genome" }
sub usage_desc { return "genome buildModel [genome id] [model id] [options]" }
sub description { return <<END;
This function constructs a basic model from the annotated genome.
If no mapping object is supplied, it uses the mapping object
associated with the annotated genome. model-name is the name of the
resulting model.

    \$ genome buildModel my-genome my-model
END
}
sub options {
    return (
    	["template|t=s", "Specific template to use in building a model"],
		["mapping|m=s", "Mapping with classifiers for model building"]
    );
}
sub sub_execute {
    my ($self, $opts, $args,$anno) = @_;
    my $modelID = shift(@{$args});
    my $template;
    if (defined($opts->{template})) {
    	$template = $self->get_object({
	    	type => "ModelTemplate",
	    	reference => $opts->{template}
	    });
    } else {
    	my $mapping;
    	if(defined($opts->{mapping})) {
	        $mapping = $self->get_object({
		    	type => "Mapping",
		    	reference => $opts->{mapping},
		    });
	    } else {
	        $mapping = $anno->mapping;
	    }
    }
    $self->usage_error("Template model no found!") unless(defined($template));
    my $model = $template->buildModel({
    	annotation => $anno
    });
    $self->save_object({
    	type => "Model",
    	reference => $modelID,
    	object => $model
    });
}

1;