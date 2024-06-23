# Estee Food Truck API

Welcome to the Estee Food Truck API! This Mojolicious-based API is designed to provide users with information about food trucks in a given area, including their locations, available food items, and more. Not only can it list the food trucks, but it can also find the closest food truck to your address! Never go hungry again!

## Prerequisites

Before you begin, ensure you have Perl installed on your system. This application has been tested with Perl 5.34.1.

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/jshahbazi/estee-perl.git
   cd estee-perl
   ```

2. Install the required Perl modules:
   ```
   cpan local::lib
   sudo cpan App::cpanminus
   cpanm --local-lib=~/perl5 Mojolicious
   cpanm Test::More
   cpanm Test::Mojo
   cpanm Test::MockModule
   cpanm Geo::Coder::OSM
   cpanm Geo::Distance
   cpanm DBI DBD::SQLite
   cpanm Text::CSV
   ```

3. Download the Mobile Food Facility Permit CSV file from [San Francisco Open Data](https://data.sfgov.org/api/views/rqzj-sfat/rows.csv) and place it in the `data` directory of the project.

## Configuration

Create a `food_truck_finder.conf` file in the project root directory with the following content:

```perl
{
  secrets => ['your_secret_key_here'],
  # Add any other configuration options here
}
```

Replace `'your_secret_key_here'` with a secure random string.

## Running the Application

To start the server:

```
morbo script/estee-perl
```

The application will be available at `http://localhost:3000`.

## Running Tests

To run the test suite:

```
prove -l t
```

If you need to debug the routes, use:

```
prove -l t routes -v
```

## API Endpoints

- `GET /food_trucks`: Get all food trucks
- `GET /food_trucks/by_name`: Get food trucks by name
- `GET /food_trucks/closest`: Find closest food trucks
- `GET /food_trucks/:location_id`: Get food truck by ID
- `GET /food_trucks/:location_id/applicant_fooditems`: Get food items for a specific truck
- `POST /food_trucks/create`: Create a new food truck
- `PUT /food_trucks/:location_id`: Update a food truck
- `DELETE /food_trucks/:location_id`: Delete a food truck

## Project Structure

- `lib/FoodTruckFinder.pm`: Main application class
- `lib/FoodTruckFinder/Controller/FoodTrucks.pm`: Controller handling food truck-related actions
- `lib/FoodTruckFinder/Database.pm`: Database interaction module
- `t/`: Test files
- `script/estee-perl`: Application script

