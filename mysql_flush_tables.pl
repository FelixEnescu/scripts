#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use DBI;

my %args = (
            verbose => 0,
            user     => $ENV{USER},
            hostname  => '127.0.0.1',
            port     => 3306
           );

GetOptions(\%args,
           'verbose!',
           'user=s',
           'password=s',
           'hostname=s',
           'port=i',
           'database=s@'
          );


my $dbh = DBI->connect("dbi:mysql:hostname=$args{hostname};port=$args{port}",
                        $args{user}, $args{password})
  or die DBI->errstr;

my @dbs = $dbh->func('_ListDBs');

for my $db (@dbs) {
  next if uc($db) eq 'INFORMATION_SCHEMA';
  $dbh->do("use $db");
  my $tables = $dbh->selectcol_arrayref("show tables");
  for (1..2) {
    for my $table (@$tables) {
      print "flushing $db.$table\n";
      $dbh->do("flush table $table");
    }
  }
}

print "flushing all\n";
$dbh->do("flush tables");

