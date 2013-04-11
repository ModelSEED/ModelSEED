package ModelSEED::App::mseed::Command::list;
use strict;
use common::sense;
use Try::Tiny;
use List::Util qw(max);
use ModelSEED::Exceptions;
use Class::Autouse qw(
    ModelSEED::Reference
    ModelSEED::Auth::Factory
    ModelSEED::Store
    ModelSEED::App::Helpers
);
use base 'ModelSEED::App::MSEEDBaseCommand';
use Class::Autouse qw(
    ModelSEED::App::import
);
sub abstract { return "List and retrive objects from workspace or datastore."; }
sub usage_desc { return "ms list [query] [options]" }
sub options {
    return (
    	["mine", "Only list items that I own"],
        ["with|w:s@", "Append a tab-delimited column with this attribute"],
        ["query|q:s@", "Only list sub objects matching a query"],
        ["no_ref", "Do not print the reference column (useful for 'with' option)"]
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
    my $ref = shift @$args;
    my $fields = ["Reference"];
    if ($opts->{no_ref}) {
    	$fields = [];
    }
    push(@$fields, split(/,/,join(",",@{$opts->{with} || []})));
    my $queryHash = {};
    if (defined($opts->{query})) {
		my $queries = [split(/,/,join(",",@{$opts->{query}}))];
		foreach my $query (@{$queries}) {
			my $array = [split(/\=/,$query)];
			if (defined($array->[1])) {
				$queryHash->{$array->[0]} = $array->[1];
			}
		}
	}
    my $output = $self->store()->list({
    	reference => $ref,
    	mine => $opts->{mine},
    	fields => $fields,
    	query => $queryHash,
    	noref => $opts->{no_ref}
    });
    my $table = Text::Table->new(
		@{$output->{headings}}
	);
    $table->load(@{$output->{data}});
    print $table;
}

1;
