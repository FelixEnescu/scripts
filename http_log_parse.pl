#
# Parse Apache Log
#
#
#	Written by [blueCat] <felix@enescu.name>
#
#	First cut the intereval of interest from file with cut_interval
#

use warnings;
use strict;

use Time::HiRes qw/ time /;
my $start = time;

use Getopt::Long;

my ( $in_file, $out_file );
my $report_interval;
my $source_ip;
my $nginx;
my $combined;
my $apache;

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
			'nginx' => \$nginx,
			'combined' => \$combined,
			'apache' => \$apache,
			);

if ( ! defined  $out_file ) {
	$out_file = $in_file . "out";
}

my $err_file = $out_file . ".err";

my $lines_to_process = 20000;

if ( ! defined $report_interval ) {
	$report_interval = 20000;
}


my ($fin, $fout, $ferr);
open ($fin, "<:raw", $in_file) or die "Could not open input $in_file: $!";
open ($ferr, ">", $err_file) or die "Could not open error $err_file: $!";


my %by_hour = ();

my %int_ips_total_rq = (); # Total requests per IP per interval
my %int_uris_total_rq = (); # Total requests per URI per interval
my %int_urisnotok_total_rq = (); # Total requests per REF per interval
my %int_refs_total_rq = (); # Total requests per REF per interval
my %int_uas_total_rq = (); # Total requests per UA per interval


my $total_rq = 0;
my $total_size = 0;
my $total_time = 0;
my $duration_factor;

my ($ip, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $rqtime, $keepalive, $kaidx, $ref, $ua);

#my $re = qr!^([\d\.]+?) ([\w-]+?) ([\w-]+?) \[(\d\d)/(\w\w\w)/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+0300\] "(.*?)" (\d*?) ([\d-]*?) "(.*?)" "(.*?)"$!;
my $re;

if ( defined $apache ) {
	# Default is apache ele_ext
	#89.238.194.86 - [28/Oct/2012:03:27:09 +0300] "GET /library/elefant_white/js/jquery.jplayer/themes/blue.monday/jplayer.blue.monday.css HTTP/1.0" 200 12940 2473 - 0 "http://www.elefant.ro/" "Wget/1.12 (linux-gnu)"
	$re = qr!^([\d\.]+?) ([\w-]+?) \[(\d\d)/(\w\w\w)/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+0\d00\] "(\w+?) (\S+?) HTTP/(.*?)" (\d*?) (\d*?) (\d*?) ([X+-]*?) (\d*?) "(.*?)" "(.*?)"$!;
	$duration_factor = 1000;
	
} elsif ( defined $nginx ) {
	# nginx ele_ext
	$re = qr!^([\d\.]+?) ([\w-]+?) ([\w-]+?) \[(\d\d)/(\w\w\w)/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+0\d00\] "(\w+?) (\S+?) HTTP/(.*?)" (\d*?) ([\d-]*?) "(.*?)" "(.*?)"$!;
	$duration_factor = 1;
} elsif ( defined $combined ) {
	$re = qr!^([\d\.]+?) ([\w-]+?) ([\w-]+?) \[(\d\d)/(\w\w\w)/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+0\d00\] "(\w+?) (\S+?) HTTP/(.*?)" (\d*?) ([\d-]*?) "(.*?)" "(.*?)"$!;
} else {
	die "No log format specified";
}

while( my $line = <$fin> )  {   
	if ( $line =~ $re ) {
		if ( defined $apache ) {
			($ip, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $rqtime, $keepalive, $kaidx, $ref, $ua) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18);
			#print "$ip, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $rqtime, $keepalive, $kaidx, $ref, $ua\n";
		} elsif ( defined $nginx ) {
			($ip, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $rqtime, $keepalive, $kaidx, $ref, $ua) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18);
			#print "$ip, $unk, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $ref, $ua\n";
		} elsif ( defined $combined ) {
			($ip, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $rqtime, $keepalive, $kaidx, $ref, $ua) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18);
			#print "$ip, $unk, $user, $day, $month, $year, $hour, $min, $sec, $method, $uri, $proto, $hcode, $size, $ref, $ua\n";
		}
		
		if ( defined $source_ip && $source_ip ne $ip ) {
			next;
		}
		
		$total_rq += 1;		
		$total_size += ($size ne "-")?$size:0;
		$total_time += $rqtime;
		
		$by_hour{$month}{$day}{$hour}->{rqs} += 1;
		$by_hour{$month}{$day}{$hour}->{size} += ($size ne "-")?$size:0;

		$int_ips_total_rq{$ip}->{rqs} += 1;
		$int_ips_total_rq{$ip}->{rqtime} += $rqtime;
		$int_ips_total_rq{$ip}->{size} += ($size ne "-")?$size:0;
		$int_ips_total_rq{$ip}->{ua} = $ua;
		

		$int_uris_total_rq{$uri}->{rqs} += 1;
		$int_uris_total_rq{$uri}->{size} += ($size ne "-")?$size:0;
		$int_uris_total_rq{$uri}->{rqtime} += $rqtime;

		$int_refs_total_rq{$ref}->{rqs} += 1;
		$int_refs_total_rq{$ref}->{size} += ($size ne "-")?$size:0;
		$int_refs_total_rq{$ref}->{rqtime} += $rqtime;

		$int_uas_total_rq{$ua}->{rqs} += 1;
		$int_uas_total_rq{$ua}->{size} += ($size ne "-")?$size:0;
		$int_uas_total_rq{$ua}->{rqtime} += $rqtime;
		
		if ( $hcode >= 400 ) {
			$int_urisnotok_total_rq{$uri}->{rqs} += 1;
			$int_urisnotok_total_rq{$uri}->{hcode} = $hcode;
			$int_urisnotok_total_rq{$uri}->{size} += ($size ne "-")?$size:0;
			$int_urisnotok_total_rq{$uri}->{rqtime} += $rqtime;
		}
		
	} else {
		print STDERR "Error in line $.\n"; 
		print STDERR "$line";
		print $ferr  "Error in line $.\n"; 
		print $ferr "$line";
	};  

	if ( not $. % $report_interval ) {
		printf "Line %15s, $month $day $hour:$min\n", commify($.); 
	} 
   #last if $. == $lines_to_process;
}

my $tlines = $.;

print $ferr "File had " . commify($tlines) . " lines\n";
print STDERR "File had " . commify($tlines) . " lines\n";

close $fin;

###############################################################################
#
# Print reports
#
# Prepare common values
#
my $total_mb = $total_size/1024/1024;
my $total_gb = $total_mb/1024;
my $total_time_sec = $total_time/$duration_factor/1000;
my $total_avg_time = $total_time/$total_rq/$duration_factor;

###############################################################################
#
# Reports by IP
#
#
print_report_by_rq(\%int_ips_total_rq, "IP", \%known_ips);
print_report_by_rq(\%int_uris_total_rq, "URI", \%known_ips);
print_report_by_rq(\%int_refs_total_rq, "Referer", \%known_ips);
print_report_by_rq(\%int_uas_total_rq, "UserAgent", \%known_ips);
print_report_by_rq(\%int_urisnotok_total_rq, "Errors", \%known_ips);

print_report_by_rqtime(\%int_ips_total_rq, "IP", \%known_ips);
print_report_by_rqtime(\%int_uris_total_rq, "URI", \%known_ips);
print_report_by_rqtime(\%int_refs_total_rq, "Referer", \%known_ips);
print_report_by_rqtime(\%int_uas_total_rq, "UserAgent", \%known_ips);
print_report_by_rqtime(\%int_urisnotok_total_rq, "Errors", \%known_ips);




print STDERR "Writting " . $out_file . "-by-hour ... ";
open ($fout, ">:raw", $out_file . "-by-hour") or die "Could not open $out_file by-hour: $!";
print $fout "month, day_of_month, hour, requests, size, sizeMB, sizeGB\n";
print $fout "total, total, total," . $total_rq . ", " . $total_size;
printf $fout ", %.2f MB", $total_mb;
printf $fout ", %.2f GB", $total_gb;
print $fout "\n";

foreach $month ( sort keys %by_hour ) {
	#print "$month: { ";
	for $day ( sort keys %{ $by_hour{$month} } ) {
		#print "$day=$by_hour{$month}{$day} ";
			for $hour ( sort keys %{ $by_hour{$month}{$day} } ) {
				print $fout "$month, $day, $hour, ";
				print $fout $by_hour{$month}{$day}{$hour}->{rqs};
				print $fout ", ";
				print $fout $by_hour{$month}{$day}{$hour}->{size};
				
				my $sz = $by_hour{$month}{$day}{$hour}->{size};
				$sz = $sz/1024/1024;
				printf $fout ", %.2f MB", $sz;
				$sz = $sz/1024;
				printf $fout ", %.2f GB", $sz;
				
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

sub print_report_by_rqtime {
	my $hash_ref = shift;
	my $file_tail = shift;
	my $names = shift;
	
	my $categ = 'by_rqtime'
	
	print STDERR "Writting " . $out_file . "-$categ-$file_tail ... ";
	open ($fout, ">:raw", $out_file . "-$categ-$file_tail") or die "Could not open $out_file $categ-$file_tail: $!";
	print $fout "$file_tail, Name, Requests, Size, SizeMB, SizeGB, RqTime, RqTimeSec, AvgRqTime\n";
	print $fout "Total, -, " . $total_rq . ", " . $total_size;
	printf $fout ", %.2f", $total_mb;
	printf $fout ", %.2f", $total_gb;
	print $fout ", " . $total_time;
	printf $fout ", %.2f", $total_time_sec;
	printf $fout ", %.2f", $total_avg_time;
	print $fout ", -\n";

	foreach my $crt_key ( sort { $hash_ref->{$b}->{rqtime} <=> $hash_ref->{$a}->{rqtime} } keys %$hash_ref ) {
	
		if ( exists  $names->{ $crt_key } ) {
			print $fout "$crt_key, " . $names->{ $crt_key } . ", " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		} else {
			print $fout "$crt_key, -, " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		}

		#print $fout "$crt_key, " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		
		my $sz = $hash_ref->{$crt_key}->{size};
		$sz = $sz/1024/1024;
		printf $fout ", %.2f", $sz;
		$sz = $sz/1024;
		printf $fout ", %.2f", $sz;
		
		printf $fout ", %.2f", $hash_ref->{$crt_key}->{rqtime} / $duration_factor ;
		printf $fout ", %.2f", $hash_ref->{$crt_key}->{rqtime} / $duration_factor / 1000;
		printf $fout ", %.2f", $hash_ref->{$crt_key}->{rqtime} / $hash_ref->{$crt_key}->{rqs} / $duration_factor;
		
		if ( $file_tail eq "IP" ) {
			print $fout ", " . $int_ips_total_rq{$crt_key}->{ua} . "\n";
		} else {
			print $fout "\n";
		}
	}
	close $fout;
	print STDERR "Done.\n";
	
}


sub print_report_by_rq {
	my $hash_ref = shift;
	my $file_tail = shift;
	my $names = shift;

	my $categ = 'by_rq'
	
	print STDERR "Writting " . $out_file . "-$categ-$file_tail ... ";
	open ($fout, ">:raw", $out_file . "-$categ-$file_tail") or die "Could not open $out_file $categ-$file_tail: $!";
	print $fout "$file_tail, Name, Requests, Size, SizeMB, SizeGB, RqTime, RqTimeSec, AvgRqTime\n";
	print $fout "Total, -, " . $total_rq . ", " . $total_size;
	printf $fout ", %.2f", $total_mb;
	printf $fout ", %.2f", $total_gb;
	print $fout ", " . $total_time;
	printf $fout ", %.2f", $total_time_sec;
	printf $fout ", %.2f", $total_avg_time;
	print $fout ", -\n";

	foreach my $crt_key ( sort { $hash_ref->{$b}->{rqs} <=> $hash_ref->{$a}->{rqs} } keys %$hash_ref ) {
	
		if ( exists  $names->{ $crt_key } ) {
			print $fout "$crt_key, " . $names->{ $crt_key } . ", " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		} else {
			print $fout "$crt_key, -, " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		}

		#print $fout "$crt_key, " . $hash_ref->{$crt_key}->{rqs} . ", " . $hash_ref->{$crt_key}->{size};
		
		my $sz = $hash_ref->{$crt_key}->{size};
		$sz = $sz/1024/1024;
		printf $fout ", %.2f", $sz;
		$sz = $sz/1024;
		printf $fout ", %.2f", $sz;
		
		printf $fout ", %.2f", $hash_ref->{$crt_key}->{rqtime} / $duration_factor ;
		printf $fout ", %.2f", $hash_ref->{$crt_key}->{rqtime} / $duration_factor / 1000;
		printf $fout ", %.2f", $hash_ref->{$crt_key}->{rqtime} / $hash_ref->{$crt_key}->{rqs} / $duration_factor;
		
		if ( $file_tail eq "IP" ) {
			print $fout ", " . $int_ips_total_rq{$crt_key}->{ua} . "\n";
		} else {
			print $fout "\n";
		}
	}
	close $fout;
	print STDERR "Done.\n";
	
}
