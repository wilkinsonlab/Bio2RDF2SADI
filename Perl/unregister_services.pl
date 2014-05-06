#!/usr/bin/perl -w

use RDF::Trine;
use RDF::Trine::Parser;
use RDF::Query::Client;

=head1 NAME

 unregister_services.pl  - a script for bulk de-registering Bio2RDF2SADI services

=head1 USAGE

  The first thing you need to do is take your Bio2RDF2SADI service script offline
  (usually called "SADI" in a default installation)
  
  By taking this offline, the service will not respond to an HTTP GET, and
  therefore when the registy calls it, and finds it isn't there, it will
  remove it from the registry
  
  Therefore, all this script does is query the registry for all
  Bio2RDF2SADI services, and then asks the registry to re-GET them...
  which fails, and therefore they become de-registered
  
  The only thing you might need to configure in this script is the regexp
  that matches your Bio2RDF2SADI services.  For all of our services,
  this is 'Bio2RDF2SADI', which is a subfolder underneath our 'cgi-bin' folder. 

=cut


my $query = <<"EOF";
PREFIX  dc:   <http://protege.stanford.edu/plugins/owl/dc/protege-dc.owl#>
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  sadi: <http://sadiframework.org/ontologies/sadi.owl#>
PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
PREFIX  owl:  <http://www.w3.org/2002/07/owl#>
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  serv: <http://www.mygrid.org.uk/mygrid-moby-service#>

SELECT ?s
FROM <http://sadiframework.org/registry/>
WHERE
  { ?s rdf:type serv:serviceDescription .
    ?s serv:providedBy ?org .
    ?org dc:publisher ?pub .
    FILTER regex(str(?pub), "bio2rdf2sadi") . 
  }

EOF

 my $client = RDF::Query::Client
               ->new($query);
 my $iterator = $client->execute('http://dev.biordf.net/sparql');
 
my %to_deregister;
 while (my $row = $iterator->next) {
	my $servname = $row->{s}->as_string;
	$servname =~ s/[<>]//g;
        print $servname, "\t", $row->{s}->as_string, "\n";
        $to_deregister{$servname} = 1;
 }

#exit 1;



# an example of how to de-register a service
# curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=http://sadiframework.org/examples/hello'



foreach my $name(keys %to_deregister){
	# $name = "affymetrix/Probeset_inDataset_Dataset"; 
	print ++$count;
	print "  curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=$name'\n";
	my $fail =0;
	while ($fail <= 3){
			
		open(REGISTER, "-|", "curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=$name'");
		my @lines = <REGISTER>;
		my $response = join ("", @lines);
		# print $response;
		if ($response =~ /\<h3\>success/is){
			print "Successful!\n\n";
			$fail = 5;
		} elsif ($response =~ /error.*?blockquote>([^\<]+)/is){
			my $error = $1;
			print "ERROR:  $error\n";
			open (ERROR, ">>service_registration_errors.txt");
			print ERROR "$count  $error\n";
			close ERROR;
			$fail = 5;
		} else {
			++$fail;  # try several times before giving up... can't connect errors are common...
			if ($fail <=3){
				print "\n\nSorry... trying again...\n\n";
			} else {
				print "giving up on $service_script$name\n\n";
				open (ERROR, ">>service_registration_errors.txt");
				print ERROR "$count  gave up trying $service_script$name\n";
				close ERROR				
			}
		}
		sleep 3;  # give the registry a break :-)  poor Tomcat...
	}

	# exit 1;
}
