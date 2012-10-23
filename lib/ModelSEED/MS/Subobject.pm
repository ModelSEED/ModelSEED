package ModelSEED::MS::Subobject;

sub TIESCALAR {
    my ($class, $linkclass) = @_;

    return bless { CLASS => $linkclass, DATA => undef, OBJECT => undef }, $class;
}

sub FETCH {
    my ($self) = @_;

    # now we actually create the object
}

sub STORE {
    my ($self, $value) = @_;

    # must be either an object of type CLASS, or a HashRef (HASH) of data
    if (ref($value) eq "HASH") {
        # store the data
    } elsif (ref($value) eq $self->{CLASS}) {
        $self->{OBJECT} = $value;
    } else {
        # error
    }
}
