#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoodTruckFinder::Model::FoodTruck;

# Create a new FoodTruck object
my $food_truck = FoodTruckFinder::Model::FoodTruck->new(
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
);

print "Applicant: ", $food_truck->applicant, "\n";
