# Unit tests for ModelSEED::Database::MongoDBSimple
use strict;
use warnings;
use Test::More;
use ModelSEED::Database::MongoDBSimple;
use ModelSEED::Auth::Basic;
use ModelSEED::Auth::Public;
use ModelSEED::Reference;
use Data::UUID;
use Data::Dumper;
my $test_count = 0;

sub _uuid {
    return Data::UUID->new->create_str();
}

# Test _merge_hash
{
    my $a = { a => [1], b => [2] };
    my $b = { c => [3], d => [4] };
    is_deeply ModelSEED::Database::MongoDBSimple::_merge_hash(
        $a, $b), {  a => [1], b => [2], c => [3], d => [4] };
    is_deeply ModelSEED::Database::MongoDBSimple::_merge_hash(
        $a, {}), $a;
    is_deeply ModelSEED::Database::MongoDBSimple::_merge_hash(
        $b, {}), $b;
    is_deeply ModelSEED::Database::MongoDBSimple::_merge_hash(
        {}, $a), $a;
    $test_count += 4;
}

# Basic object initialization
{
    my $mongo = ModelSEED::Database::MongoDBSimple->new({ db_name => 'test' });
    ok defined($mongo), "Should create a class instance";
    ok defined($mongo->conn), "Should have connection to database";
    ok defined($mongo->db), "Should have database object";
    $test_count += 3;
}

{
    my $db = ModelSEED::Database::MongoDBSimple->new( db_name => 'test',);
    my $type = "biochemistry";
    # Delete the database to get it clean and fresh
    $db->delete_database;
    $db->init_database;
    my $ref1 = ModelSEED::Reference->new({
        ref => "biochemistry/alice/one"
    });
    my $ref2 = ModelSEED::Reference->new({
        ref => "biochemistry/alice/two"
    });
    my $auth = ModelSEED::Auth::Basic->new({
            username => "alice",
            password => "password",
    });
    my $pub = ModelSEED::Auth::Public->new();
    my $obj1 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj2 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    # Tests on non-existant objects
    ok !$db->has_data($ref1), "Database is empty";
    is $db->get_data($ref1, $auth), undef, "Cannot get non-existant object";
    is $db->has_data($ref1, $auth), 0, "Stat non-existant object returns false";
    ok !$db->delete_data($ref1, $auth), "Cannot delete non-existant object";
    $test_count += 4;

    # Tests on existing objects
    ok $db->save_data($ref1, $obj1, $auth), "Save object returns success";
    ok $db->has_data($ref1, $auth), "Has object after save";
    is_deeply $db->get_data($ref1, $auth), $obj1, "Get object returns same object";
    $test_count += 3;

    # Test permissions, not authorized
    ok !$db->has_data($ref1, $pub), "Test has_data, unauthorized";
    is undef, $db->get_data($ref1, $pub), "Test get_data, unauthorized";
    ok !$db->save_data($ref1, $obj2, $pub), "Shouldn't be able to save with another person's alias";
    is_deeply $db->get_data($ref1, $auth), $obj1, "Unauthorized save did not go through";
    $test_count += 4;

    # Test permissons, set to public (unauthorized)
    ok !$db->set_public($ref1, 1, $pub), "set_public unauthorized should fail";
    ok !$db->add_viewer($ref1, 'bob', $pub), "remove_viewer unauthorized should fail";
    ok !$db->remove_viewer($ref1, 'bob', $pub), "add_viewer unauthorized should fail";
    ok !$db->alias_owner($ref1, $pub), "getting alias owner, unauthorized should fail";
    ok !$db->alias_viewers($ref1, $pub), "getting alias viewers, unauthorized should fail";
    ok !$db->alias_public($ref1, $pub), "getting alias public, unauthorized should fail";
    ok !$db->alias_uuid($ref1, $pub), "getting alias uuid, unauthorized should fail";
    $test_count += 7;

    # Set permissions to public, authorized
    ok $db->set_public($ref1, 1, $auth), "set_public sould return success, auth";
    ok $db->alias_public($ref1, $auth), "alias_public sould return success, auth";
    is_deeply $db->alias_viewers($ref1, $auth), [], "no viewers on new alias";
    ok $db->add_viewer($ref1, "bob", $auth), "add_vewier should return success, auth"; 
    is_deeply $db->alias_viewers($ref1, $auth), ["bob"], "no viewers on new alias";
    is $db->alias_owner($ref1, $auth), "alice", "owner should be right on alias";
    $test_count += 6;

    # Test getting, for perm: public
    ok $db->has_data($ref1, $pub), "Test has_data, unauthorized, now public";
    is_deeply $db->get_data($ref1, $pub), $obj1, "Test get_data, unauthorized, now public";
    ok !$db->save_data($ref1, $obj2, $pub), "Shouldn't be able to save with another person's alias";
    is_deeply $db->get_data($ref1, $pub), $obj1, "Unauthorized save did not go through";
    $test_count += 4;

    # Test alter permissiosn, public, unauthorized
    ok !$db->set_public($ref1, 1, $pub), "set_public public, unauthorized should fail";
    ok !$db->add_viewer($ref1, 'bob', $pub), "remove_viewer public, unauthorized should fail";
    ok !$db->remove_viewer($ref1, 'bob', $pub), "add_viewer public, unauthorized should fail";
    is $db->alias_owner($ref1, $pub), "alice", "getting alias owner, public, unauthorized should work";
    is_deeply $db->alias_viewers($ref1, $pub), ["bob"], "getting alias viewers, public, unauthorized should work";
    is $db->alias_public($ref1, $pub), 1, "getting alias public, public, unauthorized should work";
    ok $db->alias_uuid($ref1, $pub), "getting alias uuid, public, unauthorized should work";
    $test_count += 7;

    # Test permissions for bob
    my $bob = ModelSEED::Auth::Basic->new({ username => "bob", password => "password" });
    $db->set_public($ref1, 0, $auth);
    is $db->alias_public($ref1, $auth), 0, "Should set correctly";
    ok $db->has_data($ref1, $bob), "Test has_data, bob";
    is_deeply $db->get_data($ref1, $bob), $obj1, "Test get_data, bob";
    ok !$db->save_data($ref1, $obj2, $bob), "Shouldn't be able to save with another person's alias";
    is_deeply $db->get_data($ref1, $bob), $obj1, "Unauthorized save did not go through";

    $test_count += 5;
}

## Testing alias listing
{
    my $db = ModelSEED::Database::MongoDBSimple->new( db_name => 'test',);
    my $type = "biochemistry";
    # Delete the database to get it clean and fresh
    $db->db->drop();
    my $alice = ModelSEED::Auth::Basic->new(
        username => "alice",
        password => "password",
    );
    my $pub = ModelSEED::Auth::Public->new();
    my $bob = ModelSEED::Auth::Basic->new(
        username => "bob",
        password => "password"
    );
    my $charlie = ModelSEED::Auth::Basic->new(
        username => "charlie",
        password => "password"
    );
    # Set up permissions:
    # alias  type          owner  viewers  public
    # one    biochemistry  alice           1
    # two    biochemistry  alice  bob      1
    # three  biochemistry  alice
    # four   model         bob    alice    
    # five   model         alice  bob      1
    # six    biochemistry  bob    alice     
    # c      model         charlie
    # c      biochemistry  charlie
    my $ref1 = ModelSEED::Reference->new(ref => "biochemistry/alice/one");
    my $ref2 = ModelSEED::Reference->new(ref => "biochemistry/alice/two");
    my $ref3 = ModelSEED::Reference->new(ref => "biochemistry/alice/three");
    my $ref4 = ModelSEED::Reference->new(ref => "model/bob/four");
    my $ref5 = ModelSEED::Reference->new(ref => "model/alice/five");
    my $ref6 = ModelSEED::Reference->new(ref => "biochemistry/bob/six");
    my $ref7 = ModelSEED::Reference->new(ref => "biochemistry/charlie/c");
    my $ref8 = ModelSEED::Reference->new(ref => "model/charlie/c");
    my $obj1 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj2 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj3 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj4 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj5 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj6 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj7 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj8 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };

    $db->save_data($ref1, $obj1, $alice);
    $db->save_data($ref2, $obj2, $alice);
    $db->save_data($ref3, $obj3, $alice);
    {
        $db->add_viewer($ref2, "bob", $alice);
        $db->set_public($ref1, 1, $alice);
        $db->set_public($ref2, 1, $alice);
    }
    $db->save_data($ref4, $obj4, $bob);
    $db->save_data($ref5, $obj5, $alice);
    $db->save_data($ref6, $obj6, $bob);
    {
        $db->add_viewer($ref4, "alice", $bob);
        $db->add_viewer($ref5, "bob", $alice);
        $db->set_public($ref5, 1, $alice);
        $db->add_viewer($ref6, "alice", $bob);
    }
    $db->save_data($ref7, $obj7, $charlie);
    $db->save_data($ref8, $obj8, $charlie);
   
    # Now test get_aliases for alice
    {
        my $all = $db->get_aliases(undef, $alice);
        my $bio = $db->get_aliases("biochemistry", $alice);
        my $hers = $db->get_aliases("biochemistry/alice", $alice);
        is scalar(@$all), 6, "Should get 6 aliases for alice, undef";
        is scalar(@$bio), 4, "Should get 4 aliases for alice, 'biochemistry'";
        is scalar(@$hers), 3, "Should get 3 aliases for alice, 'biochemistry/alice'";
    }
    # And for bob
    {
        my $all  = $db->get_aliases(undef, $bob);
        my $bio  = $db->get_aliases("biochemistry", $bob);
        my $hers = $db->get_aliases("biochemistry/alice", $bob);
        my $his  = $db->get_aliases("model/bob", $bob);
        is scalar(@$all), 5, "Should get 5 aliases for bob, undef";
        is scalar(@$bio), 3, "Should get 3 aliases for bob, 'biochemistry'";
        is scalar(@$hers), 2, "Should get 2 aliases for bob, 'biochemistry/alice'";
        is scalar(@$his), 1, "Should get 1 aliases for bob, 'model/bob'";
    }
    # And for public
    {
        my $all  = $db->get_aliases(undef, $pub);
        my $bio  = $db->get_aliases("biochemistry", $pub);
        my $model  = $db->get_aliases("model", $pub);
        my $b_hers = $db->get_aliases("biochemistry/alice", $pub);
        my $b_his = $db->get_aliases("biochemistry/bob", $pub);
        my $m_hers = $db->get_aliases("model/alice", $pub);
        my $m_his = $db->get_aliases("model/bob", $pub);

        is scalar(@$all), 3, "Should get 3 aliases for pub, undef";
        is scalar(@$bio), 2, "Should get 2 aliases for pub, 'biochemistry'";
        is scalar(@$model), 1, "Should get 1 aliases for pub, 'model'";
        is scalar(@$b_hers), 2, "Should get 2 aliases for pub, 'biochemistry/alice'";
        is scalar(@$b_his), 0, "Should get 0 aliases for pub, 'biochemistry/bob'";
        is scalar(@$m_hers), 1, "Should get 1 aliases for pub, 'model/alice'";
        is scalar(@$m_his), 0, "Should get 0 aliases for pub, 'model/bob'";
    }
    $test_count += 14;

    # Now test that get_aliases for charlie returns correct ammount for different refs
    {
        my $bio    = $db->get_aliases("biochemistry", $charlie);
        my $model  = $db->get_aliases("model", $charlie);
        my $all    = $db->get_aliases(undef, $charlie);
        is scalar(@$bio), 3, "Should get 3 for charlie 2 public + 1 private";
        is scalar(@$model), 2, "Should get 2 for charlie 1 public + 1 private";
        is scalar(@$all), 5, "Should get 5 for charlie, the total of last two tests";

        $test_count += 3;
    }
}

# Test ancestor / descendant functions
{
    my $db = ModelSEED::Database::MongoDBSimple->new( db_name => 'test',);
    my $type = "biochemistry";
    # Delete the database to get it clean and fresh
    $db->db->drop();
    my $alice = ModelSEED::Auth::Basic->new(
        username => "alice",
        password => "password",
    );
    my $pub = ModelSEED::Auth::Public->new();
    my $bob = ModelSEED::Auth::Basic->new(
        username => "bob",
        password => "password"
    );
    # Reference Structure:
    # alias  type          owner  viewers  public
    # one    biochemistry  alice           1
    # two    biochemistry  alice  bob      0
    # three  biochemistry  alice
    # four
    my $ref1 = ModelSEED::Reference->new(ref => "biochemistry/alice/one");
    my $ref2 = ModelSEED::Reference->new(ref => "biochemistry/alice/two");
    my $ref3 = ModelSEED::Reference->new(ref => "biochemistry/alice/three");
    my $ref4 = ModelSEED::Reference->new(ref => "biochemistry/alice/four");
    my $obj1 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj2 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj3 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $obj4 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    my $ref1_old_uuid = $obj1->{uuid};
    my $ref2_old_uuid = $obj2->{uuid};
    my $obj1_uuid_ref = ModelSEED::Reference->new(
        type => "biochemistry",
        uuid => $obj1->{uuid}
    );
    my $obj2_uuid_ref = ModelSEED::Reference->new(
        type => "biochemistry",
        uuid => $obj2->{uuid}
    );
    my $obj1_anc_graph = { $ref1_old_uuid => [] };
    my $obj2_anc_graph = { $ref2_old_uuid => [] };
    my $obj3_anc_graph = { $obj3->{uuid} => [ $ref1_old_uuid ], $ref1_old_uuid => [] };
    my $obj4_anc_graph = { $obj4->{uuid} => [ $ref2_old_uuid ], $ref2_old_uuid => []  };

    # test ancestors, ancestor_graph and descendants on undefined ref
    is $db->ancestors($ref4, $alice), undef, "Should have undef from non-existant object";
    is $db->ancestor_graph($ref4, $alice), undef, "Should have undef from non-existant object";
    is $db->ancestors($ref4, $bob), undef, "Should have undef from non-existant object";
    is $db->ancestor_graph($ref4, $bob), undef, "Should have undef from non-existant object";
    is $db->ancestors($ref4, $pub), undef, "Should have undef from non-existant object";
    is $db->ancestor_graph($ref4, $pub), undef, "Should have undef from non-existant object";
    $test_count += 6;

    # test with no parent uuids (and test with permissions)
    $db->save_data($ref1, $obj1, $alice);
    $db->save_data($ref2, $obj2, $alice);
    {
        $db->set_public($ref1, 1, $alice);
        $db->add_viewer($ref2, "bob", $alice);
    }
    is_deeply $db->ancestors($ref1, $alice), [];
    is_deeply $db->ancestor_graph($ref1, $alice), $obj1_anc_graph;
    is_deeply $db->ancestors($ref1, $bob), [];
    is_deeply $db->ancestor_graph($ref1, $bob), $obj1_anc_graph;
    is_deeply $db->ancestors($ref1, $pub), [];
    is_deeply $db->ancestor_graph($ref1, $pub), $obj1_anc_graph;
    $test_count += 6;

    is_deeply $db->ancestors($ref2, $alice), [];
    is_deeply $db->ancestor_graph($ref2, $alice), $obj2_anc_graph;
    is_deeply $db->ancestors($ref2, $bob), [];
    is_deeply $db->ancestor_graph($ref2, $bob), $obj2_anc_graph;
    is_deeply $db->ancestors($ref2, $pub), undef;
    is_deeply $db->ancestor_graph($ref2, $pub), undef;
    $test_count += 6;

    # test with a single parent on each:
    # x---x <= one
    #
    # x---x <= two
    $db->save_data($ref1, $obj3, $alice);
    $db->save_data($ref2, $obj4, $alice);
    
    is_deeply $db->ancestors($ref1, $alice), [ $ref1_old_uuid ];
    is_deeply $db->ancestor_graph($ref1, $alice), $obj3_anc_graph;
    is_deeply $db->ancestors($ref1, $bob), [ $ref1_old_uuid ];
    is_deeply $db->ancestor_graph($ref1, $bob), $obj3_anc_graph;
    is_deeply $db->ancestors($ref1, $pub), [$ref1_old_uuid];
    is_deeply $db->ancestor_graph($ref1, $pub), $obj3_anc_graph;
    $test_count += 6;

    is_deeply $db->descendants($ref1, $alice), [];
    is_deeply $db->descendants($ref1, $bob), [];
    is_deeply $db->descendants($ref1, $pub), [];
    is_deeply $db->descendants($obj1_uuid_ref, $alice), [ $obj3->{uuid} ];
    is_deeply $db->descendants($obj1_uuid_ref, $bob), [ $obj3->{uuid} ];
    is_deeply $db->descendants($obj1_uuid_ref, $pub), [ $obj3->{uuid} ];
    $test_count += 6;

    is_deeply $db->ancestors($ref2, $pub), undef;
    is_deeply $db->ancestor_graph($ref2, $pub), undef;
    is_deeply $db->ancestors($ref2, $alice), [ $ref2_old_uuid ];
    is_deeply $db->ancestor_graph($ref2, $alice), $obj4_anc_graph;
    is_deeply $db->ancestors($ref2, $bob), [ $ref2_old_uuid ];
    is_deeply $db->ancestor_graph($ref2, $bob), $obj4_anc_graph;
    $test_count += 6;

    is_deeply $db->descendants($ref2, $alice), [];
    is_deeply $db->descendants($ref2, $bob), [];
    is_deeply $db->descendants($obj2_uuid_ref, $alice), [ $obj4->{uuid} ];
    is_deeply $db->descendants($obj2_uuid_ref, $bob), [ $obj4->{uuid} ];
    $test_count += 4;

    # test with a merged object
    #  x---x 
    #      +---------x <= one 
    #  x---x <= two
    my $merge = { uuid => _uuid(), ancestor_uuids => [ $obj3->{uuid}, $obj4->{uuid} ] };
    $db->save_data($ref1, $merge, $alice, { is_merge => 1 });
    my $expect_ancestors = [ $obj1->{uuid}, $obj2->{uuid}, $obj3->{uuid}, $obj4->{uuid} ];
    my $got_ancestors    = $db->ancestors($ref1, $alice);
    is_deeply { map { $_ => 1 } @$got_ancestors }, { map { $_ => 1 } @$expect_ancestors };
    is_deeply scalar( @{$db->ancestor_graph($ref1,$alice)->{$merge->{uuid}}}), 2;
    $test_count += 2;
}

# Test init_database, delete_database operations
{
    my $db = ModelSEED::Database::MongoDBSimple->new( db_name => 'test',);
    ok $db->init_database, "First init_database call should work";
    ok $db->init_database, "Second init_database call should also work";
    ok $db->delete_database, "Call to delete database should work";

    ok $db->init_database, "Next call to init_database after delete should work";
    my $ref1 = ModelSEED::Reference->new({
        ref => "biochemistry/alice/one"
    });
    my $alice = ModelSEED::Auth::Basic->new({
            username => "alice",
            password => "password",
    });
    my $obj1 = { uuid => _uuid(), compounds => [{ uuid => _uuid() }] };
    ok $db->save_data($ref1, $obj1, $alice), "Save object in init_ and delete_ tests should work";
    my $all = $db->get_aliases(undef, $alice);
    is scalar @$all, 1, "Should get one object from database";
    ok $db->delete_database({ keep_data => 1 }), "Call to delete_database with keep_data should return ok";
    ok $db->init_database, "Call to init after delete w/ keep_data should return ok";
    my $all2 = $db->get_aliases(undef, $alice);
    is scalar @$all2, 1, "Should get one object from db after delete w/ keep_data";
    ok $db->delete_database, "Should return ok again from delete database";
    ok $db->init_database, "Should return ok again from init database";
    my $all3 = $db->get_aliases(undef, $alice);
    is scalar @$all3, 0, "Should get no objects from db after delete without keep_data";
    ok $db->delete_database; 
    ok $db->delete_database, "Test double-delete";
    $test_count += 14; 
}
done_testing($test_count);
