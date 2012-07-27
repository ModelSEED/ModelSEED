use strict;
use warnings;
use lib 'lib';
use Test::More;
use Module::Pluggable search_path => ['ModelSEED'];
# Test for compliation errors in all plugins under ModelSEED.
my $testCount = 0;
my $skipModules = {
    "ModelSEED::Database::MongoDBSimple" => 1,
};
sub test {
    SKIP: {
        skip "Skipping $_ see t/require.t for details", 1 if $skipModules->{$_};
        require_ok($_);  
    };
    $testCount += 1;
}
test $_ for __PACKAGE__->plugins;
done_testing($testCount);
