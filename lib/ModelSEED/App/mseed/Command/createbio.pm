package ModelSEED::App::mseed::Command::createbio;
use strict;
use common::sense;
use ModelSEED::App::mseed;
use base 'ModelSEED::App::MSEEDBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Creates an empty biochemistry"; }
sub usage_desc { return "ms createbio [ biochemistry id ] [name]"; }
sub options {
    return (
		["namespace|n:s", "Sets the default NameSpace to use for the biochemsitry object"],
   	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    $opts->{namespace}='ModelSEED' if !defined($opts->{namespace});
    my $new_biochemistry = ModelSEED::MS::Biochemistry->new({defaultNameSpace => $opts->{namespace},
							     name => $args->[0]});
    #Add empty aliasSets
    $new_biochemistry->add("aliasSets",ModelSEED::MS::AliasSet->new({name=>'ModelSEED',source=>'ModelSEED',attribute=>'compounds',class=>'Compound'}));
    $new_biochemistry->add("aliasSets",ModelSEED::MS::AliasSet->new({name=>'ModelSEED',source=>'ModelSEED',attribute=>'reactions',class=>'Reaction'}));
    $new_biochemistry->add("aliasSets",ModelSEED::MS::AliasSet->new({name=>'searchname',source=>'ModelSEED',attribute=>'compounds',class=>'Compound'}));

    #add proton
    $new_biochemistry->addCompoundFromHash({id=>['cpd00067'],names=>['H+','Proton'],namespace=>'ModelSEED',formula=>['H'],charge=>[1]});

    #add compartments
    $new_biochemistry->addCompartmentFromHash({id=>'e',name=>'Extracellular',hierarchy=>0,uuid=>"0A33AC94-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'w',name=>'Cell Wall',hierarchy=>1,uuid=>"0A33BA9A-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'p',name=>'Periplasm',hierarchy=>2,uuid=>"0A33C2CE-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'c',name=>'Cytosol',hierarchy=>3,uuid=>"0A33CBC0-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'g',name=>'Golgi',hierarchy=>4,uuid=>"0A33D494-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'r',name=>'Endoplasmic Reticulum',hierarchy=>4,uuid=>"0A33DD4A-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'l',name=>'Lysosome',hierarchy=>4,uuid=>"0A33E632-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'n',name=>'Nucleus',hierarchy=>4,uuid=>"0A33EEA2-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'h',name=>'Chloroplast',hierarchy=>4,uuid=>"0A33F776-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'m',name=>'Mitochondria',hierarchy=>4,uuid=>"0A34007C-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'x',name=>'Peroxisome',hierarchy=>4,uuid=>"0A3409A0-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'v',name=>'Vacuole',hierarchy=>4,uuid=>"0A34135A-D74E-11E1-8F32-85923D9902C7"});
    $new_biochemistry->addCompartmentFromHash({id=>'d',name=>'Plastid',hierarchy=>4,uuid=>"0A341C38-D74E-11E1-8F32-85923D9902C7"});
    $self->save_object({
    	type => "Biochemistry",
    	reference => $args->[0],
    	object => $new_biochemistry
    });
}

1;
