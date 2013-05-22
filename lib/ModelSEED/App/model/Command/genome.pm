package ModelSEED::App::model::Command::genome;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
sub abstract { return "Returns the associated annotation object" }
sub usage_desc { return "model genome [model]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
    my $anno = $self->get_object({
    	reference => "Annotation/".$model->annotation_uuid(),
    	store => $opts->{store}
    });
	print "Model linked to genome:\n".$anno->msStoreID()."\n";
}

1;
