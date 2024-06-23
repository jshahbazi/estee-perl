use Mojo::UserAgent;

# This is a simple test script to verify that the geocode function works by testing the Nominatim API
my $ua = Mojo::UserAgent->new;
my $tx = $ua->get('http://nominatim.openstreetmap.org');
if (my $res = $tx->result) {
    print "Mojo HTTP request succeeded\n";
} else {
    my $err = $tx->error;
    print "Mojo HTTP request failed: ", $err->{code} ? "$err->{code} response: $err->{message}" : "Connection error: $err->{message}";
}