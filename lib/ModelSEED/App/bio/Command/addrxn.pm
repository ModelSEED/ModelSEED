package ModelSEED::App::bio::Command::addrxn;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities;
sub abstract { return "Adds a single reaction to the database from input arguments" }
sub usage_desc { return "bio addrxn [ biochemistry id ] [id] [equation]"; }
sub options {
    return (
        ["names|n:s", "Abbreviation"],
        ["abbreviation|b:s", "Molecular formula"],
        ["enzymes|z:s", "Associated EC number"],
        ["direction|d:s", "Default directionality for reaction"],
        ["deltag|g:s", "Gibbs free energy (kcal/mol)"],
        ["deltagerr|e:s", "Uncertainty in Gibbs energy"],
        ["namespace|n:s", "Namespace under which IDs will be added"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify an id for the reaction") unless(defined($args->[0]));
    $self->usage_error("Must specify an equation for the reaction") unless(defined($args->[1]));
    my $rxnData = {
    	id => [$args->[0]],
    	equation => [$args->[1]]
    };
   	if (defined($opts->{names})) {
    	$rxnData->{names} = [split(/\|/,$opts->{names})];
    }
    if (defined($opts->{enzymes})) {
    	$rxnData->{enzymes} = [split(/\|/,$opts->{enzymes})];
    }
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = $bio->defaultNameSpace();
    }
    my $headings = ["abbreviation","direction","deltag","deltagerr"];
    foreach my $heading (@{$headings}) {
    	if (defined($opts->{$heading})) {
    		$rxnData->{$heading} = [$opts->{$heading}];
    	}
    }
    $rxnData->{aliasType} = $opts->{namespace};
    my $rxn = $bio->addReactionFromHash($rxnData);
    if (defined($rxn)) {
    	print "Reaction added with UUID:".$rxn->uuid()."\n";
    }
    $self->save_bio($bio);
}

1;
