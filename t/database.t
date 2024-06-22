use strict;
use warnings;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use DBI;
use FoodTruckFinder::Database;
use FoodTruckFinder::Model::FoodTruck;

BEGIN {
    use_ok('FoodTruckFinder::Database');
    use_ok('FoodTruckFinder::Model::FoodTruck');
}

# Setup a temporary database file
my $tempdir = tempdir(CLEANUP => 1);
my $db_file = File::Spec->catfile($tempdir, 'food_trucks_test.db');
my $csv_file = 'data/Mobile_Food_Facility_Permit.csv';

my $db = FoodTruckFinder::Database->new($db_file);

# Test creating a table
ok($db->create_table(), 'create_table method works');

# Test inserting a food truck
ok($db->create_database($csv_file), 'create_database method works');

# Test fetching all food trucks
my @food_trucks = $db->get_all_food_trucks();
is(scalar @food_trucks, 481, 'get_all_food_trucks returns correct number of trucks');
is($food_trucks[0]->applicant, 'The Chai Cart', 'get_all_food_trucks returns correct data');

# Test fetching a food truck by ID
my $food_truck = $db->get_food_truck_by_id(755221);
is($food_truck->{applicant}, 'Fruteria Serrano', 'get_food_truck_by_id returns correct data');

# Test fetching a food truck by name
my @food_trucks_by_name = $db->get_food_truck_by_name('Fruteria Serrano');
is(scalar @food_trucks_by_name, 1, 'get_food_truck_by_name returns correct number of trucks');
is($food_trucks_by_name[0]->{applicant}, 'Fruteria Serrano', 'get_food_truck_by_name returns correct data');

# Test inserting a mocked food truck
my $mocked_truck = FoodTruckFinder::Model::FoodTruck->new(
    location_id              => 123455,
    applicant                => 'Mocked Truck',
    facility_type            => 'Truck',
    cnn                      => 123456,
    location_description     => 'Mocked Location',
    address                  => '123 Mocked St',
    blocklot                 => '00010001',
    block                    => '0001',
    lot                      => '0001',
    permit                   => '15MFF-0001',
    status                   => 'REQUESTED',
    food_items               => 'Hot Dogs, Burgers',
    x                        => 6013916.72,
    y                        => 2117244.027,
    latitude                 => 37.774929,
    longitude                => -122.419416,
    schedule                 => '',
    dayshours                => '',
    NOISent                  => '',
    approved                 => '',
    received                 => '',
    prior_permit             => '',
    expiration_date          => '',
    location                 => '',
    fire_prevention_districts => 1,
    police_districts         => 1,
    supervisor_districts     => 1,
    zip_codes                => 94103,
    neighborhoods_old        => 1,
);
$db->insert_food_truck($mocked_truck);
$food_truck = FoodTruckFinder::Model::FoodTruck->new($db->get_food_truck_by_id(123455));
is($food_truck->applicant, 'Mocked Truck', 'insert_food_truck works');


# Test updating the mocked food truck
my $updated_truck = FoodTruckFinder::Model::FoodTruck->new(
    location_id              => 123455,
    applicant                => 'Updated Truck',
    facility_type            => 'Truck',
    cnn                      => 123456,
    location_description     => 'Updated Location',
    address                  => '123 Updated St',
    blocklot                 => '00010001',
    block                    => '0001',
    lot                      => '0001',
    permit                   => '15MFF-0001',
    status                   => 'REQUESTED',
    food_items               => 'Hot Dogs, Burgers',
    x                        => 6013916.72,
    y                        => 2117244.027,
    latitude                 => 37.774929,
    longitude                => -122.419416,
    schedule                 => '',
    dayshours                => '',
    NOISent                  => '',
    approved                 => '',
    received                 => '',
    prior_permit             => '',
    expiration_date          => '',
    location                 => '',
    fire_prevention_districts => 1,
    police_districts         => 1,
    supervisor_districts     => 1,
    zip_codes                => 94103,
    neighborhoods_old        => 1,
);
$db->update_food_truck(123455, $updated_truck);
$food_truck = FoodTruckFinder::Model::FoodTruck->new($db->get_food_truck_by_id(123455));
is($food_truck->applicant, 'Updated Truck', 'update_food_truck works');

# Test deleting a food truck
ok($db->delete_food_truck(123455), 'delete_food_truck works');
$food_truck = $db->get_food_truck_by_id(123455);
is($food_truck, undef, 'delete_food_truck successfully deletes truck');

done_testing();
