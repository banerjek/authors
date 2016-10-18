#!/usr/bin/perl

use strict;
use warnings;

my $infile = 'ohsu-metadata.owl';
my $outfile = 'author-data.txt';

#####################################
# store some regexes to get key fields
my $ohsu_regex = qr/<owl:Class rdf:about="http:\/\/ohsu-metadata\/([^"]*)">/; 
my $label_scopus_regex = qr/<rdfs:label rdf:datatype="&xsd;string">([^_]*)_([0-9]*)</; 
my $member_of_regex = qr/<rdfs:subClassOf rdf:resource="http:\/\/ohsu-metadata\/([^"]*)"/; 
my $detectunit_regex = qr/ohsu-metadata3:hasName rdf:/; 
my $endrecord_regex = qr/<\/owl:Class>/; 

###########################
# Organizations are stored in hashes of hashes and peop
my %organizations = ();
my %organization_names = ();
my %organization_members = ();

my $isunit = 0;
my $record = '';
my $ohsu_id = '';
my $scopus_id = '';
my $member_of = '';
my $label = '';
my $line = '';

my @source_data = [];

local $/ = undef;
$/ = "\n";

open (INFILE, $infile) or die("Unable to open data file \"$infile\"");
@source_data = <INFILE>;
close $infile;

foreach $line(@source_data) {
	if ($line =~ /$ohsu_regex/) {
		$ohsu_id = $1;
		}
	if ($line =~ /$detectunit_regex/) {
		$isunit = 1;	
		}
	if ($line =~ /$member_of_regex/) {
		$member_of = $1;	
		push @{$organization_members{$member_of}}, $ohsu_id;
		#######################################
		# store members in comma delimited list
		#######################################
	#	if ($organization_members{$member_of}) {
	#		$organization_members{$member_of} .= ",$ohsu_id";
	#		} else {
	#		$organization_members{$member_of} = $ohsu_id;
	#		}
		}
	if ($line =~ /$label_scopus_regex/) {
		$scopus_id = $2;
		$label = $1;
		}

	################################
	# Detect end of record and print
	################################
	if ($line =~ /$endrecord_regex/) {
		if ($isunit == 1) {
			$organization_names{$ohsu_id} = $label;
			#print "$scopus_id -- $ohsu_id -- $label\n";
			$scopus_id = '';
			$ohsu_id = '';
			$label = '';
			$isunit = 0;
			}
		}
	}

	######################
	# iterate through keys
	######################
	
	for my $org_key(keys %organization_members) {
		print "$organization_names{$org_key}\n";
		my $members = join(':', @{$organization_members{$org_key}});
		print "$members\n";

		}
