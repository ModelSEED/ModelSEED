#!/usr/bin/perl
use strict;
use common::sense;
use Class::Autouse qw(
    YAML::XS
    File::Temp
    JSON::XS
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::FBAFormulation
    ModelSEED::Solver::FBA
);

my $args = \@ARGV;

my $auth  = ModelSEED::Auth::Factory->new->from_config;
my $store = ModelSEED::Store->new(auth => $auth);
my $helper = ModelSEED::App::Helpers->new();
# Retreiving the model object on which FBA will be performed
my ($model, $ref) = $helper->get_object("model",$args,$store);
warn "Model not found; You must supply a valid model name." unless(defined($model));

my $forms = $model->fbaFormulations();


# for each formulation mode.
if ($ARGV[1] eq "-j") {
    my $file = $ARGV[2];
    open(IN, $file) or die "Cannot open $file: $!\n"; 
    read(IN, my $form_uuid, (-s $file)); 
    close(IN);

    foreach my $form (@$forms) {
        next if $form->uuid() ne $form_uuid;
#        $DB::single = 1; #debug
        my $geneCalls = {
	    "media" => $form->media()->name(),
	    "data" => &getGeneCalls($form)
	};
	print YAML::XS::Dump($geneCalls);
	exit;
    }
}

#$DB::single = 1; #debug

my $overForms = {};
foreach my $form (@$forms) {
    next if !defined $form || !$form->fva();

    $overForms->{$form->media()->name()} = &getGeneCalls($form);
}

printGeneCalls($overForms);


sub getGeneCalls {
    my ($form) = @_;
    
    my $rxnToFlux_value = &_buildRxn2flux_value($form);
    my $rxnToGenes = &_buildRxnToGenes($model);
    return &_computeGeneOnOff($rxnToFlux_value, $rxnToGenes);
}
# print gene calls for each media.
sub printGeneCalls {    
    my ($overForms) = @_;

    my $tbl = {"headings" =>["gene_id"], "data" => []};
    
    while (my ($media, $geneCalls) = each %$overForms) {
        push @{$tbl->{"headings"}}, $media;

        my @gene_ids = sort by_feature_id keys %{$geneCalls};
        for (my $row_i = 0; $row_i < @gene_ids; $row_i++ ) {
            $tbl->{"data"}->[$row_i] = [$gene_ids[$row_i]] if (!defined $tbl->{"data"}->[$row_i]);
            push @{$tbl->{"data"}->[$row_i]}, $geneCalls->{$gene_ids[$row_i]};
        }
    }
    ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl,"\t");
}

# look through fba (fva) results, and make a hash for activity status.
sub _buildRxn2flux_value {
    my ($form) = @_;
    my $rxnToFlux_value = {};
    my @reactionVars = @{$form->fbaResults()->[0]->fbaReactionVariables};
    foreach my $rxnVar (@reactionVars) {

        # positive: 1, 0: 0, negative: -1;
        my ($max_sign, $min_sign) = map {$_ <=> 0} ($rxnVar->max(), $rxnVar->min());

        # translate max /min flux to activity status.
        # e: Essential, a: Active, i: Inactive, n: Not the case.
        #        max
        #       - 0 +
        #     - e a a
        # min 0 n i a
        #     + n n e
        my $status = ($max_sign == $min_sign) ? ($max_sign == 0) ? "Inactive" : "Essential" : "Active"; 
        print STDERR "Unexpected max and min.\n" if $max_sign < $min_sign; 
        $rxnToFlux_value->{$rxnVar->modelreaction()->id()} = $status;        
    }

    return $rxnToFlux_value;
}

sub _buildRxnToGenes {
    my ($model) = @_;
    
    my $rxnToGenes = {};
    foreach my $mdlrxn (@{$model->modelreactions()}) {
        foreach my $prot (@{$mdlrxn->modelReactionProteins()}) {
            foreach my $subunit (@{$prot->modelReactionProteinSubunits()}) {
                foreach my $feature (@{$subunit->modelReactionProteinSubunitGenes()}) {
                    # overwrite by priority.
                    push @{$rxnToGenes->{$mdlrxn->id()}}, $feature->feature()->id();
                }
            }
        }
    }
    return $rxnToGenes;
}

sub _computeGeneOnOff {
    my ($rxnToFlux_value, $rxnToGenes)  = @_;
    
    my $geneCalls;
    while ( my ($mdlrxn_id, $gene_ids) = each %$rxnToGenes) {
        next if !exists $rxnToFlux_value->{$mdlrxn_id};
        foreach my $gene_id (@{$gene_ids}) {
            # overwrite by priority.
            ($geneCalls->{$gene_id}) = sort by_status ($geneCalls->{$gene_id}, $rxnToFlux_value->{$mdlrxn_id}); 
        }
    }
    return $geneCalls;
}

# sort activity status by priority.
sub by_status {
    my %priority = (
        'Essential' => 3,
        'Active' => 2, 
        'Inactive' => 1,        
        );
    return $priority{$b} <=> $priority{$a};        
}

sub by_feature_id {
    if ($a =~ /(\w+)\.(\d+)$/) {
        my $a_kind = $1;
        my $a_num = $2;
        if ($b =~ /(\w+)\.(\d+)$/) {
            my $b_kind = $1;
            my $b_num = $2;	    
            return $a_kind cmp $b_kind || $a_num <=> $b_num;
	    }
    }
    return 0;    
}
