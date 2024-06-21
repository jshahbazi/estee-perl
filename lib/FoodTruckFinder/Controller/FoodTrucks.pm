package FoodTruckFinder::Controller::FoodTrucks;
use Mojo::Base 'Mojolicious::Controller';
# use Mojo::JSON qw(encode_json decode_json);
use DBI;
use Geo::Coder::OSM;
use Geo::Distance;
use FoodTruckFinder::Database;
use Data::Dump qw(dump);

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw(decode_json);

my $db_file = "food_trucks.db";
my $db = FoodTruckFinder::Database->new($db_file);

my $geo = Geo::Distance->new();

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
  # warn "get_food_trucks";
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
            # warn "Found food truck:", @results;
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
  # warn "get_food_truck_by_name:-",$name,"-";

  eval {
      my @results = $db->get_food_truck_by_name($name);
      # dump(@results);
      if (@results) {
          # warn "Found food truck by  name:", @results;
          $self->render(json => \@results);
      } else {
        # warn "No food truck found with this name";
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

  # dump($data);

  # return $self->render(json => {status => 'ok', message => 'Test'}, status => 200);
  eval {
      my $result = $db->update_food_truck($location_id, $data);
      # warn "Result:-",$result,"-";
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
  dump($address);
  eval {
      my @results = $db->get_all_food_trucks();
      
      if (!@results) {
          $self->render(json => {error => 'Food trucks not found'}, status => 404);
          return;
      }

      my $location = geocode($address);
      warn "Location:-",dump($location),"-";
      if (!$location) {
          $self->render(json => {error => 'Invalid address'}, status => 400);
          return;
      }

      my @distances;
      foreach my $truck (@results) {
          my $distance = $geo->distance('kilometer', $location->{lat}, $location->{lon}, $truck->latitude, $truck->longitude);
          push @distances, { distance => $distance, truck => $truck };
      }

      @distances = sort { $a->{distance} <=> $b->{distance} } @distances;
      my @closest_trucks = map { $_->{truck} } @distances[0..2];
      $self->render(json => \@closest_trucks);
  }
}

1;
