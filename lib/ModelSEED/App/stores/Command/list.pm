package ModelSEED::App::stores::Command::list;
use strict;
use common::sense;
use Text::Table;
use ModelSEED::utilities;
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
	my $config = ModelSEED::utilities::config();
	my $stores = $config->currentUser()->userStores();
	my $tbl = [];
	foreach my $store (@{$stores}) {
		my $primary = "no";
		if ($store->associatedStore()->name() eq $config->currentUser()->primaryStoreName()) {
			$primary = "yes";
		}
		if (!defined($opts->{type}) || $opts->{type} eq $store->type()) {
			push(@{$tbl},[
	            $store->associatedStore()->name(),
	            $store->associatedStore()->type(),
	            $store->associatedStore()->url(),
	            $store->associatedStore()->database(),
	           	$primary,
	           	$store->login()
	        ]);
		}
	}
    my $table = Text::Table->new(
		'Name','Type','URL','Database','Primary','Login'
	);
    $table->load(@$tbl);
    print $table;
	return;
}

1;
