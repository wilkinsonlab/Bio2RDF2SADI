#!/usr/bin/perl -w

# an example of how to register a service
# curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=http://sadiframework.org/examples/hello'

my %servicenames;
my $service_script = "http://biordf.org/cgi-bin/SADI/Bio2RDF2SADI/SADI/";  # trailing slash


opendir (DIR, "/home/biordf/public_html/ontologies/") || die "can't open ontologies folder";
my @endpoints = readdir DIR;

foreach my $end(@endpoints){
	next if $end =~ /^\./;
	opendir (DIR2, "/home/biordf/public_html/ontologies/$end") || die "can't open sub-ontology folder";
	my @services = readdir DIR2;
	foreach my $servname(@services){
		next if $servname =~ /^\./;
		die unless ($servname =~ /(\S+)\.\S+/);
		$servname = $1; 
		$servicenames{"$end/$servname"} = 1; # rely on hash to remove duplicates with .owl, .sparql, and .cfg extensions
	}
}

closedir DIR;
closedir DIR2;

my $count;

foreach my $name(keys %servicenames){
	# $name = "affymetrix/Probeset_inDataset_Dataset"; 
	print ++$count;
	print "  curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=$service_script$name'\n";
	my $fail =0;
	while ($fail <= 3){
#		last;  #  comment me out to do the real registration	
		open(REGISTER, "-|", "curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=$service_script$name'");
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
			print ERROR "$count $service_script$name  $error \n";
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
