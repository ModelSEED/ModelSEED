package ModelSEED::utilities;
use strict;
use warnings;
use Carp qw(cluck);
use Data::Dumper;
use File::Temp qw(tempfile);
use File::Path;
use File::Copy::Recursive;
use parent qw( Exporter );
our @EXPORT_OK = qw( args usage error verbose set_verbose translateArrayOptions );
our $VERBOSE = undef; # A GLOB Reference to print verbose() calls to, or undef.

=head1 ModelSEED::utilities

Basic utility functions in the ModelSEED

=head2 Argument Processing

=head3 args

    $args = args( $required, $optional, ... );

Process arguments for a given function. C<required> is an ArrayRef
of strings that correspond to required arguments for the function.
C<optional> is a HashRef that defines arguments with default values.
The remaining values are the arguments to the function. E.g.

    sub function {
        my $self = shift;
        my $args = args ( [ "name" ], { phone => "867-5309" }, @_ );
        return $args;
    }
    # The following calls will work
    print Dumper function(name => "bob", phone => "555-555-5555");
    # Prints { name => "bob", phone => "555-555-5555" }
    print Dumper function( { name => "bob" } );
    # Prints { name => "bob", phone => "867-5309" }
    print Dumper function();
    # dies, name must be defined...

=head2 Warnings

=head3 error

    error("String");

Confesses an error to stderr.

=head2 Printing Verbosely

There are two functions in this package that control the printing of verbose
messages: C<verbose> and C<set_verbose>.

=head3 verbose

    $rtv = verbose("string one", "string two");

Call with a list of strings to print a message if the verbose flag has been
set. If the list of strings is empty, nothing is printed. Returns true if
the verbose flag is set. Otherwise returns undef.

=head3 set_verbose

    $rtv = set_verbose($arg);

Calling with a GLOB reference sets the filehandle that C<verbose()>
prints to that reference and sets the verbose flag. Calling with
the value 1 sets the verbose flag and causes C<verbose()> to print
to C<STDERR>.  Calling with any other unsets the verbose flag.
Returns the GLOB Reference that C<verbose()> will print to if the
verbose flag is set. Otherwise it returns undef.

=cut

sub set_verbose {
    my $val = shift;
    if(defined $val && ref $val eq 'GLOB') {
        $VERBOSE = $val;
    } elsif(defined $val && $val eq 1) {
        $VERBOSE = \*STDERR;
    } else {
        $VERBOSE = undef;
    }
    return $VERBOSE;
}

sub verbose {
    if ( defined $VERBOSE ) {
        print $VERBOSE join("\n",@_)."\n" if @_;
        return 1;
    } else {
        return 0;
    }
}

sub _get_args {
    my $args;
    if (ref $_[0] eq 'HASH') {
        $args = $_[0];
    } elsif(scalar(@_) % 2 == 0) {
        my %hash = @_;
        $args = \%hash;
    } elsif(@_) {
        my ($package, $filename, $line, $sub) = caller(1);
        error("Final argument to $package\:\:$sub must be a ".
              "HashRef or an Array of even length");
    } else {
        $args = {};
    }
    return $args;
}

sub usage {
    my $mandatory = shift;
    my $optional  = shift;
    my $args = _get_args(@_);
    return USAGE($mandatory, $optional, $args);
}

sub args {
    my $mandatory = shift;
    my $optional  = shift;
    my $args      = _get_args(@_);
    my @errors;
    foreach my $arg (@$mandatory) {
        push(@errors, $arg) unless defined($args->{$arg});
    }
    if (@errors) {
        my $usage = usage($mandatory, $optional, $args);
        my $missing = join("; ", @errors);
        error("Mandatory arguments $missing missing. Usage: $usage");
    }
    foreach my $arg (keys %$optional) {
        $args->{$arg} = $optional->{$arg} unless defined $args->{$arg};
    }
    return $args;
}

sub error { Carp::confess($_[0]); }

=head3 ARGS

Definition:
	ARGS->({}:arguments,[string]:mandatory arguments,{}:optional arguments);
Description:
	Processes arguments to authenticate users and perform other needed tasks

=cut

sub ARGS {
	my ($args,$mandatoryArguments,$optionalArguments,$substitutions) = @_;
	if (!defined($args)) {
	    $args = {};
	}
	if (ref($args) ne "HASH") {
		ModelSEED::utilities::ERROR("Arguments not hash");	
	}
	if (defined($substitutions) && ref($substitutions) eq "HASH") {
		foreach my $original (keys(%{$substitutions})) {
			$args->{$original} = $args->{$substitutions->{$original}};
		}
	}
	if (defined($mandatoryArguments)) {
		for (my $i=0; $i < @{$mandatoryArguments}; $i++) {
			if (!defined($args->{$mandatoryArguments->[$i]})) {
				push(@{$args->{_error}},$mandatoryArguments->[$i]);
			}
		}
	}
	ModelSEED::utilities::ERROR("Mandatory arguments ".join("; ",@{$args->{_error}})." missing. Usage:".ModelSEED::utilities::USAGE($mandatoryArguments,$optionalArguments,$args)) if (defined($args->{_error}));
	if (defined($optionalArguments)) {
		foreach my $argument (keys(%{$optionalArguments})) {
			if (!defined($args->{$argument})) {
				$args->{$argument} = $optionalArguments->{$argument};
			}
		}	
	}
	return $args;
}

=head3 USAGE

Definition:
	string = ModelSEED::utilities::USAGE([]:madatory arguments,{}:optional arguments);
Description:
	Prints the usage for the current function call.

=cut

sub USAGE {
	my ($mandatoryArguments,$optionalArguments,$args) = @_;
	my $current = 1;
	my @calldata = caller($current);
	while ($calldata[3] eq "ModelSEED::utilities::ARGS") {
		$current++;
		@calldata = caller($current);
	}
	my $call = $calldata[3];
	my $usage = "";
	if (defined($mandatoryArguments)) {
		for (my $i=0; $i < @{$mandatoryArguments}; $i++) {
			if (length($usage) > 0) {
				$usage .= "/";	
			}
			$usage .= $mandatoryArguments->[$i];
			if (defined($args)) {
				$usage .= " => ";
				if (defined($args->{$mandatoryArguments->[$i]})) {
					$usage .= $args->{$mandatoryArguments->[$i]};
				} else {
					$usage .= " => ?";
				}
			}
		}
	}
	if (defined($optionalArguments)) {
		my $optArgs = [keys(%{$optionalArguments})];
		for (my $i=0; $i < @{$optArgs}; $i++) {
			if (length($usage) > 0) {
				$usage .= "/";	
			}
			$usage .= $optArgs->[$i]."(".$optionalArguments->{$optArgs->[$i]}.")";
			if (defined($args)) {
				$usage .= " => ";
				if (defined($args->{$optArgs->[$i]})) {
					$usage .= $args->{$optArgs->[$i]};
				} else {
					$usage .= " => ".$optionalArguments->{$optArgs->[$i]};
				}
			}
		}
	}
	return $call."{".$usage."}";
}

=head3 ERROR

Definition:
	void ModelSEED::utilities::ERROR();
Description:	

=cut

sub ERROR {	
	my ($message) = @_;
    $message = "\"\"$message\"\"";
	Carp::confess($message);
}

=head3 USEERROR

Definition:
	void ModelSEED::utilities::USEERROR();
Description:	

=cut

sub USEERROR {	
	my ($message) = @_;
	print STDERR "\n".$message."\n";
	print STDERR "Critical error. Discontinuing current operation!\n";
	exit();
}

=head3 USEWARNING

Definition:
	void ModelSEED::utilities::USEWARNING();
Description:	

=cut

sub USEWARNING {	
	my ($message) = @_;
	print STDERR "\n".$message."\n\n";
}

=head3 PRINTFILE
Definition:
	void ModelSEED::utilities::PRINTFILE();
Description:	

=cut

sub PRINTFILE {
    my ($filename,$arrayRef) = @_;
    open ( my $fh, ">", $filename) || ModelSEED::utilities::ERROR("Failure to open file: $filename, $!");
    foreach my $Item (@{$arrayRef}) {
    	print $fh $Item."\n";
    }
    close($fh);
}

=head3 TOJSON

Definition:
	void ModelSEED::utilities::TOJSON(REF);
Description:	

=cut

sub TOJSON {
    my ($ref,$prettyprint) = @_;
    my $JSON = JSON->new->utf8(1);
    if (defined($prettyprint) && $prettyprint == 1) {
		$JSON->pretty(1);
    }
    return $JSON->encode($ref);
}

=head3 LOADFILE
Definition:
	void ModelSEED::utilities::LOADFILE();
Description:	

=cut

sub LOADFILE {
    my ($filename) = @_;
    my $DataArrayRef = [];
    open (my $fh, "<", $filename) || ModelSEED::utilities::ERROR("Couldn't open $filename: $!");
    while (my $Line = <$fh>) {
        $Line =~ s/\r//;
        chomp($Line);
        push(@{$DataArrayRef},$Line);
    }
    close($fh);
    return $DataArrayRef;
}

=head3 LOADTABLE
Definition:
	void ModelSEED::utilities::LOADTABLE(string:filename,string:delimiter);
Description:	

=cut

sub LOADTABLE {
    my ($filename,$delim,$headingLine) = @_;
    if (!defined($headingLine)) {
    	$headingLine = 0;
    }
    my $output = {
    	headings => [],
    	data => []
    };
    if ($delim eq "|") {
    	$delim = "\\|";	
    }
    if ($delim eq "\t") {
    	$delim = "\\t";	
    }
    my $data = ModelSEED::utilities::LOADFILE($filename);
    if (defined($data->[0])) {
    	$output->{headings} = [split(/$delim/,$data->[$headingLine])];
	    for (my $i=($headingLine+1); $i < @{$data}; $i++) {
	    	push(@{$output->{data}},[split(/$delim/,$data->[$i])]);
	    }
    }
    return $output;
}

=head3 PRINTTABLE

Definition:
	void ModelSEED::utilities::PRINTTABLE(string:filename,{}:table);
Description:

=cut

sub PRINTTABLE {
    my ($filename,$table,$delimiter) = @_;
    if (!defined($delimiter)) {
    	$delimiter = "\t";
    } 
    my $out_fh;
    if ($filename eq "STDOUT") {
    	$out_fh = \*STDOUT;
    } else {
    	open ( $out_fh, ">", $filename) || ModelSEED::utilities::USEERROR("Failure to open file: $filename, $!");
    }
	print $out_fh join($delimiter,@{$table->{headings}})."\n";
	foreach my $row (@{$table->{data}}) {
		print $out_fh join($delimiter,@{$row})."\n";
	}
    if ($filename ne "STDOUT") {
    	close ($out_fh);
    }
}

=head3 PRINTTABLESPARSE

Definition:
	void ModelSEED::utilities::PRINTTABLESPARSE(string:filename,table:table,string:delimiter,double:min,double:max);
Description:	

=cut

sub PRINTTABLESPARSE {
    my ($filename,$table,$delimiter,$min,$max) = @_;
    if (!defined($delimiter)) {
    	$delimiter = "\t";
    } 
    my $out_fh;
    if ($filename eq "STDOUT") {
    	$out_fh = \*STDOUT;
    } else {
    	open ( $out_fh, ">", $filename) || ModelSEED::utilities::USEERROR("Failure to open file: $filename, $!");
    }
    for (my $i=1; $i < @{$table->{data}};$i++) {
    	for (my $j=1; $j < @{$table->{headings}};$j++) {
    		if (defined($table->{data}->[$i]->[$j])) {
    			if (!defined($min) || $table->{data}->[$i]->[$j] >= $min) {
    				if (!defined($max) || $table->{data}->[$i]->[$j] <= $max) {
    					print $out_fh $table->{data}->[$i]->[0].$delimiter.$table->{headings}->[$j].$delimiter.$table->{data}->[$i]->[$j]."\n";
    				}
    			}
    		}	
    	}
    }
    if ($filename ne "STDOUT") {
    	close ($out_fh);
    }
}

=head3 PRINTHTMLTABLE

Definition:
    string = ModelSEED::utilities::PRINTHTMLTABLE( array[string]:headers, array[array[string]]:data, string:table_class );
Description:
    Utility method to print html table
Example:
    my $headers = ['Column 1', 'Column 2', 'Column 3'];
    my $data = [['1.1', '1.2', '1.3'], ['2.1', '2.2', '2.3'], ['3.1', '3.2', '3.3']];
    my $html = ModelSEED::utilities::PRINTHTMLTABLE( $headers, $data, 'my-class');

=cut

sub PRINTHTMLTABLE {
    my ($headers, $data, $class) = @_;

    # do some checking
    my $error = 0;
    unless (defined($headers) && ref($headers) eq 'ARRAY') {
        $error = 1;
    }

    if (defined($data) && ref($data) eq 'ARRAY') {
        foreach my $row (@$data) {
            unless (defined($row) && ref($row) eq 'ARRAY' && scalar @$row == scalar @$headers) {
                $error = 1;
            }
        }
    } else {
        $error = 1;
    }

    if ($error) {
        ERROR("Call to PRINTHTMLTABLE failed: incorrect arguments and/or argument structure");
    }

    # now create the table
    my $html = [];
    push(@$html, '<table' . (defined($class) ? ' class="' . $class . '"' : "") . ">");
    push(@$html, '<thead>');
    push(@$html, '<tr>');

    foreach my $header (@$headers) {
        push(@$html, '<th>' . $header . '</th>');
    }

    push(@$html, '</tr>');
    push(@$html, '</thead>');
    push(@$html, '<tbody>');

    foreach my $row (@$data) {
        push(@$html, '<tr>');
        foreach my $cell (@$row) {
            push(@$html, '<td>' . $cell . '</td>');
        }
        push(@$html, '</tr>');
    }

    push(@$html, '</tbody>');
    push(@$html, '</table>');

    return join("\n", @$html);
}

=head3 MODELSEEDCORE

Definition:
	string = ModelSEED::utilities::MODELSEEDCORE();
Description:
	This function converts the job specifications into a ModelDriver command and runs it
Example:

=cut

sub MODELSEEDCORE {
	return $ENV{MODEL_SEED_CORE};
}

=head3 GLPK

Definition:
	string = ModelSEED::utilities::GLPK();
Description:
	Returns location of glpk executable
Example:

=cut

sub GLPK {
	return $ENV{GLPK};
}

=head3 CPLEX

Definition:
	string = ModelSEED::utilities::CPLEX();
Description:
	Returns location of cplex executable
Example:

=cut

sub CPLEX {
	return $ENV{CPLEX};
}

=head3 parseArrayString

Definition:
	string = ModelSEED::utilities::parseArrayString({
		string => string(none),
		delimiter => string(|),
		array => [](undef)	
	});
Description:
	Parses string into array
Example:

=cut

sub parseArrayString {
	my ($args) = @_;
	$args = ModelSEED::utilities::ARGS($args,[],{
		string => "none",
		delimiter => "|",
	});
	if ($args->{delimiter} eq "|") {
		$args->{delimiter} = "\\|";
	}
	my $output = [];
	my $delim = $args->{delimiter};
	if ($args->{string} ne "none") {
		$output = [split(/$delim/,$args->{string})];
	}
	return $output;
}

=head3 translateArrayOptions

Definition:
	string = ModelSEED::utilities::translateArrayOptions({
		option => string|[],
		delimiter => string:|
	});
Description:
	Parses argument options into array
Example:

=cut

sub translateArrayOptions {
	my ($args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["option"],{
		delimiter => "|"
	});
	if ($args->{delimiter} eq "|") {
		$args->{delimiter} = "\\|";
	}
	if ($args->{delimiter} eq ";") {
		$args->{delimiter} = "\\;";
	}
	my $output = [];
	if (ref($args->{option}) eq "ARRAY") {
		foreach my $item (@{$args->{option}}) {
			push(@{$output},split($args->{delimiter},$item));
		}
	} else {
		$output = [split($args->{delimiter},$args->{option})];
	}
	return $output;
}

1;
