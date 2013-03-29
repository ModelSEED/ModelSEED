package ModelSEED::App::genome::Command::tokbase;
use strict;
use common::sense;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'ModelSEED::App::GenomeBaseCommand';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);

sub abstract { return "Loads this annotation as a genome object in KBase" }

sub usage_desc { return "genome tokbase [ reference] [?]"; }

sub description { return <<END;
This function translates the annotation object into a KBase genome and uploads it.
    \$ genome tokbase my-genome
END
}

sub options {
    return (
        ["workspace|w=s", "KBase workspace where genome will be uploaded"],
        ["url|u=s", "URL of the KBase workspace server"],
        ["database|d=s", "Database of store (default is 'msws')"],
    );
}

sub sub_execute {
    my ($self, $opts, $args, $obj) = @_;
	my $auth;
	if (!defined($opts->{username})) {
		$auth = $self->kbauth();
	} else {
		$auth = $self->kbauth({
			username => $opts->{username},
			password => $opts->{password},
		});
	}
	if (!defined($opts->{workspace})) {
		$opts->{workspace} = $self->kbworkspace($auth);
	}
	my $genome = $obj->buildKBaseGenome();
	$self->kbfbaclient->genome_object_to_workspace({
		genomeobj => $genome,
		workspace => $opts->{workspace},
		auth => $auth,
		biochemistry => $bio,
		mapping => $map
	});
	return;
}