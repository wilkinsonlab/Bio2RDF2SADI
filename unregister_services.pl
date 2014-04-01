#!/usr/bin/perl -w

use RDF::Trine;
use RDF::Trine::Parser;
use RDF::Query::Client;

my $query = <<"EOF";
PREFIX  dc:   <http://protege.stanford.edu/plugins/owl/dc/protege-dc.owl#>
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  sadi: <http://sadiframework.org/ontologies/sadi.owl#>
PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
PREFIX  owl:  <http://www.w3.org/2002/07/owl#>
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  serv: <http://www.mygrid.org.uk/mygrid-moby-service#>

SELECT ?s ?name 
FROM <http://sadiframework.org/registry/> 
WHERE
  { ?s rdf:type serv:serviceDescription .
    ?s serv:hasServiceNameText ?name .
  FILTER regex(str(?s), "Bio2RDF2SADI")

  }
EOF

 my $client = RDF::Query::Client
               ->new($query);
 my $iterator = $client->execute('http://sadiframework.org/registry/sparql/');
 
my %to_deregister;
 while (my $row = $iterator->next) {
	my $servname = $row->{s}->as_string;
	$servname =~ s/[<>]//g;
    print $servname, "\t", $row->{name}->as_string, "\n";
    $to_deregister{$servname} = 1;
 }

#exit 1;



# an example of how to register a service
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
