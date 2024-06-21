# estee-perl



## Installation


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


morbo script/estee-perl

prove -l t

prove -l t/REST.t routes -v