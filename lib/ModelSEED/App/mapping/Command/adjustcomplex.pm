package ModelSEED::App::mapping::Command::adjustcomplex;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Adjusts a complex in the mapping" }
sub usage_desc { return "mapping adjustcomplex [mapping id] [complex id] [options]" }
sub options {
    return (
    	["delete","Delete the complex from the mapping"],
        ["name=s","New name for complex"],
        ["delroles=s@","Roles to remove"],
        ["clearoles","Class all roles"],
        ["addroles=s@","List of roles to add (role id:triggering:optional:type)"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    $self->usage_error("Must specify existing complex ID or use key word 'new'.") unless(defined($args->[0]));
	my $input = {
		id => $args->[0]
	};
	if (defined($opts->{name})) {
		$input->{name} = $opts->{name};
	}
	if (defined($opts->{clearoles})) {
		$input->{clearRoles} = $opts->{clearoles};
	}
	if (defined($opts->{"delete"})) {
		$input->{"delete"} = $opts->{"delete"};
	}
	if (defined($opts->{delroles})) {
		$input->{rolesToRemove} = [split(/\|/,join("|",@{$opts->{delroles} || []}))];
	}
	if (defined($opts->{addroles})) {
		$input->{rolesToAdd} = [split(/\|/,join("|",@{$opts->{addroles} || []}))];
		for (my $i=0; $i < @{$input->{rolesToAdd}}; $i++) {
			$input->{rolesToAdd}->[$i] = [split(/:/,$input->{rolesToAdd}->[$i])];
		}
	}
	my $cpx = $map->adjustComplex($input);
	print "Adjustments complete on role:\n".$cpx->id()."\n";
	$self->save_mapping($map);
}

1;