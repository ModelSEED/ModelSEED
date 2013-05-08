package ModelSEED::App::MappingBaseCommand;
use strict;
use common::sense;
use base 'ModelSEED::App::BaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Mapping
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
        $self->usage_error("Must provide ID of mapping");
    }
    if ($id !~ m/^Mapping\//) {
    	$id = "Mapping/".$id;
    }
   	my $obj = $self->get_object({
   		type => "Mapping",
   		reference => $id,
   		store => $opts->{store}
   	});
    return $self->sub_execute($opts, $args,$obj);
}

sub save_mapping {
	my ($self,$obj) = @_;
	my $ref = $obj->msStoreID();
    if ($self->opts()->{saveas}) {
    	my $newid = $self->opts()->{saveas};
    	$ref =~ s/\/[^\/]+$/\/$newid/;
    	ModelSEED::utilities::verbose("New alias set for map:".$ref);
    }
    ModelSEED::utilities::verbose("Saving map to:".$ref);
    $self->save_object({
	   	type => "Mapping",
	   	reference => $ref,
	   	store => $self->opts()->{store},
		object => $obj
    });
}

1;
