use strict;
package ModelSEED::MS::Utilities::GlobalFunctions;

=head3 convertRoleToSearchRole
Definition:
	string:searchrole = ModelSEED::MS::Utilities::GlobalFunctions::convertRoleToSearchRole->(string rolename);
Description:
	Converts the input role name into a search name by removing spaces, capitalization, EC numbers, and some punctuation.

=cut

sub convertRoleToSearchRole {
	my ($rolename) = @_;
	$rolename = lc($rolename);
	$rolename =~ s/[\d\-]+\.[\d\-]+\.[\d\-]+\.[\d\-]+//g;
	$rolename =~ s/\s//g;
	$rolename =~ s/\#.*$//g;
	return $rolename;
}

=head3 functionToRoles
Definition:
	Output = ModelSEED::MS::Utilities::GlobalFunctions::functionToRoles->(string function);
	Output = {
		roles => [string],
		delimiter => [string],
		compartment => string,
		comment => string
	};
Description:
	Converts a functional annotation from the seed into a set of roles, a delimiter, a comment, and a compartment.

=cut

sub functionToRoles {
	my ($function) = @_;
	my $output = {
		roles => [],
		delimiter => "none",
		compartments => ["u"],
		comment => "none"	
	};
	my $compartmentTranslation = {
		"cytosolic" => "c",
		"plastidial" => "d",
		"mitochondrial" => "m",
		"peroxisomal" => "x",
		"lysosomal" => "l",
		"vacuolar" => "v",
		"nuclear" => "n",
		"plasma\\smembrane" => "p",
		"cell\\swall" => "w",
		"golgi\\sapparatus" => "g",
		"endoplasmic\\sreticulum" => "r",
		extracellular => "e",
	    cellwall => "w",
	    periplasm => "p",
	    cytosol => "c",
	    golgi => "g",
	    endoplasm => "r",
	    lysosome => "l",
	    nucleus => "n",
	    chloroplast => "h",
	    mitochondria => "m",
	    peroxisome => "x",
	    vacuole => "v",
	    plastid => "d",
	    unknown => "u"
	};
	my $array = [split(/\#/,$function)];
	$function = shift(@{$array});
	$function =~ s/\s+$//;
	$output->{comment} = join("#",@{$array});
	my $compHash = {};
	if (length($output->{comment}) > 0) {
		foreach my $comp (keys(%{$compartmentTranslation})) {
			if ($output->{comment} =~ /$comp/) {
				$compHash->{$compartmentTranslation->{$comp}} = 1;
			}
		}
	}
	if (keys(%{$compHash}) > 0) {
		$output->{compartments} = [keys(%{$compHash})];
	}
	if ($function =~ /\s*;\s/) {
		$output->{delimiter} = ";";
	}
	if ($function =~ /s+\@\s+/) {
		$output->{delimiter} = "\@";
	}
	if ($function =~ /s+\/\s+/) {
		$output->{delimiter} = "/";
	}
	$output->{roles} = [split(/\s*;\s+|\s+[\@\/]\s+/,$function)];
	return $output;
}

1;