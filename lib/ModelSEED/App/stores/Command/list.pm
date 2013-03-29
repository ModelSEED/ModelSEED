package ModelSEED::App::stores::Command::list;
use strict;
use common::sense;
use Text::Table;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Lists all stores currently available in this Model SEED installation." }
sub usage_desc { return "stores list [options]"; }
sub options {
    return (
        ["type|t=s", "Only list stores of this type"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $config = config();
	my $stores = $config->stores();
	my $tbl = [];
	foreach my $store (@{$stores}) {
		my $primary = "no";
		if ($store->name() eq $config->PRIMARY_STORE()) {
			$primary = "yes";
		}
		if (!defined($opts->{type}) || $opts->{type} eq $store->type()) {
			push(@{$tbl},[
	            $store->name(),
	            $store->type(),
	            $store->url(),
	            $store->database(),
	           	$primary
	        ]);
		}
	}
    my $table = Text::Table->new(
		'Name','Type','URL','Database','Primary'
	);
    $table->load(@$tbl);
    print $table;
	return;
}

1;
