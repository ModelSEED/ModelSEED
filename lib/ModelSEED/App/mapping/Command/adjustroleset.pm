package ModelSEED::App::mapping::Command::adjustroleset;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Adjusts a role set in the mapping" }
sub usage_desc { return "mapping adjustroleset [mapping id] [roleset id] [options]" }
sub options {
    return (
        ["delete","Delete the roleset"],
        ["name=s","Name for the roleset"],
        ["class=s","Primary class of the roleset"],
        ["subclass=s","Secondary class of the roleset"],
        ["type=s","Type of the roleset"],
        ["newroles=s@","Roles to add"],
        ["remroles=s@","Roles to remove"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    $self->usage_error("Must specify existing roleset ID or use key word 'new'.") unless(defined($args->[0]));
	my $input = {
		id => $args->[0],
		rolesToAdd => [],
		rolesToRemove => []
	};
	if (defined($opts->{name})) {
		$input->{name} = $opts->{name};
	}
	if (defined($opts->{class})) {
		$input->{class} = $opts->{class};
	}
	if (defined($opts->{subclass})) {
		$input->{subclass} = $opts->{subclass};
	}
	if (defined($opts->{"delete"})) {
		$input->{"delete"} = $opts->{"delete"};
	}
	if (defined($opts->{type})) {
		$input->{type} = $opts->{type};
	}
	if (defined($opts->{newroles})) {
		$input->{rolesToAdd} = [split(/\|/,join("|",@{$opts->{newroles} || []}))];
	}
	if (defined($opts->{remroles})) {
		$input->{rolesToRemove} = [split(/\|/,join("|",@{$opts->{remroles} || []}))];
	}
	my $ss = $map->adjustRoleset($input);
	print "Adjustments complete on roleset:\n".$ss->id()."\n";
	$self->save_mapping($map);
}

1;