package ModelSEED::App::mseed::Command::save;
use strict;
use common::sense;
use base 'ModelSEED::App::MSEEDBaseCommand';
use JSON::XS;
use Class::Autouse qw(
    ModelSEED::Reference
);

sub abstract { return "Save JSON data to a reference"; }
sub usage_desc { return "ms save [ref] < JSON"; }

sub options {
    return (
        ["file|f:s", "Filename with JSON data"],
        ["help|h|?", "Print this usage information"],
    );
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};

    $self->usage_error("Must provide a reference") unless @$args == 1;

    my $refstr = shift @$args;
    my $ref = ModelSEED::Reference->new(ref => $refstr);
    my $ref_type = $ref->base();
    my $ref_id = $ref->alias_string();

    my $fh = *STDIN;
    if($opts->{file}) {
        open($fh, "<", $opts->{file}) or
            die "Could not open file: " .$opts->{file} . ", $@\n";
    }

    my @lines = <$fh>;
    my $str = join("\n",@lines);
    my $data = JSON::XS->new->utf8(1)->decode($str);
    close($fh);
    $self->save_data({type=>$ref_type, reference=>$refstr ,data=>$data});
}

1;
