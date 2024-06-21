package FoodTruckFinder::Database;
use strict;
use warnings;
use DBI;
use Text::CSV;
use FoodTruckFinder::Model::FoodTruck;
use Data::Dump qw(dump);

sub new {
    my ($class, $db_name) = @_;
    my $self = { db_name => $db_name };
    bless $self, $class;
    return $self;
}

sub to_int {
    my $value = shift;
    return defined $value && $value =~ /\S/ ? int($value) : undef;
}

sub to_float {
    my $value = shift;
    return defined $value && $value =~ /\S/ ? $value + 0 : undef;
}

sub to_num {
    my $value = shift;
    return defined $value && $value =~ /\S/ ? $value + 0 : 0;
}


sub create_database {
    my ($self, $csv_file) = @_;
    $self->create_table();
    open my $fh, '<', $csv_file or die "Could not open file '$csv_file' $!";
    my $csv = Text::CSV->new({ binary => 1 });
    $csv->column_names($csv->getline($fh));
    
    while (my $row = $csv->getline_hr($fh)) {
        my $food_truck = FoodTruckFinder::Model::FoodTruck->new(
            location_id              => to_int($row->{location_id}),
            applicant                => $row->{Applicant} // '',
            facility_type            => $row->{FacilityType} // '',
            cnn                      => to_int($row->{cnn}),
            location_description     => $row->{LocationDescription} // '',
            address                  => $row->{Address} // '',
            blocklot                 => $row->{blocklot} // '',
            block                    => $row->{block} // '',
            lot                      => $row->{lot} // '',
            permit                   => $row->{permit} // '',
            status                   => $row->{Status} // '',
            food_items               => $row->{FoodItems} // '',
            x                        => to_num($row->{X}),
            y                        => to_num($row->{Y}),
            latitude                 => to_num($row->{Latitude}),
            longitude                => to_num($row->{Longitude}),
            schedule                 => $row->{Schedule} // '',
            dayshours                => $row->{dayshours} // '',
            NOISent                  => $row->{NOISent} // '',
            approved                 => $row->{Approved} // '',
            received                 => $row->{Received} // '',
            prior_permit             => $row->{PriorPermit} // '',
            expiration_date          => $row->{ExpirationDate} // '',
            location                 => $row->{Location} // '',
            fire_prevention_districts => to_int($row->{'Fire Prevention Districts'}),
            police_districts         => to_int($row->{'Police Districts'}),
            supervisor_districts     => to_int($row->{'Supervisor Districts'}),
            zip_codes                => to_int($row->{'Zip Codes'}),
            neighborhoods_old        => to_int($row->{'Neighborhoods (old)'}),
        );
        # warn "Inserting food truck: ", $food_truck->applicant, "\n"; # Debugging
        $self->insert_food_truck($food_truck);
    }
    close $fh;
}

sub create_table {
    my $self = shift;
    my $dbh = $self->_connect_db();
    $dbh->do(<<'EOSQL');
CREATE TABLE IF NOT EXISTS food_trucks (
    location_id INTEGER PRIMARY KEY,
    applicant TEXT,
    facility_type TEXT,
    cnn INTEGER,
    location_description TEXT,
    address TEXT,
    blocklot TEXT,
    block TEXT,
    lot TEXT,
    permit TEXT,
    status TEXT,
    food_items TEXT,
    x REAL,
    y REAL,
    latitude REAL,
    longitude REAL,
    schedule TEXT,
    dayshours TEXT,
    NOISent TEXT,
    approved TEXT,
    received TEXT,
    prior_permit TEXT,
    expiration_date TEXT,
    location TEXT,
    fire_prevention_districts INTEGER,
    police_districts INTEGER,
    supervisor_districts INTEGER,
    zip_codes INTEGER,
    neighborhoods_old INTEGER
)
EOSQL
    $dbh->disconnect();
}

sub insert_food_truck {
    my ($self, $food_truck) = @_;

    my $dbh = $self->_connect_db();
    my $sql = <<'EOSQL';
INSERT INTO food_trucks (location_id, applicant, facility_type, cnn, location_description, address, blocklot, block, lot,
    permit, status, food_items, x, y, latitude, longitude, schedule, dayshours, NOISent, approved, received,
    prior_permit, expiration_date, location, fire_prevention_districts, police_districts, supervisor_districts,
    zip_codes, neighborhoods_old) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
EOSQL
    my $sth = $dbh->prepare($sql);

    my @values = (
        $food_truck->location_id, 
        $food_truck->applicant, 
        $food_truck->facility_type, 
        $food_truck->cnn, 
        $food_truck->location_description, 
        $food_truck->address, 
        $food_truck->blocklot, 
        $food_truck->block, 
        $food_truck->lot, 
        $food_truck->permit, 
        $food_truck->status, 
        $food_truck->food_items, 
        $food_truck->x, 
        $food_truck->y, 
        $food_truck->latitude, 
        $food_truck->longitude, 
        $food_truck->schedule, 
        $food_truck->dayshours, 
        $food_truck->NOISent, 
        $food_truck->approved, 
        $food_truck->received, 
        $food_truck->prior_permit, 
        $food_truck->expiration_date, 
        $food_truck->location, 
        $food_truck->fire_prevention_districts, 
        $food_truck->police_districts, 
        $food_truck->supervisor_districts, 
        $food_truck->zip_codes, 
        $food_truck->neighborhoods_old
    );

    # Debugging: Print the values being inserted
    # warn "Values: ", join(", ", map { defined $_ ? $_ : 'NULL' } @values), "\n";

    my $result = $sth->execute(@values);

    # warn "Result:", $result;
    
    # Debugging: Confirm that the food truck has been inserted
    # warn "Inserted food truck: ", $food_truck->applicant, "\n";
    
    $dbh->disconnect();
    return $result;
}

sub get_all_food_trucks {
    my $self = shift;
    my $dbh = $self->_connect_db();
    my @results;

    eval {
        my $sth = $dbh->prepare('SELECT * FROM food_trucks');
        $sth->execute();

        while (my $row = $sth->fetchrow_hashref) {
            # warn "Row: ", join(", ", map { defined $_ ? $_ : 'NULL' } values %$row); # Debugging
            push @results, FoodTruckFinder::Model::FoodTruck->new(%$row);
        }
    };

    if ($@) {
        warn "Error fetching food trucks: $@";
    }

    $dbh->disconnect();
    return \@results;
}

sub get_food_truck_by_id {
    my ($self, $location_id) = @_;
    # warn "Getting food truck by id:", $location_id;
    my $dbh = $self->_connect_db();
    my $food_truck;

    eval {
        my $sth = $dbh->prepare('SELECT * FROM food_trucks WHERE location_id = ?');
        $sth->execute($location_id);
        my $row = $sth->fetchrow_hashref;
        if ($row && keys %$row) {
            $food_truck = $row
        } else {
            $food_truck = undef;
        }
    };

    if ($@) {
        warn "Error fetching food truck by id: $@";
    }

    $dbh->disconnect();
    return $food_truck;
}

sub get_food_truck_by_name {
    my ($self, $name) = @_;
    my $dbh = $self->_connect_db();
    my @results;

    eval {
        my $sth = $dbh->prepare('SELECT * FROM food_trucks WHERE applicant LIKE ?');
        $sth->execute('%' . $name . '%');
        
        while (my $row = $sth->fetchrow_hashref) {
            push @results, $row #FoodTruckFinder::Model::FoodTruck->new(%$row);
        }
    };

    if ($@) {
        warn "Error fetching food truck by name: $@";
    }
    $dbh->disconnect();
    # dump(@results);
    return @results;
}


sub update_food_truck {
    my ($self, $location_id, $food_truck_input) = @_;
    my $existing_truck = $self->get_food_truck_by_id($location_id);
    return undef unless $existing_truck;

    my $food_truck = FoodTruckFinder::Model::FoodTruck->new(%$food_truck_input);
    
    my $dbh = $self->_connect_db();
    my $sql = <<'EOSQL';
UPDATE food_trucks SET applicant = ?, facility_type = ?, cnn = ?, location_description = ?, address = ?, blocklot = ?, block = ?, lot = ?, permit = ?, 
status = ?, food_items = ?, x = ?, y = ?, latitude = ?, longitude = ?, schedule = ?, dayshours = ?, NOISent = ?, approved = ?, received = ?, 
prior_permit = ?, expiration_date = ?, location = ?, fire_prevention_districts = ?, police_districts = ?, supervisor_districts = ?, 
zip_codes = ?, neighborhoods_old = ? WHERE location_id = ?
EOSQL
    my $sth = $dbh->prepare($sql);
    $sth->execute(
        $food_truck->applicant, $food_truck->facility_type, $food_truck->cnn, $food_truck->location_description, 
        $food_truck->address, $food_truck->blocklot, $food_truck->block, $food_truck->lot, $food_truck->permit, 
        $food_truck->status, $food_truck->food_items, $food_truck->x, $food_truck->y, $food_truck->latitude, 
        $food_truck->longitude, $food_truck->schedule, $food_truck->dayshours, $food_truck->NOISent, $food_truck->approved, 
        $food_truck->received, $food_truck->prior_permit, $food_truck->expiration_date, $food_truck->location, 
        $food_truck->fire_prevention_districts, $food_truck->police_districts, $food_truck->supervisor_districts, 
        $food_truck->zip_codes, $food_truck->neighborhoods_old, $location_id
    );
    $dbh->disconnect();
    return $food_truck;
}

sub delete_food_truck {
    my ($self, $location_id) = @_;
    my $existing_truck = $self->get_food_truck_by_id($location_id);
    return undef unless $existing_truck;

    my $dbh = $self->_connect_db();
    my $sth = $dbh->prepare('DELETE FROM food_trucks WHERE location_id = ?');
    $sth->execute($location_id);
    $dbh->disconnect();
    return 1;
}

sub _connect_db {
    my $self = shift;
    return DBI->connect("dbi:SQLite:dbname=" . $self->{db_name},"","");
}

1;
