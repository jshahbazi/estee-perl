# Estee Food Truck API (in Perl!)

Welcome to the Estee Food Truck API! This Mojolicious-based Perl API is designed to provide users with information about food trucks in a given area, including their locations, available food items, and more. Not only can it list the food trucks, but it can also find the closest food truck to your address! Never go hungry again!

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

Note that this isn't actually used for anything at the moment, but I wanted to include it for completeness.

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

Add -v for more verbose output:

```
prove -l t -v
```

If you need to debug the routes, use:

```
prove -l t routes -v
```


## API Endpoints

### GET /food_trucks

Retrieve all food trucks.

| Detail | Description |
|--------|-------------|
| Response | Array of food truck objects |

### GET /food_trucks/:location_id

Retrieve a specific food truck by its location ID.

| Detail | Description |
|--------|-------------|
| Parameters | `location_id`: The unique identifier of the food truck location |
| Response | Food truck object or 404 if not found |

### GET /food_trucks/by_name

Search for food trucks by name.

| Detail | Description |
|--------|-------------|
| Parameters | `name`: The name (or part of the name) of the food truck |
| Response | Array of matching food truck objects or 404 if not found |

### GET /food_trucks/closest

Find the closest food trucks to a given address.

| Detail | Description |
|--------|-------------|
| Parameters | `address`: The address to search from |
| Response | JSON object with source address, coordinates, and closest trucks |

Example response:
```json
{
  "source_address": "227 BUSH ST, San Francisco, CA 94104",
  "source_coordinates": {
    "latitude": 37.79099512131908,
    "longitude": -122.40151717834377
  },
  "closest_trucks": [
    {
      "distance": 0.0222907660097768,
      "truck": {
        "applicant": "Truck Name",
        "address": "123 Food St",
        "food_items": "Hot Dogs, Burgers",
        "latitude": 37.123456,
        "longitude": -122.654321,
        "schedule": "Mon-Fri 10am-3pm",
        "status": "APPROVED"
      }
    },
    {
      "distance": 0.0222907660097768,
      "truck": {
        "applicant": "Truck Name",
        "address": "123 Food St",
        "food_items": "Hot Dogs, Burgers",
        "latitude": 37.123456,
        "longitude": -122.654321,
        "schedule": "Mon-Fri 10am-3pm",
        "status": "APPROVED"
      }
    },
    {
      "distance": 0.0222907660097768,
      "truck": {
        "applicant": "Truck Name",
        "address": "123 Food St",
        "food_items": "Hot Dogs, Burgers",
        "latitude": 37.123456,
        "longitude": -122.654321,
        "schedule": "Mon-Fri 10am-3pm",
        "status": "APPROVED"
      }
    },    
  ]
}
```

Note: The response includes the three closest food trucks.

### GET /food_trucks/:location_id/applicant_fooditems

Get the applicant and food items for a specific food truck.

| Detail | Description |
|--------|-------------|
| Parameters | `location_id`: The unique identifier of the food truck location |
| Response | JSON object with location_id, applicant, and food_items |

Example response:
```json
{
  "location_id": 1,
  "applicant": "Truck Name",
  "food_items": ["Hot Dogs", "Burgers"]
}
```

Note: Food items are returned as an array, split from the comma-separated string in the database.

### POST /food_trucks/create

Create a new food truck.

| Detail | Description |
|--------|-------------|
| Request Body | JSON object with food truck details |
| Response | 201 Created with success message if created, 500 if failed |

Example response:
```json
{
  "status": "success",
  "message": "Food truck created successfully"
}
```

### PUT /food_trucks/:location_id

Update an existing food truck.

| Detail | Description |
|--------|-------------|
| Parameters | `location_id`: The unique identifier of the food truck location |
| Request Body | JSON object with updated food truck details |
| Response | 200 OK with success message if updated, 500 if failed |

Example response:
```json
{
  "status": "success",
  "message": "Food truck updated successfully"
}
```

### DELETE /food_trucks/:location_id

Delete a food truck.

| Detail | Description |
|--------|-------------|
| Parameters | `location_id`: The unique identifier of the food truck location |
| Response | 200 OK with success message if deleted, 500 if failed |

Example response:
```json
{
  "status": "success",
  "message": "Food truck deleted successfully"
}
```

## Project Structure

- `lib/FoodTruckFinder.pm`: Main application class
- `lib/FoodTruckFinder/Controller/FoodTrucks.pm`: Controller handling food truck-related actions
- `lib/FoodTruckFinder/Database.pm`: Database interaction module
- `t/`: Test files
- `script/estee-perl`: Application script

## Design Thoughts

- Overall this wasn't as difficult as I thought it would be.  Of course, the Mojolicious library really did all the work, but that's a good thing - at the very least it shows that there are modern libraries for Perl (which I didn't think there were).  I followed the same approach as I did in my Python version: https://github.com/jshahbazi/estee, and really the only thing that gave me trouble was getting the array vs scalar references and everything that goes with them.  I wasn't surprised by it - this harkens back to older systems languages so it makes sense that it's there.  We've gotten spoiled over the years with languages like Python.

- I probably should have put stuff in the config and loaded it in each file.

- I included a couple of test scripts in the script/ directory 

- The Test::Mojo module made things surprisingly easy for tests.  Overall the tests were probably the easiest part of it, and the most helpful, of course.  One thing to note that is a little hacky is that for the api.t testing, I launch a full application which creates a real database and all that.

- The routing tripped me up a little bit at first because I originally wasn't using 'under'.  It would match under the first possible path and just hang.  FastAPI in Python got me a little spoiled on how easy it is to work with, but once I learned about using 'under', then it was a lot easier.