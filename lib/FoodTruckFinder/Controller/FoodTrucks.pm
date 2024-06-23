package FoodTruckFinder::Controller::FoodTrucks;
use Mojo::Base 'Mojolicious::Controller';
use DBI;
use Geo::Coder::OSM;
use Geo::Distance;
use FoodTruckFinder::Database;
use Data::Dump qw(dump);

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw(decode_json);
use Mojo::JSON qw(to_json);
use Scalar::Util qw(blessed);

my $db_file = "food_trucks.db";
my $db = FoodTruckFinder::Database->new($db_file);

# Create a new Geo::Distance object for calculating distances in GET /food_trucks/closest
my $geo = Geo::Distance->new();

# Convenience function to dump data to a file for debugging purposes
sub dump_to_file {
    my ($data, $filename) = @_;
    open my $fh, '>', $filename or die "Could not open file '$filename' $!";
    print $fh dump($data);
    close $fh;
}

# Geocode an address using the Nominatim API
sub geocode {
    my ($address) = @_;
    my $ua = Mojo::UserAgent->new;
    
    my $url = Mojo::URL->new('https://nominatim.openstreetmap.org/search');
    $url->query(format => 'json', q => $address, limit => 1);

    my $tx = $ua->get($url);
    if (my $res = $tx->result) {
        if ($res->is_success) {
            my $data = decode_json($res->body);
            if (@$data) {
                return {
                    lat => $data->[0]{lat},
                    lon => $data->[0]{lon}
                };
            }
        } else {
            warn "HTTP request failed: ", $res->code, " ", $res->message;
        }
    } else {
        my $err = $tx->error;
        warn "Connection error: $err->{message}";
    }
    return undef;
}


sub _connect_db {
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","");
  return $dbh;
}

# GET /food_trucks
sub get_food_trucks {
  my $self = shift;
  my @results = $db->get_all_food_trucks();
  $self->render(json => \@results);
}

# GET /food_trucks/:location_id
sub get_food_truck_by_id {
    my $self = shift;
    my $location_id = $self->param('location_id');

    eval {
        my @results = $db->get_food_truck_by_id($location_id);
        if (defined $results[0]) {
            $self->render(json => \@results);
        } else {
            $self->render(json => { message => 'No food truck found with this ID' }, status => 404);
        }
    } or do {
        my $error = $@ || 'Unknown error';
        warn "Error in get_food_truck_by_id: $error";
        # $self->app->log->error("Error in get_food_truck_by_id: $error");
        $self->render(json => { error => 'An internal error occurred' }, status => 500);
    };
}

# GET /food_trucks/by_name
sub get_food_truck_by_name {
  my $self = shift;
  my $name = $self->param('name');

  eval {
      my @results = $db->get_food_truck_by_name($name);
      if (@results) {
          $self->render(json => \@results);
      } else {
          $self->render(json => { message => 'No food truck found with this ID' }, status => 404);
      }
  } or do {
      my $error = $@ || 'Unknown error';
      warn "Error in get_food_truck_by_id: $error";
      # $self->app->log->error("Error in get_food_truck_by_id: $error");
      $self->render(json => { error => 'An internal error occurred' }, status => 500);
  };
}

# POST /food_trucks
sub create_food_truck {
  my $self = shift;
  my $data = $self->req->json;
  my $food_truck = FoodTruckFinder::Model::FoodTruck->new(%$data);

  eval {
      my $result = $db->insert_food_truck($food_truck);

      if ($result) {
          return $self->render(json => {status => 'success', message => 'Food truck created successfully'}, status => 201);
      } else {
          return $self->render(json => {status => 'error', message => 'Failed to create food truck'}, status => 500);
      }
  }
}

# PUT /food_trucks/:location_id
sub update_food_truck {
  my $self = shift;
  my $location_id = $self->param('location_id');
  my $data = $self->req->json;

  eval {
      my $result = $db->update_food_truck($location_id, $data);
      if ($result) {
          return $self->render(json => {status => 'success', message => 'Food truck updated successfully'}, status => 200);
      } else {
          warn "Failed to update food truck";
          return $self->render(json => {status => 'error', message => 'Failed to update food truck'}, status => 500);
      }
  }
}

# DELETE /food_trucks/:location_id
sub delete_food_truck {
  my $self = shift;
  my $location_id = $self->param('location_id');

  eval {
      my $result = $db->delete_food_truck($location_id);
      if ($result) {
          return $self->render(json => {status => 'success', message => 'Food truck deleted successfully'}, status => 200);
      } else {
          return $self->render(json => {status => 'error', message => 'Failed to delete food truck'}, status => 500);
      }
  }
}

# GET /food_trucks/:location_id/applicant_fooditems
sub get_food_truck_items {
    my $self = shift;
    my $location_id = $self->param('location_id');

    eval {
        my @results = $db->get_food_truck_by_id($location_id);
        if (@results && defined $results[0]) {
            my $food_truck = $results[0];
            
            # Split food_items string into an array, trim whitespace
            my @food_items = map { s/^\s+|\s+$//g; $_ } split /,/, ($food_truck->{food_items} || '');
            
            $self->render(json => {
                location_id => $food_truck->{location_id},
                applicant => $food_truck->{applicant},
                food_items => \@food_items
            });
        } else {
            # $self->app->log->warn("No food truck found with ID: $location_id");
            $self->render(json => {error => 'Food truck not found'}, status => 404);
        }
    };
    if ($@) {
        # $self->app->log->error("Database error: $@");
        $self->render(json => {error => 'Internal server error'}, status => 500);
    }
}

# GET /food_trucks/closest
sub find_closest_food_trucks {
  my $self = shift;
  my $address = $self->param('address');

  eval {
    my @food_trucks = $db->get_all_food_trucks();
    if (!@food_trucks) {
        return $self->render(json => {error => 'Food trucks not found'}, status => 404);
    }

    # Calculate the latitude and longitude of the source address using the Nominatim API
    my $location = geocode($address);
    if (!$location) {
        return $self->render(json => {error => 'Invalid address'}, status => 400);
    }

    my @distances;
    for my $food_truck (@food_trucks) {
        my ($latitude, $longitude, $applicant, $address, $facility_type, $food_items, $status, $schedule, $dayshours, $location_description);

        # Check to make sure it's a blessed FoodTruckFinder::Model::FoodTruck object        
        if (blessed($food_truck) && $food_truck->isa('FoodTruckFinder::Model::FoodTruck')) {
            $latitude = $food_truck->latitude;
            $longitude = $food_truck->longitude;
            $applicant = $food_truck->applicant;
            $address = $food_truck->address;
            $facility_type = $food_truck->facility_type;
            $food_items = $food_truck->food_items;
            $status = $food_truck->status;
            $schedule = $food_truck->schedule;
            $dayshours = $food_truck->dayshours;
            $location_description = $food_truck->location_description;
        } else {
            dump($food_truck);
            warn "Unknown food truck format";
        }

        # Calculate the distance between the source address and the food truck
        my $distance = $geo->distance('mile', 
                              $location->{lon}, $location->{lat}, 
                              $longitude, $latitude);

        push @distances, { 
            distance => $distance, 
            truck => {
                applicant => $applicant,
                address => $address,
                food_items => $food_items,
                latitude => $latitude,
                longitude => $longitude,
                schedule => $schedule,
                status => $status
            }
        }
      }

      # Sort the distances and get the 3 closest food trucks
      @distances = sort { $a->{distance} <=> $b->{distance} } @distances;
      my @closest_trucks = @distances[0..2];    

      $self->render(json => {
          source_address => $address,
          source_coordinates => {
              latitude => $location->{lat},
              longitude => $location->{lon}
          },
          closest_trucks => \@closest_trucks
      });
  };
  if ($@) {
      $self->app->log->error("Error in find_closest_food_trucks: $@");
      $self->render(json => {error => 'Internal server error'}, status => 500);
  }
}

1;
