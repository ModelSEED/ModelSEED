package ModelSEED::App::stores::Command::rm;
use strict;
use common::sense;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Removes the specified store from the Model SEED configuration." }
sub usage_desc { return "stores rm [name of store]"; }
sub options {
    return (
        ["delete", "Permanemtly delete the store"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $name = shift @$args;
	unless (defined($name)) {
        $self->usage_error("Must provide name of store to delete");
    } 
	my $config = config();
	$opts = args($opts,[],{
		"delete" => 0,
		name => $name
	});
	$config->remove_store($opts);
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	return;
}

1;
