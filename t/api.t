use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/../lib"; # Adjust the path to your lib directory
use Test::Number::Delta within => 1e-6;

# Test::Mojo object
my $t = Test::Mojo->new('FoodTruckFinder');

# Test GET /food_trucks
$t->get_ok('/food_trucks')
  ->status_is(200);

# Test GET /food_trucks/:location_id
$t->get_ok('/food_trucks/755221')
  ->status_is(200);

$t->get_ok('/food_trucks/1')
  ->status_is(404);

# Test GET /food_trucks/by_name
$t->get_ok('/food_trucks/by_name?name=Fruteria')
  ->status_is(200);

$t->get_ok('/food_trucks/by_name?name=Test Truck')
  ->status_is(404);  

# Test POST /food_trucks
$t->post_ok('/food_trucks/create' => json => {
    location_id => 1,
    applicant => 'Test Truck',
    facility_type => 'Truck',
    cnn => 123456,
    location_description => 'Test Location',
    address => '123 Test St',
    blocklot => '00010001',
    block => '0001',
    lot => '0001',
    permit => '15MFF-0001',
    status => 'REQUESTED',
    food_items => 'Hot Dogs, Burgers',
    x => 6013916.72,
    y => 2117244.027,
    latitude => 37.774929,
    longitude => -122.419416,
    schedule => '',
    dayshours => '',
    NOISent => '',
    approved => '',
    received => '',
    prior_permit => '',
    expiration_date => '',
    location => '',
    fire_prevention_districts => 1,
    police_districts => 1,
    supervisor_districts => 1,
    zip_codes => 94103,
    neighborhoods_old => 1,
})->status_is(201);

# Test GET /food_trucks/:location_id again after insertion
$t->get_ok('/food_trucks/1')
  ->status_is(200)
  ->json_is([{
      location_id => 1,
      applicant => 'Test Truck',
      facility_type => 'Truck',
      cnn => 123456,
      location_description => 'Test Location',
      address => '123 Test St',
      blocklot => '00010001',
      block => '0001',
      lot => '0001',
      permit => '15MFF-0001',
      status => 'REQUESTED',
      food_items => 'Hot Dogs, Burgers',
      x => 6013916.72,
      y => 2117244.027,
      latitude => 37.774929,
      longitude => -122.419416,
      schedule => '',
      dayshours => '',
      NOISent => '',
      approved => '',
      received => '',
      prior_permit => '',
      expiration_date => '',
      location => '',
      fire_prevention_districts => 1,
      police_districts => 1,
      supervisor_districts => 1,
      zip_codes => 94103,
      neighborhoods_old => 1,
  }]);

# Test GET /food_trucks/by_name after insertion
$t->get_ok('/food_trucks/by_name?name=Test Truck')
  ->status_is(200)
  ->json_is([
      {
          location_id => 1,
          applicant => 'Test Truck',
          facility_type => 'Truck',
          cnn => 123456,
          location_description => 'Test Location',
          address => '123 Test St',
          blocklot => '00010001',
          block => '0001',
          lot => '0001',
          permit => '15MFF-0001',
          status => 'REQUESTED',
          food_items => 'Hot Dogs, Burgers',
          x => 6013916.72,
          y => 2117244.027,
          latitude => 37.774929,
          longitude => -122.419416,
          schedule => '',
          dayshours => '',
          NOISent => '',
          approved => '',
          received => '',
          prior_permit => '',
          expiration_date => '',
          location => '',
          fire_prevention_districts => 1,
          police_districts => 1,
          supervisor_districts => 1,
          zip_codes => 94103,
          neighborhoods_old => 1,
      }
  ]);

# Test PUT /food_trucks/:location_id
$t->put_ok('/food_trucks/1' => json => {
    location_id => 1,
    applicant => 'Updated Truck',
    facility_type => 'Truck',
    cnn => 123456,
    location_description => 'Updated Location',
    address => '123 Updated St',
    blocklot => '00010001',
    block => '0001',
    lot => '0001',
    permit => '15MFF-0001',
    status => 'REQUESTED',
    food_items => 'Hot Dogs, Burgers',
    x => 6013916.72,
    y => 2117244.027,
    latitude => 37.774929,
    longitude => -122.419416,
    schedule => '',
    dayshours => '',
    NOISent => '',
    approved => '',
    received => '',
    prior_permit => '',
    expiration_date => '',
    location => '',
    fire_prevention_districts => 1,
    police_districts => 1,
    supervisor_districts => 1,
    zip_codes => 94103,
    neighborhoods_old => 1,
})->status_is(200);

# Test GET /food_trucks/:location_id after update
$t->get_ok('/food_trucks/1')
  ->status_is(200)
  ->json_is([
    {
      location_id => 1,
      applicant => 'Updated Truck',
      facility_type => 'Truck',
      cnn => 123456,
      location_description => 'Updated Location',
      address => '123 Updated St',
      blocklot => '00010001',
      block => '0001',
      lot => '0001',
      permit => '15MFF-0001',
      status => 'REQUESTED',
      food_items => 'Hot Dogs, Burgers',
      x => 6013916.72,
      y => 2117244.027,
      latitude => 37.774929,
      longitude => -122.419416,
      schedule => '',
      dayshours => '',
      NOISent => '',
      approved => '',
      received => '',
      prior_permit => '',
      expiration_date => '',
      location => '',
      fire_prevention_districts => 1,
      police_districts => 1,
      supervisor_districts => 1,
      zip_codes => 94103,
      neighborhoods_old => 1,
  }]
  );

# Test: Food truck found
$t->get_ok('/food_trucks/1/applicant_fooditems')
  ->status_is(200)
  ->json_is('/location_id', 1)
  ->json_is('/applicant', 'Updated Truck')
  ->json_is('/food_items', ['Hot Dogs', 'Burgers']);

# Test: Food truck not found
$t->get_ok('/food_trucks/2/applicant_fooditems')
  ->status_is(404);

# Test DELETE /food_trucks/:location_id
$t->delete_ok('/food_trucks/1')
  ->status_is(200);

# Test GET /food_trucks/:location_id after delete
$t->get_ok('/food_trucks/1')
  ->status_is(404);

# Test GET /food_trucks/closest
$t->get_ok('/food_trucks/closest?address=227 BUSH ST, San Francisco, CA 94104')
  ->status_is(200)
  ->json_has('/source_address')
  ->json_has('/source_coordinates/latitude')
  ->json_has('/source_coordinates/longitude')
  ->json_has('/closest_trucks')
  ->json_is('/source_address' => '227 BUSH ST, San Francisco, CA 94104')
  ->json_is('/closest_trucks/1/truck/address' => '115 SANSOME ST');

# Use Test::Number::Delta to check floating point numbers
my $response = $t->tx->res->json;
delta_ok($response->{source_coordinates}{latitude}, 37.79099512131908, 'Latitude is close enough');
delta_ok($response->{source_coordinates}{longitude}, -122.40151717834377, 'Longitude is close enough');
delta_ok($response->{closest_trucks}[0]{distance}, 0.0222907660097768, 'First truck distance is close enough');
delta_ok($response->{closest_trucks}[1]{distance}, 0.0396710238753308, 'Second truck distance is close enough');

# Check the number of closest trucks
my $closest_trucks = $response->{closest_trucks};
is(scalar @$closest_trucks, 3, 'Correct number of closest trucks');


# Test Invalid address
$t->get_ok('/food_trucks/closest?address=Invalid Address')
  ->status_is(400)
  ->json_is('/error', 'Invalid address');



done_testing();
