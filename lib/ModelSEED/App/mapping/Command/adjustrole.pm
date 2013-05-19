package ModelSEED::App::mapping::Command::adjustrole;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
sub abstract { return "Adjusts a functional role in the mapping" }
sub usage_desc { return "mapping adjustrole [mapping id] [role id] [options]" }
sub options {
    return (
    	["delete","Delete the role from the mapping"],
        ["name=s","New name for role"],
        ["seedfeature=s","Representative feature md5"],
        ["newaliases=s@","Aliases to add"],
        ["removealiases=s@","Aliases to remove"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    $self->usage_error("Must specify existing role ID or use key word 'new'.") unless(defined($args->[0]));
	my $input = {
		id => $args->[0]
	};
	if (defined($opts->{name})) {
		$input->{name} = $opts->{name};
	}
	if (defined($opts->{seedfeature})) {
		$input->{seedfeature} = $opts->{seedfeature};
	}
	if (defined($opts->{"delete"})) {
		$input->{"delete"} = $opts->{"delete"};
	}
	if (defined($opts->{newaliases})) {
		$input->{aliasToAdd} = [split(/\|/,join("|",@{$opts->{newaliases} || []}))];
	}
	if (defined($opts->{removealiases})) {
		$input->{aliasToRemove} = [split(/\|/,join("|",@{$opts->{removealiases} || []}))];
	}
	my $role = $map->adjustRole($input);
	print "Adjustments complete on role:\n".$role->id()."\n";
	$self->save_mapping($map);
}

1;
