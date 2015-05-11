#!/usr/bin/perl 

# Copyright 2014 Magnus Enger Libriotech

=head1 NAME

nciptester.pl - Run test requests against an NCIP endpoint.

=head1 SYNOPSIS

 perl nciptester.pl -e http://localhost:3000/ -s LookupUser -v

=cut

use File::Slurper 'read_text';
use HTTP::Tiny;
use XML::LibXML::PrettyPrint qw( print_xml );
use Term::ANSIColor;
use Data::Dumper;
use Pod::Usage;
use Getopt::Long;
use Modern::Perl;

my ( $endpoint, $service, $validate ) = get_options();

my $xmlschema = XML::LibXML::Schema->new( 'location' => 'ncip_v2_02.xsd' );

# Check that the XML file corresponding to the request exists
my $servicefile = "req/$service.xml";
die colored ['red'], "The file $servicefile does not exist...\n" unless -e $servicefile;
my $serviceuest_xml = read_text($servicefile);
say "------------------ Request --------------------";
say $serviceuest_xml;

if ( $validate ) {
    # Validate the request
    say "------------------ Validate -------------------";
    eval { say $xmlschema->validate( XML::LibXML->new->parse_string( $serviceuest_xml ) ) ? say colored ['red'], "ERROR" : say colored ['green'], "OK!"; };
    say colored ['red'], $@ if $@;
}

# Send the request
my $http = HTTP::Tiny->new();
my $response = $http->post( $endpoint, { 'content' => $serviceuest_xml } );

if ( $response->{success} ){

    # Print the response content
    # say "------------------ Raw esponse ----------------";
    # say $response->{'content'};

    # Prettyprint the response content
    my $response_xml = XML::LibXML->new->parse_string( $response->{'content'} );
    my $pp = XML::LibXML::PrettyPrint->new(
        'indent_string' => "    ",
    );
    $pp->pretty_print($response_xml); # modified in-place
    say "------------------ Response -------------------";
    say $response_xml->toString;

    if ( $validate ) {
        # Validate the response against the schema
        say "------------------ Validate -------------------";
        eval { $xmlschema->validate( $response_xml ) ? say colored ['red'], "ERROR" : say colored ['green'], "OK!"; };
        say colored ['red'], $@ if $@;
    }

} else {

    say "****************** Error **********************";
    print color 'red';
    say "$response->{status} $response->{reason}\n";
    print color 'reset';
    say Dumper $response;

}

=head1 OPTIONS

=over 4

=item B<-e, --endpoint>

URL for endpoint. Include http://

=item B<-s, --service>

Name of the service we want to test. E.g. LookupUser. This must correspond with
the name of an .xml file in the req subdirectory. So if you specify LookupUser,
there must be a F<req/LookupUser.xml> file that contains the NCIP request. 

Names of services and files are arbitrary, so they do not have to correspond to
actual NCIP services. 

=item B<-v --validate>

More verbose output.

=item B<-h, -?, --help>

Prints this help message and exits.

=back
                                                               
=cut

sub get_options {

    # Options
    my $endpoint = '';
    my $service  = '';
    my $validate = '';
    my $help     = '';

    GetOptions (
        'i|endpoint=s' => \$endpoint,
        's|service=s'  => \$service,
        'v|validate'   => \$validate,
        'h|?|help'     => \$help
    );

    pod2usage( -exitval => 0 ) if $help;
    pod2usage( -msg => "\nMissing Argument: -e, --endpoint required\n", -exitval => 1 ) if !$endpoint;
    pod2usage( -msg => "\nMissing Argument: -s, --service required\n", -exitval => 1 ) if !$service;

    return ( $endpoint, $service, $validate );

}

=head1 AUTHOR

Magnus Enger, Libriotech <>

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut
