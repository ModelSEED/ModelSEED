package ModelSEED::App::GenomeBaseCommand;
use strict;
use common::sense;
use base 'ModelSEED::App::BaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Genome
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
        $self->usage_error("Must provide ID of genome");
    }
    if ($id !~ m/^Annotation\//) {
    	$id = "Annotation/".$id;
    }
   	my $obj = $self->get_object({
   		type => "Annotation",
   		reference => $id,
   		store => $opts->{store}
   	});
    return $self->sub_execute($opts, $args,$obj);
}

sub save_genome {
	my ($self,$obj) = @_;
	my $ref = $obj->msStoreID();
    if ($self->opts()->{saveas}) {
    	my $newid = $self->opts()->{saveas};
    	$ref =~ s/\/[^\/]+$/\/$newid/;
    	ModelSEED::utilities::verbose("New alias set for genome:".$ref);
    }
    ModelSEED::utilities::verbose("Saving genome to:".$ref);
    $self->save_object({
	   	type => "Annotation",
	   	reference => $ref,
	   	store => $self->opts()->{store},
		object => $obj
    });
}

1;
