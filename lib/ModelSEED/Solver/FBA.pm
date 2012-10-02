package ModelSEED::Solver::FBA;

=head1 ModelSEED::Solver::FBA

Interface for running Flux Balance Analysis jobs, including
gapfilling and gapgeneration jobs. 

=head2 METHODS

=head3 new

    Reads in configuration, if none supplied, defaults
    to configuration in ModelSEED::Configuration

=head3 start

    my $token = $solver->start($fba);

=head3 stop

    my $status = $solver->stop($token);

=head3 done

    my $bool = $solver->done($token);

=head3 getResults

    my $fba = $solver->getResults($token);

=cut
use strict;
use common::sense;
use ModelSEED::Configuration;
use ModelSEED::Auth::Factory;
use ModelSEED::Store;
use Module::Load qw(load);

sub new {
    my $class = shift;
    my $args;
    # Handle config passed in as list or hash-ref
    if(ref($_[0]) eq 'HASH') {
        $args = shift @_;
    } else {
        my %args = @_;
        $args = \%args;
    }
    my ($store, $class);
    # Construct a ModelSEED::Store if one doesn't exist already
    if (defined $args && defined($args->{store})) {
        $store = $args->{store};
    } else {
        my $auth = ModelSEED::Auth::Factory->new->from_config;
        $store = ModelSEED::Store->new(auth => $auth);
    }
    # If USE_CLUSTER is true, use clustered solver
    if (defined $args && defined($args->{class})) {
        $class = $args->{class};
    } else {
        my $conf = ModelSEED::Configuration->new;
        my $options = $conf->user_options;
        if ($options->{USE_CLUSTER}) {
            $class = "ModelSEED::Solver::FBA::Cluster";
        } else {
            $class = "ModelSEED::Solver::FBA::Inline";
        }
    }
    load $class;
    return $class->new(store => $store);
}

1;
