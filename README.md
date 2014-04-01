Bio2RDF2SADI
============

Code for auto-wrapping the Bio2RDF Endpoints as SADI services (both Perl and Java steps included)

The process is:

1)  In the /Java/Binary/config/config.cfg file, edit the DEFAULT_IRI parameter to 
	point at the location where you will be deploying the automatically-generated 
	ontologies.  This must be a publicly-accessible folder on the Web, and
	on the same machine as the final service script (the script will access
	those files directly)

2)  Run the Bio2RDF2SADI Jar file in /Java/Binary.  This will create a set of ontology, 
	query, and configuration files for your services.

3)  Deploy these ontologies at the Web location selected in (1)

4)  From the Perl folder, deploy the SADI script to an executable folder on your server

5)  Edit the $CONFIGURATION_FILE_PATH variable in the SADI script to 
	point to the system path (NOT THE WEB PATH) of the files from (1)
	For more information, read the POD documentation for SADI.

6)  Test your installation by browsing to one of the services.  Service URLs follow
	the pattern  http://your.domain.org/cgi-bin/SADI/<namespace>/<servicename>
	where namespace is the bio2rdf dataset (e.g. 'atlas' or 'sgd') and 
	servicename is the name of the service (e.g. 'Symbol_sameAs_Marker').
	If you are configured correctly, this URL will return an RDF document
	with the interface definition of the service endpoint.

7)  If you wish to register your services in the public SADI registry
	(please think before you do this!), then run the register_services.pl
	script on the same machine as your service endpoint (see the POD
	documentation for more details)

