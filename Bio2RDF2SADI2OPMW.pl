#!/usr/bin/perl -w
use strict;

use RDF::Trine;
use RDF::Query::Client;
use RDF::Trine::Serializer::Turtle;


my $store = RDF::Trine::Store::Memory->new();
my $model = RDF::Trine::Model->new($store);
  # Create a namespace object for the foaf vocabulary
my $opmw = RDF::Trine::Namespace->new( 'http://www.opmw.org/ontology/' );
my $rdfs = RDF::Trine::Namespace->new(  'http://www.w3.org/2000/01/rdf-schema#');
my $rdf =  RDF::Trine::Namespace->new( 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');

 # Create a node object for the FOAF name property
my $label = $rdfs->label;
my $type = $rdf->type;
my $comment = $rdfs->comment;

my $uses = $opmw->uses;
my $generatedBy = $opmw->isGeneratedBy;
my $wfData = $opmw->WorkflowTemplateArtifact;
my $wfServ = $opmw->WorkflowTemplateProcess;


my $query = <<EOQ;
PREFIX  dc:   <http://protege.stanford.edu/plugins/owl/dc/protege-dc.owl#>
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  sadi: <http://sadiframework.org/ontologies/sadi.owl#>
PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
PREFIX  owl:  <http://www.w3.org/2002/07/owl#>
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  serv: <http://www.mygrid.org.uk/mygrid-moby-service#>
SELECT distinct(?s1) ?output_type ?name1 ?desc1 ?s2 ?name2 ?desc2
FROM <http://sadiframework.org/registry/>
WHERE
  { ?s1 rdf:type serv:serviceDescription .
    ?s2 rdf:type serv:serviceDescription .
    ?s1 serv:hasServiceDescriptionText ?desc1 .
    ?s2 serv:hasServiceDescriptionText ?desc2 .
    ?s2 serv:hasOperation ?operation2 .
    ?s1 serv:hasServiceNameText ?name1 .
    ?s2 serv:hasServiceNameText ?name2 .

    ?s1 sadi:decoratesWith ?blank .
    ?blank owl:someValuesFrom ?output_type .

    ?operation2 serv:inputParameter ?in2 .
    ?in2  serv:objectType ?output_type .
    FILTER(regex(?s1, "Bio2RDF2SADI")) .

  }


EOQ

 my $client = RDF::Query::Client->new($query);
 
 my $iterator = $client->execute('http://sadiframework.org/registry/sparql');
 
 while (my $row = $iterator->next) {
    my ($serv1, $datatype, $name1, $desc1, $serv2, $name2, $desc2) = (
            $row->{s1}->as_string,
            $row->{output_type}->as_string,
            $row->{name1}->as_string,
            $row->{desc1}->as_string,
            $row->{s2}->as_string,
            $row->{name2}->as_string,
            $row->{desc2}->as_string);
my $stm;    
#    $stm = statement($serv1, $type, $wfServ);
#    $model->add_statement($stm);
#    $stm = statement($serv1, $label, $name1);
#    $model->add_statement($stm);
#    $stm = statement($serv1, $comment, $desc1);
#    $model->add_statement($stm);
    
    
    $stm = statement($datatype, $type, $wfData);
    $model->add_statement($stm);
    $stm = statement($serv2, $uses, $datatype); 
    $model->add_statement($stm);
#    $stm = statement($serv2, $label, $name2); 
#    $model->add_statement($stm);
#    $stm = statement($serv2, $comment, $desc2); 
#    $model->add_statement($stm);
    
    $stm = statement($datatype, $generatedBy, $serv1);
    $model->add_statement($stm);
    
    
 }

 my $serializer = RDF::Trine::Serializer::Turtle->new(namespaces => {
                                                                     opmw => 'http://www.opmw.org/ontology/',
                                                                     rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
                                                                     rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'});
 
 my $turtle = $serializer->serialize_model_to_string($model);
 open(OUT, ">Bio2RDF2SADI2OPMW.ttl") || die "can't open output $!\n";
 print OUT $turtle;
 close OUT;


use RDF::Trine::Exporter::GraphViz;

  my $ser = RDF::Trine::Exporter::GraphViz->new( as => 'dot',
						style => {rankdir => 'LR'},
						namespaces => {
                                                                     opmw => 'http://www.opmw.org/ontology/',
                                                                     rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
                                                                     rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
								     sadi => 'http://biordf.org/cgi-bin/SADI/Bio2RDF2SADI/SADI/',} );
  $ser->to_file( 'graph.svg', $model );


exit 1;


sub statement {
	my ($s, $p, $o) = @_;
	unless (ref($s) =~ /Trine/){
		$s =~ s/[\<\>]//g;
		$s = RDF::Trine::Node::Resource->new($s);
	}
	unless (ref($p) =~ /Trine/){
		$p =~ s/[\<\>]//g;
		$p = RDF::Trine::Node::Resource->new($p);
	}
	unless (ref($o) =~ /Trine/){
		if ($o =~ /http\:\/\//){
			$o =~ s/[\<\>]//g;
			$o = RDF::Trine::Node::Resource->new($o);
		} elsif ($o =~ /\D/) {
			$o = RDF::Trine::Node::Literal->new($o);
		} else {
			$o = RDF::Trine::Node::Literal->new($o);				
		}
	}
	my $statement = RDF::Trine::Statement->new($s, $p, $o);
	return $statement;
}

