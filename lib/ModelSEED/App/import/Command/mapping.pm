package ModelSEED::App::import::Command::mapping;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use File::Temp qw(tempfile);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use LWP::Simple;
use JSON::XS;
use ModelSEED::utilities qw( verbose set_verbose );
use Class::Autouse qw(
    ModelSEED::MS::Mapping
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::PPOFactory
    ModelSEED::Database::Composite
    ModelSEED::Reference
);

sub abstract { return "Import mapping from local or remote database"; }

sub usage_desc { return "ms import mapping [alias] [options]"; }
sub description { return <<END;
Import mapping data (roles, complexes, etc.)
Alias, required, is the name that you would like to save the mapping as.

You may supply a biochemistry with -b to use when importing the mapping
objct. If this is not supplied, the default biochemistry, i.e.
\$ ms defaults bichemistry
will be used.
    
The [--filepath path] argument indicates where you are importing
the mapping from. Current supported options are:
    
    --filepath path : path with flat files of mapping data 

END
}

sub opt_spec {
    return (
        ["biochemistry|b:s", "Reference to biochemistry to use for import"],
        ["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["namespace|n:s", "Name space of database (default is 'ModelSEED')"],
        ["store|s:s", "Identify which store to save the mapping to"],
        ["verbose|v", "Print detailed output of import status"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    set_verbose 1 if $opts->{verbose};
    print($self->usage) && return if $opts->{help};
    my $auth = ModelSEED::Auth::Factory->new->from_config();
    my $helpers = ModelSEED::App::Helpers->new;
    my $store;
    # Initialize the store object
    if($opts->{store}) {
        my $store_name = $opts->{store};
        my $config = ModelSEED::Configuration->instance;
        my $store_config = $config->config->{stores}->{$store_name};
        die "No such store: $store_name" unless(defined($store_config));
        my $db = ModelSEED::Database::Composite->new(databases => [ $store_config ]);
        $store = ModelSEED::Store->new(auth => $auth, database => $db);
    } else {
        $store = ModelSEED::Store->new(auth => $auth);
    }
    # Check that required argument are present
    my ($alias) = @$args;
    $self->usage_error("Must supply an alias") unless(defined($alias));
    # Make sure the alias object is valid "username/alias_string"
    $alias = $helpers->process_ref_string(
        $alias, "mapping", $auth->username
    );
    verbose "Will be saving to $alias...\n";
    # Getting biochemistry if that was provided
    my ($biochemistry, $bio_ref);
    if ($opts->{biochemistry}) {
        $bio_ref = $helpers->process_ref_string(
            $opts->{biochemistry}, "biochemistry", $auth->username
        );
        $biochemistry = $store->get_object($bio_ref);
        verbose "Using $bio_ref biochemistry while importing mapping\n";
    }
    my $alias_ref = ModelSEED::Reference->new(ref => $alias);
    my $map;
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = "ModelSEED";
    }
	if($opts->{filepath}) {
        my $factory = ModelSEED::MS::Factories::TableFileFactory->new({
             filepath => $opts->{filepath},
             namespace => $opts->{namespace},
        });
		$map = $factory->createMapping({
			name => $alias,
			biochemistry => $biochemistry,
			verbose => $opts->{verbose},
        });
    } else {
        # Just fetch a pre-built mapping from the web
        my $url = "http://bioseed.mcs.anl.gov/~chenry/exampleObjects/defaultMap.json.gz";
        my $data;
        {
            my ($fh1, $compressed_filename) = tempfile();
            my ($fh2, $uncompressed_filename) = tempfile();
            close($fh1);
            close($fh2);
            verbose "Fetching mapping from web...\n";
            my $status = getstore($url, $compressed_filename);
            # This should probably be >= 200 <= 400? does getstore handle redirects?
            die "Unable to fetch from model_seed\n" unless($status == 200);
            verbose "Extracting...\n";
            gunzip $compressed_filename => $uncompressed_filename
                or die "Extract failed: $GunzipError\n";
            my $string;
            {
                local $/;
                open(my $fh, "<", $uncompressed_filename) || die "$!: $@";
                $string = <$fh>;
            }
            $data = JSON::XS->new->utf8->decode($string);
        }
        verbose "Validating fetched mapping...\n";
        $map = ModelSEED::MS::Mapping->new($data);
        $map->biochemistry_uuid($biochemistry->uuid);
        $map->biochemistry($biochemistry);
    }
    unless($opts->{dry}) {
        $store->save_object($alias_ref, $map);
        verbose "Saved mapping to $alias!\n";
    }
}

1;
