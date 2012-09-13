package ModelSEED::App::model::Command::updateprovenance;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Updates the provenance objects the model is linked to"; }
sub usage_desc { return "model updateprovenance [ model || - ] [options]"; }
sub opt_spec {
    return (
        ["bio|b","Update linked biochemistry"],
        ["anno|a","Update linked annotation"],
        ["map|m","Update linked mapping"],
        ["all","Update all linked objects"]
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    #Retreiving the model object on which FBA will be performed
    (my $model,my $ref) = $helper->get_object("model",$args,$store);
    $self->usage_error("Model not found; You must supply a valid model name.") unless(defined($model));
	#Standard commands to handle where output will be printed
    my $out_fh = \*STDOUT;
    #If any options are selected, perform the requested update
    my $change = 0;
    if ($opts->{all} || $opts->{bio}) {
    	my $desc = $model->biochemistry()->descendants();
    	if (defined($desc->[0])) {
    		$model->biochemistry_uuid($desc->[0]);
    		$change = 1;
    	}
    }
    if ($opts->{all} || $opts->{map}) {
    	my $desc = $model->mapping()->descendants();
    	if (defined($desc->[0])) {
    		$model->mapping_uuid($desc->[0]);
    		$change = 1;
    	}
    }
    if ($opts->{all} || $opts->{anno}) {
    	my $desc = $model->annotation()->descendants();
    	if (defined($desc->[0])) {
    		$model->annotation_uuid($desc->[0]);
    		$change = 1;
    	}
    }
    #Reporting any new updates that are possible 
    my $linkedProvenances = {
    	Biochemistry => "biochemistry",
    	Mapping => "mapping",
    	Annotation => "annotation"
    };
    foreach my $prov (keys(%{$linkedProvenances})) {
    	my $function = $linkedProvenances->{$prov};
    	my $desc = $model->$function()->descendants();
    	if (defined($desc) && @{$desc} > 0) {
    		print $prov." updates available:\n";
    		foreach my $dec (@{$desc}) {
    			print $dec."\n";
    		}
    		print "\n";
    	}
    }
     #Saving changed model
    if ($change == 1) {
    	$store->save_object($ref,$model);
    }
}

1;