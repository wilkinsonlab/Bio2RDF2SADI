use strict;
use warnings;
use RDF::Query::Client;
use LWP::Simple;

my $namedgSPARQL = 'PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT distinct ?graph 

WHERE {
  graph ?graph {?a ?b ?c}

}';


my $RAWsubjecttypesSPARQL = 'SELECT distinct(?stype)
FROM <NAMED_GRAPH_HERE>
WHERE {
 ?s a ?stype .
 FILTER (!regex(?stype, "owl#")) .
 FILTER (!regex(?stype, "w3.org")) .
 FILTER (!regex(?stype, ":Resource")) 
}
';   # FILTER (!regex(?stype, ":Resource")) . 


my $RAWpredicatetypesSPARQL = 'SELECT distinct(?p)
FROM <NAMED_GRAPH_HERE>
WHERE {
 ?s a <SUBJECT_TYPE_HERE> .
?s ?p ?o .   
FILTER (!regex(?p, "w3.org"))
FILTER (?p != <http://rdfs.org/ns/void#inDataset>)
}
';


my $RAWobjecttypesSPARQL = 'SELECT distinct(?otype)
FROM <NAMED_GRAPH_HERE>
WHERE {
 ?s a <SUBJECT_TYPE_HERE> .
?s <PREDICATE_TYPE_HERE> ?o .   
?o a ?otype
 FILTER (!regex(?otype, "owl#")) .
 FILTER (!regex(?stype, "w3.org")) .

}';
        

my $RAWobjectdatatypesSPARQL = 'SELECT distinct(datatype(?o)) as ?datatype
FROM <NAMED_GRAPH_HERE>
WHERE {
 ?s a <SUBJECT_TYPE_HERE> .
?s <PREDICATE_TYPE_HERE> ?o .   
 FILTER isLiteral(?o)
}
group by ?o
';



#my $RAWliteraltypeSPARQL = 'PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
#PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
#PREFIX void: <http://rdfs.org/ns/void#>
#PREFIX bio2rdf: <http://bio2rdf.org/>
#PREFIX http: <http://www.w3.org/2006/http#>
#
#SELECT distinct(?stype) ?p datatype(?o) as ?otype
#FROM <NAMED_GRAPH_HERE> 
#WHERE {
# ?s a ?stype .
# ?s ?p ?o .
# FILTER (?p != void:inDataset) . 
# FILTER isLiteral(?o)
#
#} 
#group by ?stype ?p datatype(?o)
#';


my %dataset_endpoints;

open(OUT, ">endpoint_datatypes.list") || die "can't open output file for writing $!\n";


my $bio2rdfendpoints = get('http://s4.semanticscience.org/bio2rdf/3/');
while (($bio2rdfendpoints =~ /\[(\w+)\].*?(http:\/\/s4.semanticscience.org:\d+\/sparql)/sg) ) {
        my ($namespace, $endpoint) = ($1, $2);
        next if $namespace eq "ndc";
        next if $namespace eq "lsr";
        next if $namespace eq "bioportal";
        
        my $graphquery = RDF::Query::Client->new($namedgSPARQL);
        my $iterator = $graphquery->execute($endpoint,  {Parameters => {timeout => 380000, format => 'application/sparql-results+json'}});
        next unless $iterator;  # in case endpoint is down
        my $namedgraph;
        my $highest=0;
        while (my $row = $iterator->next){
                next unless ($row->{graph}->[1] =~ /bio2rdf.dataset.*?(\d+)$/);
                my $this = $1;
                ($namedgraph = $row->{graph}->[1]) if ($this > $highest);
                print "$namespace, $namedgraph, $endpoint\n";
        }

        $dataset_endpoints{$namespace} = [$endpoint, $namedgraph];
}

foreach my $namespace(sort(keys %dataset_endpoints)){
        my ($endpoint, $namedgraph) = @{$dataset_endpoints{$namespace}};
        print "\n\n\nMoving On to $namespace\n\n\n";
        my $subjecttypesSPARQL = $RAWsubjecttypesSPARQL;
        $subjecttypesSPARQL =~ s/NAMED_GRAPH_HERE/$namedgraph/;
        
        my $typequery = RDF::Query::Client->new($subjecttypesSPARQL); # query for all output types of the form xxx_vocabulary:Resource
        my $siterator = $typequery->execute($endpoint,  {Parameters => {timeout => 380000, format => 'application/sparql-results+json'}});
        unless ($siterator){print "          ---------no subject types found -----------\n"; next;}

        while (my $row = $siterator->next){
                my $stype = $row->{stype}->[1];
                my $base_input_type = "";
                print STDERR "\n\nno match $stype\n\n" unless $stype =~ m|(http://\S+\..*):\S+$|;  #(something-something.something:something:something):Geneotype
                $base_input_type = "$1:Resource" if $1;  # because Bio2RDF doesn't know what type something is, it always outputs :Resource, which means we need services that will consume these weakly-typed data
                
                my $predicatetypesSPARQL = $RAWpredicatetypesSPARQL;
                $predicatetypesSPARQL =~ s/NAMED_GRAPH_HERE/$namedgraph/;
                $predicatetypesSPARQL =~ s/SUBJECT_TYPE_HERE/$stype/;
                
                my $ptypequery = RDF::Query::Client->new($predicatetypesSPARQL); # query for all output types of the form xxx_vocabulary:Resource
                my $piterator = $ptypequery->execute($endpoint,  {Parameters => {timeout => 380000, format => 'application/sparql-results+json'}});
                unless ($piterator){print "          ---------no predicate types found for $stype -----------\n"; next;}
        
                while (my $row = $piterator->next){
                        my $ptype = $row->{p}->[1];

                        my $objecttypesSPARQL = $RAWobjecttypesSPARQL;
                        $objecttypesSPARQL =~ s/NAMED_GRAPH_HERE/$namedgraph/;
                        $objecttypesSPARQL =~ s/SUBJECT_TYPE_HERE/$stype/;
                        $objecttypesSPARQL =~ s/PREDICATE_TYPE_HERE/$ptype/;
                        
                        my $otypequery = RDF::Query::Client->new($objecttypesSPARQL); # query for all output types of the form xxx_vocabulary:Resource
                        my $oiterator = $otypequery->execute($endpoint,  {Parameters => {timeout => 380000, format => 'application/sparql-results+json'}});
                        unless ($oiterator){print "          ---------no object types found for $stype $ptype -----------\n"; next;}
                
                        while (my $row = $oiterator->next){
                                my $otype = $row->{otype}->[1];
                                print "           Found Triple Pattern:     $stype $ptype $otype\n";
                                print OUT "$namespace\t$stype\t$ptype\t$otype\n";
                                print OUT "$namespace\t$base_input_type\t$ptype\t$otype\n" if $base_input_type;
                        }

                        my $datatypesSPARQL = $RAWobjectdatatypesSPARQL;
                        $datatypesSPARQL =~ s/NAMED_GRAPH_HERE/$namedgraph/;
                        $datatypesSPARQL =~ s/SUBJECT_TYPE_HERE/$stype/;
                        $datatypesSPARQL =~ s/PREDICATE_TYPE_HERE/$ptype/;
                        
                        my $dtypequery = RDF::Query::Client->new($datatypesSPARQL); # query for all output types of the form xxx_vocabulary:Resource
                        my $diterator = $dtypequery->execute($endpoint,  {Parameters => {timeout => 380000, format => 'application/sparql-results+json'}});
                        unless ($diterator){print "          ---------no data types found for $stype $ptype-----------\n"; next;}
                
                        while (my $row = $diterator->next){
                                my $otype = $row->{datatype}->[0];  # oddly, if you don't group-by it is ->[1], but the query often crashes!
                                $otype = $row->{datatype}->[1] unless $otype;  # this is a bug in virtuoso!
                                unless ($otype){
                                        print "\n\nwtf?\n\n";
                                        next;
                                }
                                print "           Found Triple Pattern:     $stype $ptype $otype\n";
                                print OUT "$namespace\t$stype\t$ptype\t$otype\n";
                                print OUT "$namespace\t$base_input_type\t$ptype\t$otype\n" if $base_input_type;
                        }
                }
        }
}
exit 1;

#
#        my $literaltypeSPARQL = $RAWliteraltypeSPARQL;
#        $literaltypeSPARQL =~ s/NAMED_GRAPH_HERE/$namedgraph/;
##        print "query:\n$literaltypeSPARQL\n\non$endpoint\n\n";  
#        my $ltypequery = RDF::Query::Client->new($literaltypeSPARQL); # query for all output types of the form xxx_vocabulary:Resource
#        $iterator = $ltypequery->execute($endpoint, {Parameters => {timeout => 380000, format => 'application/sparql-results+json'}});  # asking for json overcomes a bug in RDF::Query::Client
#        unless ($iterator){print "          ---------no resource types found -----------\n"; next;}
#        while (my $row = $iterator->next){
#                my $stype = $row->{stype}->[1];                
#                my $p = $row->{p}->[1];
#                my $otype = $row->{otype}->[0];  # literals use zero
#                next if ($stype =~ /\/owl\#/);
#                next if ($stype =~ /rdf\-syntax/);
#                next if ($p =~ /\/owl\#/);
#                next if ($p =~ /rdf\-syntax/);
#                next if ($otype =~ /\/owl\#/);
#                next if ($otype =~ /rdf\-syntax/);
#                next unless $otype;
#                print "           Found Data Type $stype $p $otype\n";
#                print OUT "$namespace\t$stype\t$p\t$otype\n";
#        }

#
#my $sparql = "select ?p ?o
#where {
#  <http://bio2rdf.org/drugbank:DB00001> a <http://bio2rdf.org/drugbank_vocabulary:Drug> .
#  <http://bio2rdf.org/drugbank:DB00001> ?p ?o .
#}";
#
#my $query = RDF::Query::Client->new($sparql);
#my $iterator = $query->execute('http://s4.semanticscience.org:14006/sparql');  # execute the query against the URL of the endpoint
#
#if ($iterator){ 
#        while (my $row = $iterator->next){ print "$row\n\n"}
#}
#
