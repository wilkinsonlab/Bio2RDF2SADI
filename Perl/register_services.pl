#!/usr/bin/perl -w

# an example of how to register a service
# curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=http://sadiframework.org/examples/hello'

my $USAGE = <<EOUSAGE;


   usage:
   
       register_services.pl  http://url.to/service/script/SADI/   /path/to/config/files/
       
       NOTE:
        - the service script needs a trailing slash
	- the local path to the config files; ends before the Bio2RDF namespace
	  e.g. /path/to/config/files/ [atlas/term_regulates_term.cfg]

       
EOUSAGE

my $service_script;
my $config_path;

($service_script = $ARGV[0]) || die $USAGE;
($config_path = $ARGV[0]) || die $USAGE;

opendir (DIR, "$config_path") || die "can't open configuration folder";
my @endpoints = readdir DIR;


my %servicenames;
foreach my $end(@endpoints){  # we will use the filenames to create a non-redundant list of all possible services
	next if $end =~ /^\./;
	opendir (DIR2, "$config_path/$end") || die "can't open sub-ontology folder";
	my @services = readdir DIR2;
	foreach my $servname(@services){
		next if $servname =~ /^\./;
		die "\n\nconfig filename is odd...$servname???\n\n" unless ($servname =~ /(\S+)\.\S+/);
		$servname = $1; 
		$servicenames{"$end/$servname"} = 1; # rely on hash to remove duplicates with .owl, .sparql, and .cfg extensions
	}
}

closedir DIR;
closedir DIR2;

my $count;

foreach my $name(keys %servicenames){
	# e.g. $name = "affymetrix/Probeset_inDataset_Dataset"; 
	print ++$count;
	print "  curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=$service_script$name'\n";
	my $fail =0;
	while ($fail <= 3){
#		last;  #  comment me out to do the real registration	
		open(REGISTER, "-|", "curl http://sadiframework.org/registry/register/ --data-urlencode 'serviceURI=$service_script$name'");
		my @lines = <REGISTER>;
		my $response = join ("", @lines);

		if ($response =~ /\<h3\>success/is){  # the result of this call is, unfortunately, HTML :-(
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

	# exit 1;   # if you just want to try one to see if it works, exit here
}

=head1  NAME

 register_services


=head1 USAGE
   
       register_services.pl  http://url.to/service/script/SADI/   /path/to/config/files/
       
       NOTE:
        - the service script needs a trailing slash
	- the local path to the config files; ends before the Bio2RDF namespace
	  e.g. /path/to/config/files/ [atlas/term_regulates_term.cfg]

=cut

