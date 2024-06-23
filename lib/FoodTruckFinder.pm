package FoodTruckFinder;
use Mojo::Base 'Mojolicious';
use File::Spec;
use File::Basename qw(dirname basename);
use FoodTruckFinder::Database;

sub startup () {
  my $self = shift;

  # Example configuration load - this is where you would load an actual configuration file
  my $config = $self->plugin('Config', {file => 'food_truck_finder.conf'});
  $self->secrets($config->{secrets});

  # Check if the database file exists, if not, create it
  my $db_file = File::Spec->catfile($self->home, 'food_trucks.db');
  my $csv_file = File::Spec->catfile($self->home, 'data', 'Mobile_Food_Facility_Permit.csv');
  unless (-e $db_file) {
    die "File $csv_file not found. Please download the file from https://data.sfgov.org/api/views/rqzj-sfat/rows.csv and place it in the data directory."
      unless -e $csv_file;

    my $db = FoodTruckFinder::Database->new($db_file);
    $db->create_database($csv_file);
  }

  # Router
  my $r = $self->routes;

  # API routes  
  # The gets all u
  $r->under('/food_trucks')->get('/')->to(controller => 'FoodTrucks', action => 'get_food_trucks');
  $r->under('/food_trucks')->get('/by_name')->to(controller => 'FoodTrucks', action => 'get_food_truck_by_name');
  $r->under('/food_trucks')->get('/closest')->to(controller => 'FoodTrucks', action => 'find_closest_food_trucks');
  $r->under('/food_trucks')->get('/:location_id/applicant_fooditems')->to(controller => 'FoodTrucks', action => 'get_food_truck_items');  
  $r->under('/food_trucks')->get('/:location_id')->to(controller => 'FoodTrucks', action => 'get_food_truck_by_id');

  $r->get('/food_trucks/:location_id/applicant_fooditems')->to(controller => 'FoodTrucks', action => 'get_food_truck_items');
  $r->post('/food_trucks/create')->to(controller => 'FoodTrucks', action => 'create_food_truck');
  $r->put('/food_trucks/:location_id')->to(controller => 'FoodTrucks', action => 'update_food_truck');
  $r->delete('/food_trucks/:location_id')->to(controller => 'FoodTrucks', action => 'delete_food_truck');

}

1;
