package ModelSEED::App::bio::Command::properties;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use Text::Table;
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Prints and sets the primary properties of the Biochemistry object" }
sub usage_desc { return "bio properties [biochemistry id] [options]" }
sub options {
    return (
    	["propery|p=s","Property to set"],
        ["value|v=s","New value for property"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    my $properties = [
    	qw(uuid name defaultNameSpace biochemistryStructures_uuid)
    ];
    my $set = 0;
    my $tbl = [];
    for (my $i=0; $i < @{$properties};$i++) {
    	my $prop = $properties->[$i];
    	if ($prop eq $opts->{property} && $bio->$prop() ne $opts->{value}) {
    		$bio->$prop($opts->{value});
    		$set = 1;
    	}
    	push(@{$tbl},[$prop,$bio->$prop()]);
    }
    my $table = Text::Table->new(
		'Property:','Value:'
	);
    $table->load(@$tbl);
    print $table;
    if ($set == 1) {
    	$self->save_bio($bio);
    }
}

1;
