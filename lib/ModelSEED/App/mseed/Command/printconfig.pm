package ModelSEED::App::mseed::Command::printconfig;
use strict;
use common::sense;
use Text::Table;
use base 'ModelSEED::App::MSEEDBaseCommand';

sub abstract { return "Print current configuration options" }

sub usage_desc { return "ms printconfig"; }

sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $config = config();
	my $tbl = [];
	my $configs = [qw(CPLEX_LICENCE ERROR_DIR MFATK_CACHE MFATK_BIN)];
	foreach my $var (@{$configs}) {
		push(@{$tbl},[
            $var,
            $config->$var()
        ]);
	}
    my $table = Text::Table->new(
		'Parameter','Value'
	);
    $table->load(@$tbl);
    print $table;
	return;
}

1;
