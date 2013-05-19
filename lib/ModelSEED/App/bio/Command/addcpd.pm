package ModelSEED::App::bio::Command::addcpd;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Adds a single compound to the database from input arguments" }
sub usage_desc { return "bio addcpd [ biochemistry id ] [id] [ name ] [ options ]" }
sub description { return <<END;
END
}
sub options {
    return (
    	["abbreviation|b:s", "Abbreviation"],
        ["formula|f:s", "Molecular formula"],
        ["mass|m:s", "Molecular weight"],
        ["charge|c:s", "Molecular charge"],
        ["deltag|g:s", "Gibbs free energy (kcal/mol)"],
        ["deltagerr|e:s", "Uncertainty in Gibbs energy"],
        ["altnames:s", "Alternative names"],
        ["namespace|n:s", "Name space for aliases added"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify an id for the compound") unless(defined($args->[1]));
    $self->usage_error("Must specify a primary name for the compound") unless(defined($args->[2]));
    my $cpdData = {
    	id => [$args->[1]],
    	names => [$args->[2]]
    };
    if (defined($opts->{altnames})) {
    	push(@{$cpdData->{names}},split(/\|/,$opts->{altnames}));
    }
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = $bio->defaultNameSpace();
    }
    my $headings = ["formula","mass","deltaG","deltaGErr","abbreviation","charge"];
    foreach my $heading (@{$headings}) {
    	if (defined($opts->{$heading})) {
    		$cpdData->{$heading} = [$opts->{$heading}];
    	}
    }
    $cpdData->{aliasType} = $opts->{namespace};
    my $cpd = $bio->addCompoundFromHash($cpdData);
    if (defined($cpd)) {
    	print "Compound added with UUID:".$cpd->uuid()."\n";
    }
    $self->save_bio($bio);
}

1;
