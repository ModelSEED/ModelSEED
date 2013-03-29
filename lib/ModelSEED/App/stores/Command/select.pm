package ModelSEED::App::stores::Command::select;
use strict;
use common::sense;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Selects a store as the current primary store." }
sub usage_desc { return "stores select [name of store]"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $name = shift @$args;
	unless (defined($name)) {
        $self->usage_error("Must provide name of store to select!");
    } 
	my $config = config();
	$config->select_store($name);
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	return;
}

1;
