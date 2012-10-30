#/bin/perl
#
# Cut Apache Log in common format from start interval to end interval
#
# 
#
#	Written by [blueCat] <felix@enescu.name>
#

use warnings;
use strict;

use Time::HiRes qw/ time /;
my $start = time;

use Time::Local;
use Getopt::Long;

# Format YYYY-MM-DD HH:MM:SS
my ( $int_start, $int_end );
my ( $interval_start, $interval_end );
my ( $in_file, $out_file );
my $report_interval;

GetOptions (
			'start=s' => \$int_start,
			'end=s' => \$int_end,
			'in=s' => \$in_file,
			'out=s' => \$out_file,
			'report:i' => \$report_interval,
			);


my $err_file = $out_file . ".err";

# 					Format YYYY-MM-DD HH:MM:SS
if ( $int_start =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
	#timelocal($sec,$min,$hour,$mday,$mon,$year);
	$interval_start = timelocal($6, $5, $4, $3, $2, $1);
} else {
	die "Interval start incorect: $int_start (needed YYYY-MM-DD HH:MM:SS)";
}

# 					Format YYYY-MM-DD HH:MM:SS
if ( $int_end =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
	#timelocal($sec,$min,$hour,$mday,$mon,$year);
	$interval_end = timelocal($6, $5, $4, $3, $2, $1);
} else {
	die "Interval end incorect: $int_start (needed YYYY-MM-DD HH:MM:SS)";
}

#my $lines_to_process = 200000;

if ( ! defined $report_interval ) {
	$report_interval = 20000;
}


my ($fin, $fout, $ferr);
open ($fin, "<:raw", $in_file) or die "Could not open input $in_file: $!";
open ($fout, ">:raw", $out_file) or die "Could not open output $out_file: $!";
open ($ferr, ">", $err_file) or die "Could not open error $err_file: $!";

my %mons = ('Jan'=>1,'Feb'=>2,'Mar'=>3,'Apr'=>4,'May'=>5,'Jun'=>6,'Jul'=>7,'Aug'=>8,'Sep'=>9,'Oct'=>10,'Nov'=>11,'Dec'=>12);
my ($ip, $unk, $user, $mday, $month, $year, $hour, $min, $sec, $rq, $hcode, $size, $ref, $ua);

my $rq_time;

my $re = qr!^([\d\.]+?) ([\w-]+?) ([@\.\w-]+?) \[(\d\d)/(\w\w\w)/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+0300\] "(.*?)" (\d*?) ([\d-]*?) "(.*?)" "(.*?)"$!;
while( my $line = <$fin> )  {   
   if ( $line =~ $re ) {
		($ip, $unk, $user, $mday, $month, $year, $hour, $min, $sec, $rq, $hcode, $size, $ref, $ua) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14);

		$rq_time = timelocal($sec, $min, $hour, $mday, $mons{$month}, $year);
#		print "$ip, $unk, $user, $dom, $month, $year, $hour, $min, $sec, $rq, $hcode, $size, $ref, $ua\n";
#		print "$mday, $month, $year, $hour, $min, $sec - $interval_start = $rq_time = $interval_end\n";
		
		if ($interval_start <= $rq_time) {
			last if $rq_time > $interval_end;
			print $fout "$line";
		}
	} else {
		print STDERR "Error in line $.\n"; 
		print STDERR "$line";
		print $ferr  "Error in line $.\n"; 
		print $ferr "$line";
	};  
	
	if ( not $. % $report_interval ) {
		printf STDERR "Line %15s, $year $month $mday $hour:$min\n", commify($.); 
	} 
#	last if $. == $lines_to_process;
}

my $tlines = $.;

close $fin;
close $fout;

my $end   = time;

print $ferr "File had " . commify($tlines) . " lines\n";
print STDERR "File had " . commify($tlines) . " lines\n";


printf $ferr "\nWorked for %.2f secs and processed %s lines/sec (total %s)\n", ( $end - $start ), commify(int($tlines/( $end - $start ))), commify($tlines) ;
printf STDERR "\nWorked for %.2f secs and processed %s lines/sec (total %s)\n", ( $end - $start ), commify(int($tlines/( $end - $start ))), commify($tlines) ;

close $ferr;

exit;

sub commify {
	local $_  = shift;
	1 while s/^(-?\d+)(\d{3})/$1,$2/;
	return $_;
}

