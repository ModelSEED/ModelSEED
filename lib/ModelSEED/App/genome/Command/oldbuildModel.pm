package ModelSEED::App::genome::Command::oldbuildModel;
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::GenomeBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Construct a model using this annotated genome" }
sub usage_desc { return "genome oldbuildModel [genome id] [model id] [options]" }
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
    	["mapping|m:s", "Use a specific mapping to build the model"]
    );
}
sub sub_execute {
    my ($self, $opts, $args,$anno) = @_;
    my $modelID = shift(@{$args});
    my $mapping;
    if(defined($opts->{mapping})) {
        $mapping = $self->get_object({
	    	type => "Mapping",
	    	reference => $opts->{mapping},
	    });
    } else {
        $mapping = $anno->mapping;
    }
    my $model = $anno->createStandardFBAModel({
        mapping => $mapping
    });
    $self->save_object({
    	type => "Model",
    	reference => $modelID,
    	object => $model
    });
}

1;