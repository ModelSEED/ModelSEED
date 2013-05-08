package ModelSEED::App::mapping::Command::properties;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
use Text::Table;
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Prints and sets the primary properties of the mapping object" }
sub usage_desc { return "mapping properties [mapping id] [options]" }
sub options {
    return (
    	["propery|p=s","Property to set"],
        ["value|v=s","New value for property"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    my $properties = [
    	qw(uuid name defaultNameSpace biochemistry_uuid)
    ];
    my $set = 0;
    my $tbl = [];
    for (my $i=0; $i < @{$properties};$i++) {
    	my $prop = $properties->[$i];
    	if ($prop eq $opts->{property} && $map->$prop() ne $opts->{value}) {
    		$map->$prop($opts->{value});
    	}
    	push(@{$tbl},[$prop,$map->$prop()]);
    }
    my $table = Text::Table->new(
		'Property:','Value:'
	);
    $table->load(@$tbl);
    print $table;
    if ($set == 1) {
    	$self->save_mapping($map);
    }
}

1;