#!/usr/bin/perl

use strict;
use warnings;

my $infile = 'ohsu-metadata.owl';
my $outfile = 'author-data.txt';

#####################################
# store some regexes to get key fields
my $ohsu_regex = qr/<owl:Class rdf:about="http:\/\/ohsu-metadata\/([^"]*)">/; 
my $label_regex = qr/<rdfs:label rdf:datatype="&xsd;string">([^_]*)[_<]/; 
my $scopus_regex = qr/<ohsu-metadata3:hasIdentifier rdf:datatype="&xsd;string">ScopusAuthor:([0-9]*)</; 
my $member_of_regex = qr/<rdfs:subClassOf rdf:resource="http:\/\/ohsu-metadata\/([^"]*)"/; 
my $detectunit_regex = qr/ohsu-metadata3:hasName rdf:/; 
my $endrecord_regex = qr/<\/owl:Class>/; 

###########################
# Organizations are stored in hashes of hashes and peop
my %organizations = ();
my %all_names = ();
my %organization_members = ();

my $isunit = 0;
my $record = '';
my $ohsu_id = '';
my $scopus_id = '';
my $record_id = '';
my $member_of = '';
my $label = '';
my $line = '';

my @source_data = [];
my @memberships = [];

local $/ = undef;
$/ = "\n";

open (INFILE, $infile) or die("Unable to open data file \"$infile\"");
@source_data = <INFILE>;
close $infile;

foreach $line(@source_data) {
	#####################
	# Get OHSU identifier
	#####################
	if ($line =~ /$ohsu_regex/) {
		$ohsu_id = $1;
		}
	if ($line =~ /$label_regex/) {
		$label = $1;
		}
	if ($line =~ /$scopus_regex/) {
		$scopus_id = $1;
		$record_id = $scopus_id;
		}

	if ($line =~ /$detectunit_regex/) {
		$isunit = 1;	
		$record_id = $ohsu_id;
		}
	if ($line =~ /$member_of_regex/) {
		$member_of = $1;	
		###############################################
		# keep a list of memberships until we know this 
		# record is for a person or unit
		###############################################
		push @memberships, $ohsu_id;
		}

	##########################################
	# Detect end of record and reset variables
	##########################################
	if ($line =~ /$endrecord_regex/) {
		##################
		# Record the label
		##################
		$all_names{$record_id} = $label;
		###################################################
		# Add memberships
		#
		# People and units are stored in same hash but 
		# are treated differently based on ID pattern match
		###################################################
		foreach my $membership(@memberships) {
			push @{$organization_members{$member_of}}, $record_id;
			}
		$scopus_id = '';
		$ohsu_id = '';
		$record_id = '';
		$label = '';
		$isunit = 0;
		@memberships = [];
		}
	}

	######################
	# iterate through keys
	######################
	
	for my $org_key(keys %organization_members) {
		print "$all_names{$org_key} ----- $org_key\n";
		my $members = join("\n", @{$organization_members{$org_key}});
		print "$members\n";
		}
