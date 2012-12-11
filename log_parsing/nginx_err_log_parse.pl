#
# Parse NGINX Error Log
#
#
#	Written by [blueCat] <felix@enescu.name>
#
#

use warnings;
use strict;

use Time::HiRes qw/ time /;
my $start = time;

use Getopt::Long;

my ( $in_file, $out_file );
my $report_interval;
my $source_ip;

my %known_ips = (
		'66.249.66.97'		=> 'Google Bot',
		'66.249.76.60'		=> 'Google Bot',
        '85.186.202.36'		=> 'Bunt HQ',
        '89.42.111.42'		=> 'citatepedia.ro',
        '89.149.12.231'		=> 'Elefant HQ',
        '89.238.194.86'		=> 'Icinga',
		'94.177.67.99'		=> 'Himself!!!',
		'131.253.27.53'		=> 'MSN Bot',
		'131.253.27.108'	=> 'MSN Bot',
		'157.56.95.138'		=> 'MSN Bot',
		'178.154.202.250'	=> 'Yandex Bot',
	);


GetOptions (
			'in=s' => \$in_file,
			'out=s' => \$out_file,
			'report:i' => \$report_interval,
			'ip:s' => \$source_ip,

			);

die "Need an input file" 
	unless defined $in_file;
	
if ( ! defined  $out_file ) {
	$out_file = $in_file . "out";
}

my $err_file = $out_file . ".err";

my $lines_to_process = 20;

if ( ! defined $report_interval ) {
	$report_interval = 20000;
}


my ($fin, $fout, $ferr);
open ($fin, "<:raw", $in_file) or die "Could not open input $in_file: $!";
open ($ferr, ">", $err_file) or die "Could not open error $err_file: $!";


my %by_hour = ();

my %int_ips_total_rq = (); # Total requests per IP per interval
my %int_files_total_rq = (); # Total requests per URI per interval
my %int_refs_total_rq = (); # Total requests per REF per interval


my $total_rq = 0;


my ($year, $month, $day, $hour, $min, $sec, $err1, $err2, $err3, $lfile, $ip, $method, $uri, $proto, $ref);
my $re;

#2012/11/05 03:12:09 [error] 6437#0: *4866258 open() "/home/elefant/public_html/robots.txt" failed (2: No such file or directory), client: 207.46.194.90, server: static.elefant.ro, request: "GET /robots.txt HTTP/1.1", host: "static.elefant.ro"
#2012/11/05 03:12:23 [error] 6437#0: *4866267 open() "/home/elefant/public_html/images/prettyPhoto/light_rounded/loader.gif" failed (2: No such file or directory), client: 86.122.60.78, server: static.elefant.ro, request: "GET /images/prettyPhoto/light_rounded/loader.gif HTTP/1.1", host: "static.elefant.ro", referrer: "http://www.elefant.ro/carti/religie-spiritualitate/spiritualitate/despre-minuni-cele-patru-iubiri-problema-durerii-194354.html"
#$re = qr!^([\d\.]+?) ([\w-]+?) \[(\d\d)/(\w\w\w)/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+0\d00\] "(\w+?) (\S+?) HTTP/(.*?)" (\d*?) (\d*?) (\d*?) ([X+-]*?) (\d*?) "(.*?)" "(.*?)"$!;
	
#$re = qr!^(\d\d\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d) \[error\] (\d+?)#0: \*(\d+?) open\(\) "(\w+?)" failed \(2: No such file or directory\), client: ([\d\.]+?), server: static.elefant.ro, request: "(\w+?) (\S+?) HTTP/(.*?)", host: "static.elefant.ro", referrer: "(\w+?)"$!;

# Cu referrer
#$re = qr!^(\d\d\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d) \[error\] (\d+?)#(\d+?): \*(\d+?) open\(\) "(\S+?)" failed \(2: No such file or directory\), client: ([\d\.]+?), server: static.elefant.ro, request: "(\S+?) (\S+?) HTTP/(.*?)", host: "static.elefant.ro", referrer: "(\S+?)"$!;

# Fara referrer
#$re = qr!^(\d\d\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d) \[error\] (\d+?)#(\d+?): \*(\d+?) open\(\) "(\S+?)" failed \(2: No such file or directory\), client: ([\d\.]+?), server: static.elefant.ro, request: "(\S+?) (\S+?) HTTP/(.*?)", host: "static.elefant.ro"(.*)$!;

# Fara referrer si cu spatii in request
$re = qr!^(\d\d\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d) \[error\] (\d+?)#(\d+?): \*(\d+?) open\(\) "(.+?)" failed \(2: No such file or directory\), client: ([\d\.]+?), server: static.elefant.ro, request: "(\S+?) (\S+?) HTTP/(.*?)", host: "static.elefant.ro"(.*)$!;

while( my $line = <$fin> )  {   
	if ( $line =~ $re ) {
		($year, $month, $day, $hour, $min, $sec, $err1, $err2, $err3, $lfile, $ip, $method, $uri, $proto, $ref) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15);
		#print "$year, $month, $day, $hour, $min, $sec, $err1, $err2, $lfile, $ip, $method, $uri, $proto\n";
		
		if ( defined $source_ip && $source_ip ne $ip ) {
			next;
		}
		
		$total_rq += 1;		
		
		$by_hour{$month}{$day}{$hour}->{rqs} += 1;

		$int_ips_total_rq{$ip}->{rqs} += 1;
	
		$int_files_total_rq{$lfile}->{rqs} += 1;
		$int_files_total_rq{$lfile}->{ref} = $ref;

		$int_refs_total_rq{$ref}->{rqs} += 1;
		
	} else {
		print STDERR "Error in line $.\n"; 
		print STDERR "$line";
		print $ferr  "Error in line $.\n"; 
		print $ferr "$line";
	};  

	if ( not $. % $report_interval ) {
		printf "Line %15s, $month $day $hour:$min\n", commify($.); 
	} 
#   last if $. == $lines_to_process;
}

my $tlines = $.;

print $ferr "File had " . commify($tlines) . " lines\n";
print STDERR "File had " . commify($tlines) . " lines\n";

close $fin;


###############################################################################
#
#
#
print_report_by_rq_nginx(\%int_ips_total_rq, "IP", \%known_ips);
print_report_by_rq_nginx(\%int_files_total_rq, "File", \%known_ips);
print_report_by_rq_nginx(\%int_refs_total_rq, "Referer", \%known_ips);





print STDERR "Writting " . $out_file . "-by-hour ... ";
open ($fout, ">:raw", $out_file . "-by-hour") or die "Could not open $out_file by-hour: $!";
print $fout "month, day_of_month, hour, requests\n";
print $fout "total, total, total," . $total_rq;
print $fout "\n";

foreach $month ( sort keys %by_hour ) {
	#print "$month: { ";
	for $day ( sort keys %{ $by_hour{$month} } ) {
		#print "$day=$by_hour{$month}{$day} ";
			for $hour ( sort keys %{ $by_hour{$month}{$day} } ) {
				print $fout "$month, $day, $hour, ";
				print $fout $by_hour{$month}{$day}{$hour}->{rqs};
	
				print $fout "\n";
			}
	}
}
close $fout;
print STDERR "Done.\n";


my $end   = time;
printf $ferr "\nWorked for %.2f secs and processed %s lines/sec (total %s)\n", ( $end - $start ), commify(int($tlines/( $end - $start ))), commify($tlines) ;
printf STDERR "\nWorked for %.2f secs and processed %s lines/sec (total %s)\n", ( $end - $start ), commify(int($tlines/( $end - $start ))), commify($tlines) ;

close $ferr;

exit;

sub commify {
	local $_  = shift;
	1 while s/^(-?\d+)(\d{3})/$1,$2/;
	return $_;
}


sub print_report_by_rq_nginx {
	my $hash_ref = shift;
	my $file_tail = shift;
	my $names = shift;

	my $categ = 'by_rq';
	
	print STDERR "Writting " . $out_file . "-$categ-$file_tail ... ";
	open ($fout, ">:raw", $out_file . "-$categ-$file_tail") or die "Could not open $out_file $categ-$file_tail: $!";
	print $fout "$file_tail, Name, Requests\n";
	print $fout "Total, -, " . $total_rq;
	print $fout "\n";

	foreach my $crt_key ( sort { $hash_ref->{$b}->{rqs} <=> $hash_ref->{$a}->{rqs} } keys %$hash_ref ) {
	
		if ( exists  $names->{ $crt_key } ) {
			print $fout "$crt_key, " . $names->{ $crt_key } . ", " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		} else {
			print $fout "$crt_key, -, " . $hash_ref->{$crt_key}->{rqs};
		}

		#print $fout "$crt_key, " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		
		if ( $file_tail eq "File" ) {
			print $fout ", " . $hash_ref->{$crt_key}->{ref} . "\n";
		} else {
			print $fout "\n";
		}
	}
	close $fout;
	print STDERR "Done.\n";
	
}


