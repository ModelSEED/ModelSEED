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

sub abstract { return "Loads this annotation as a genome object into KBase store" }

sub usage_desc { return "genome tokbase [ reference] [store]"; }

sub description { return <<END;
This function translates the annotation object into a KBase genome and uploads it.
    \$ genome tokbase my-genome
END
}

sub options {
    return (
        ["workspace|w=s", "KBase workspace where genome will be uploaded"],
    );
}

sub sub_execute {
    my ($self, $opts, $args, $obj) = @_;
	my $storeName = shift @$args;
	my $config = config();
	$store = $config->currentUser()->findStore($storeName);
	unless (defined($store)) {
        $self->usage_error("Specified store not currently accossiated to user.");
    }
    if (!defined($opts->{workspace})) {
		$opts->{workspace} = $store->currentWorkspace();
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