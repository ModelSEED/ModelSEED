package ModelSEED::App::stores::Command::add;
use strict;
use common::sense;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Lists all stores currently available in this Model SEED installation." }
sub usage_desc { return "stores add [name of store]"; }
sub options {
    return (
        ["type|t=s", "Type of store (default is 'workspace')"],
        ["url|u=s", "URL of store (default is 'localhost')"],
        ["database|d=s", "Database of store (default is 'msws')"],
        ["login|l=s", "Username to log into authenticated store"],
        ["password|p=s", "Password to log into authenticated store"],
        ["accounttype|a=s", "Type of account to authenticate against"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $name = shift @$args;
	unless (defined($name)) {
        $self->usage_error("Must provide name for the store.");
    } 
	my $config = config();
	$opts = args([],{
		type => "workspace",
		url => "localhost",
		database => "msws",
		name => $name,
		login => $config->username(),
		password => $config->password(),
		accounttype => "seed"
	},%{$opts});
	$config->add_store($opts);
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	return;
}

1;
