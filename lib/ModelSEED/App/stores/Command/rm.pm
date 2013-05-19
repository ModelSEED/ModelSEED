package ModelSEED::App::stores::Command::rm;
use strict;
use common::sense;
use ModelSEED::utilities;
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
	my $config = ModelSEED::utilities::config();
	$opts = args([],{
		"delete" => 0,
		name => $name
	},%{$opts});
	$config->remove_store($opts);
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	return;
}

1;
