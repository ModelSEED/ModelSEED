########################################################################
# ModelSEED::Database::Composite - Composite implementation of Database
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-05-01
########################################################################

=head1 ModelSEED::Database::Composite

A composite implementation of the L<ModelSEED::Database> interface.

=head1 Methods

=head2 new

    my $db = ModelSEED::Database::Composite->new(\%);

This initializes a Storage interface object. This accepts a hash
reference to configuration details. Currently this only accepts
two parameters:

=over

=item C<databases>

An array reference (C<\@>) where each element in the array is either
a L<ModelSEED::Database> implementation or a hash reference (C<\%>)
like the following:

    {
        class => "ModelSEED::Database::*"
        ...
    }

C<class> must be a valid class that implements the L<ModelSEED::Database>
role. All other attributes are used as arguments to the constructor
for that class.

=item C<use_config>

A boolean flag. If this is set, use the configuration details in
L<ModelSEED::Configuration> under the "stores" key as arguments
like in C<databases>.

=back

See L<ModelSEED::Database> for details on the following methods:

=head3 has_data

=head3 get_data

=head3 save_data

=head3 delete_data

=head3 find_data

=head3 get_alias

=head3 get_aliases

=head3 alias_owner

=head3 alias_public

=head3 alias_viewers

=head3 update_alias 

=head3 add_viewer

=head3 remove_viewer

=head3 remove_alias

=head3 set_public

=head3 Concepts

Since this acts as a composite over a number of database instances,
it behaves a little differently from a standard L<ModelSEED::Database>
implementation. For most "read" functions, this class simply calls
those functions on each database in it's composite. However, some
functions will stop searching after they find a result.  For "write"
functions, e.g.  C<save_object>, it will call this on all databases
in the composite.

List of "read" functions:

    has_data *
    get_data *
    get_data *
    find_data
    get_aliases 
    alias_viewers *
    alias_owner   *
    alias_public  *
    

Note that any function with a (*) stops searching after it finds
results.  So, for example C<has_object> may not query all databases.

List of "write" functions:

    save_data
    delete_data

    create_alias
    update_alias
    add_viewer
    remove_viewer
    set_public

=head2 Methods

See L<ModelSEED::Database> for methods.

=cut

package ModelSEED::Database::Composite;
use Moose;
use Moose::Util::TypeConstraints;
use ModelSEED::Exceptions;
use Try::Tiny;
use Class::Autouse qw(
    ModelSEED::Configuration
    ModelSEED::Database::FileDB
    ModelSEED::Database::MongoDBSimple
    JSON::XS
);
with 'ModelSEED::Database';

role_type 'DB', { role => 'ModelSEED::Database' };
has databases => ( is => 'ro', isa => 'ArrayRef[DB]', required => 1 );
has primary   => ( is => 'ro', isa => 'DB', builder => '_build_primary', lazy => 1);

around BUILDARGS => sub {
    my $orig  = shift @_;
    my $class = shift @_;
    my $args;
    # get the arguments passed into constructor 
    if(ref($_[0]) eq 'HASH') {
        $args = shift @_;
    } else {
        $args = { @_ };
    }
    # use configuration if that's what we want
    if(defined($args->{use_config}) && $args->{use_config}) {
        my $Config = ModelSEED::Configuration->new();
        ModelSEED::Exception::NoDatabase->throw() unless defined $Config->config->{stores};
        $args->{databases} = [ @{$Config->config->{stores}} ];
    }
    ModelSEED::Exception::NoDatabase->throw() unless @{$args->{databases}};
    foreach my $db (@{$args->{databases}}) {
        next if (ref($db) ne 'HASH' && $db->does("ModelSEED::Database"));
        my %config = %$db;
        try {
            my $class = $db->{class};
            $db = $class->new($db);
            die unless ref($db) && $db->does("ModelSEED::Database")
        } catch {
            ModelSEED::Exception::DatabaseConfigError->throw(
                dbName => $config{name},
                configText => JSON::XS->new->pretty(1)->encode(\%config),
            );
        };
    }
    return $class->$orig($args);
};

sub ancestors {
    my $self = shift @_;
    my $ancestors = [];
    foreach my $db (@{$self->databases}) {
        push(@{$ancestors},@{$db->ancestors(@_)});
    }
    return $ancestors;
}

sub descendants {
    my $self = shift @_;
    my $descendants = [];
    foreach my $db (@{$self->databases}) {
        push(@{$descendants},@{$db->descendants(@_)});
    }
    return $descendants;
}

sub init_database {
    ModelSEED::Expcetion::Basic->throw(
        message => <<ND
Cannot call init_database on ModelSEED::Database::Composite.
Call this function on the specific, non-composite,
database instance instead.
ND
    );
}

sub delete_database {
    ModelSEED::Exception::Basic->throw(
        message => <<ND
Cannot call delete_database on ModelSEED::Database::Composite.
Call this function on the specific, non-composite,
database instance instead.
ND
    );
}

sub has_data {
    my $self = shift @_;
    my $val = 0;
    foreach my $db (@{$self->databases}) {
        $val = $db->has_data(@_); 
        last if $val;
    }
    return $val;
}

sub get_data {
    my $self = shift @_;
    my $obj = undef;
    foreach my $db (@{$self->databases}) {
        $obj = $db->get_data(@_);
        last if $obj;
    }
    return $obj;
}

sub save_data {
    my $self = shift @_;
    my $rtv;
    foreach my $db (@{$self->databases}) {
        $rtv = $db->save_data(@_);
    }
    return $rtv;
}

sub delete_data {
    my $self = shift @_;
    my $deleteCount = 0;
    foreach my $db (@{$self->databases}) {
        $deleteCount += $db->delete_data(@_);
    }
    return $deleteCount;
}

sub find_data {
    my $self = shift @_;
    my $found = [];
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        push(@$found, @{$db->find_data(@args)});
    }
    return $found;
}

# Alias Functions

sub get_aliases {
    my $self = shift @_;
    my $aliases = [];
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        push(@$aliases, @{$db->get_aliases(@args)});
    }
    return $aliases;
}

sub update_alias {
    my $self = shift @_;
    return $self->primary->update_alias(@_);
}

sub alias_viewers {
    my $self = shift @_;
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        my $val = $db->get_viewers(@args);
        return $val if(defined($val));
    }
}
sub alias_owner {
    my $self = shift @_;
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        my $val = $db->get_owner(@args);
        return $val if(defined($val));
    }
}
sub alias_public {
    my $self = shift @_;
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        my $val = $db->get_public(@args);
        return $val if(defined($val));
    }
}

sub add_viewer {
    my $self = shift @_;
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        my $val = $db->add_viewer(@args);
        return $val if($val);
    }
    return 0;
}

sub remove_viewer {
    my $self = shift @_;
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        my $val = $db->remove_viewer(@args);
        return $val if($val);
    }
    return 0;
}

sub set_public {
    my $self = shift @_;
    foreach my $db (@{$self->databases}) {
        my @args = @_;
        my $val = $db->set_public(@args);
        return $val if($val);
    }
    return 0;
}


sub _build_primary {
    my $self = shift @_;
    return $self->databases->[0];
}

1;
