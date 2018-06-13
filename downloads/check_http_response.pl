#!/usr/bin/perl
#check_http_response.pl
#===============================================================================#
#										#
#	AUTHOR: 	Julian Rutledge julian@julianrutledge.com		#
#	VERSION:	1.4							#
#	CREATED:	10/6/2015						#
#	LICENSE:	GPLv3							#
#	NOTES:		2015-12-01 - added performance output 			#
#										#
#===============================================================================#
use warnings;
use strict;

use LWP;
use Getopt::Long;

#define constants
my $OK = 0;
my $WARNING = 1;
my $CRITICAL = 2;
my $UNKNOWN = 3;

#define and parse script arguments
my (
	$host,
	$url,
	$phrase,
	%reqheader
);

GetOptions(
	'H=s'	=>	\$host,		'host=s'	=>	\$host,
	'u=s'	=>	\$url,		'url=s'		=>	\$url,
	'p:s'	=>	\$phrase,	'phrase:s'	=>	\$phrase,
	'r:s'	=>	\%reqheader,	'request:s'	=>	\%reqheader
);

#define functions
sub HELP_MESSAGE {
	print "$0 -H <hostname> -u <URL> -p <phrase> -r <key>=<value>\n";
	print "\n";
	print "Mandatory Arguments:\n";
	print "\t -H, --host <hostname>\t| hostname or IP address\n";
	print "\t -u, --url <URL>\t| URL to append to hostname\n";
	print "Optional Arguments:\n";
	print "\t -p, --phrase <phrase>\t| phrase to parse the page content for\n";
	print "\t -r, --request <header>\t| headers to send in the request\n";
	print "\n";
	print "Returns OK status if HTML response code is 200 and if content contains the supplied phrase (optional).\n";
	print "Any other HTML response will return a warning. A failed connection will return a critical value.\n";
}

sub test_site {
	my ($host,$url,$phrase) = @_;
	if ( (defined $host) && (defined $url) ) {
		my $request = "$host" . "$url";
		my $agent = LWP::UserAgent->new;
		my @header = %reqheader;
		my $response = $agent->get($request, @header);
		my $html_code = $response->status_line;
		my $content = $response->content;
		my $html_num = substr($html_code, 0, 3);

		if ($response->is_success) {
			if ( ($html_code =~ m/200/) && (defined $phrase) ){
				if ( $content =~ m/$phrase/ ) {	
					return $OK, "OK - HTML: $html_code | html=$html_num";
				} else {
				return $WARNING, "WARNING - HTML: $html_code | html=$html_num";
				}
			} elsif ( ($html_code =~ m/200/) && (!defined $phrase) ){
				return $OK, "OK - HTML: $html_code | html=$html_num";
			} else {
				return $WARNING, "WARNING - HTML: $html_code | html=$html_num";
			}
		} else {
			return $CRITICAL, "CRITICAL - HTML: $html_code, $content | html=$html_num";
		}
	} else {
		HELP_MESSAGE();
		exit $UNKNOWN;
	}
}

#execute functions
my ($rc, $output) = test_site($host,$url,$phrase);
print $output, "\n";
exit $rc;

