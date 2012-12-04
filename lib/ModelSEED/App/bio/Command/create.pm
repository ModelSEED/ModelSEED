package ModelSEED::App::bio::Command::create;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
use ModelSEED::utilities qw( verbose set_verbose translateArrayOptions );
sub abstract { return "Creates an empty biochemistry"; }
sub usage_desc { return "bio create [name]"; }
sub opt_spec {
    return (
    	["verbose|v", "Print comments on command actions"]
   	);
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    $self->usage_error("Must specify a name for the object to be created") unless(defined($args->[0]));

    #verbosity
    set_verbose(1) if $opts->{verbose};

    my $new_biochemistry = ModelSEED::MS::Biochemistry->new({defaultNameSpace => 'ModelSEED',
							     name => $args->[0]});

    #Add empty aliasSets
    $new_biochemistry->add("aliasSets",ModelSEED::MS::AliasSet->new({name=>'ModelSEED',source=>'ModelSEED',attribute=>'compounds',class=>'Compound'}));
    $new_biochemistry->add("aliasSets",ModelSEED::MS::AliasSet->new({name=>'ModelSEED',source=>'ModelSEED',attribute=>'reactions',class=>'Reaction'}));
    $new_biochemistry->add("aliasSets",ModelSEED::MS::AliasSet->new({name=>'searchname',source=>'ModelSEED',attribute=>'compounds',class=>'Compound'}));

    #add proton
    $new_biochemistry->addCompoundFromHash({id=>['cpd00067'],names=>['H+','Proton'],namespace=>'ModelSEED',formula=>['H']});

    #add compartments
    $new_biochemistry->addCompartmentFromHash({id=>'e',name=>'Extracellular',hierarchy=>0});
    $new_biochemistry->addCompartmentFromHash({id=>'w',name=>'Cell Wall',hierarchy=>1});
    $new_biochemistry->addCompartmentFromHash({id=>'p',name=>'Periplasm',hierarchy=>2});
    $new_biochemistry->addCompartmentFromHash({id=>'c',name=>'Cytosol',hierarchy=>3});
    $new_biochemistry->addCompartmentFromHash({id=>'g',name=>'Golgi',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'r',name=>'Endoplasmic Reticulum',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'l',name=>'Lysosome',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'n',name=>'Nucleus',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'h',name=>'Chloroplast',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'m',name=>'Mitochondria',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'x',name=>'Peroxisome',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'v',name=>'Vacuole',hierarchy=>4});
    $new_biochemistry->addCompartmentFromHash({id=>'d',name=>'Plastid',hierarchy=>4});

    my $ref = $helper->process_ref_string($args->[0], "biochemistry", $auth->username);
    verbose("Creating biochemistry with name ".$ref."\n");
    $store->save_object($ref,$new_biochemistry);
}

1;
