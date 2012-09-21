use strict;
use warnings;
use Bash::Completion::Plugin::Test;
use Test::More tests => 2;

my $tester = Bash::Completion::Plugin::Test->new(
    plugin => 'Bash::Completion::Plugins::ModelSEED',
);

$tester->check_completions('ms imp^', [qw( import )]);
$tester->check_completions('ms lo^', [qw( logout login )]);

