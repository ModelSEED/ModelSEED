package ModelSEED::App::ModelBaseCommand;
use strict;
use common::sense;
use base 'ModelSEED::App::BaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Model
);
sub parent_options {
    my ( $class, $app ) = @_;
    return (
        $class->options($app),
    );
}

sub class_execute {
    my ($self, $opts, $args) = @_;
    my $id = shift @$args;
	unless (defined($id)) {
        $self->usage_error("Must provide ID of model");
    }
    if ($id !~ m/^Model\//) {
    	$id = "Model/".$id;
    }
   	my $obj = $self->get_object({
   		type => "Model",
   		reference => $id,
   		store => $opts->{store}
   	});
    return $self->sub_execute($opts, $args,$obj);
}

sub save_model {
	my ($self,$model) = @_;
	my $ref = $model->msStoreID();
    if ($self->opts()->{saveas}) {
    	my $newid = $self->opts()->{saveas};
    	$ref =~ s/\/[^\/]+$/\/$newid/;
    	ModelSEED::utilities::verbose("New alias set for model:".$ref);
    }
    ModelSEED::utilities::verbose("Saving model to:".$ref);
    $self->save_object({
	   	type => "Model",
	   	reference => $ref,
	   	store => $self->opts()->{store},
		object => $model
    });
}

1;
