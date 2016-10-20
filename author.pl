#!/usr/bin/perl

use strict;
use warnings;
 use List::MoreUtils qw(uniq);

my $infile = 'ohsu-metadata.owl';
my $outfile = 'author-data.txt';

#####################################
# store some regexes to get key fields
my $ohsu_regex = qr/<owl:Class rdf:about="http:\/\/ohsu-metadata\/([^"]*)">/; 
my $label_regex = qr/<rdfs:label [^>]*>([^_<]*)[_<]/; 
my $scopus_regex = qr/<ohsu-metadata3:hasIdentifier rdf:datatype="&xsd;string">ScopusAuthor:([0-9]*)</; 
my $member_of_regex = qr/<rdfs:subClassOf rdf:resource="http:\/\/ohsu-metadata\/([^"]*)"/; 
my $detectunit_regex = qr/ohsu-metadata3:hasName rdf:/; 
my $endrecord_regex = qr/<\/owl:Class>/; 

###########################
# Organizations are stored in hashes of hashes and peop
my %organizations = ();
my %all_names = ();
my %organization_members = ();
my %processed_organizations = ();

my $isunit = 0;
my $record = '';
my $ohsu_id = '';
my $scopus_id = '';
my $record_id = '';
my $member_of = '';
my $memberships = '';
my $label = '';
my $line = '';

my @source_data = [];
my @memberships = [];
my @contains_organizations = [];
my @all_organization_members = [];

local $/ = undef;
$/ = "\n";

sub listMembers {
	my ($member_key) = @_;

	for my $@member(@{$organization_members{$member_key}}) {
		if ($member =~ /[a-z]/) {
			if (!exists($processed_organizations{$member})) {
				##########################################################
				# Remember processed organization in hash to prevent loops
				##########################################################
				$processed_organizations{$member} = 1;
				print "$member\n";
				listMembers($member);
				} 
			} else {
			########################################
			# Remember all members in a global array
			########################################
			push @all_organization_members, $member;
			}
		}
	}

sub printOrgsAndMembers {
	######################
	# iterate through keys
	######################
	
	for my $org_key(keys %organization_members) {
		#######################################################################
		# Hash to keep track of processed organizations to avoid recursive loops
		#######################################################################
		%processed_organizations = ();
		$processed_organizations{$org_key} = 1;
		@all_organization_members = [];
		@contains_organizations = [];
		
		listMembers($org_key);
		print "$all_names{$org_key}\n";

		for my $member(@all_organization_members) {
			print "   $member\n";
			}
		}
	}

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
		#push @memberships, $member_of;
		}

	##########################################
	# Detect end of record and reset variables
	##########################################
	if ($line =~ /$endrecord_regex/) {
		##################
		# Record the label
		##################
		if (length($label) > 1) {
			$all_names{$record_id} = $label;
			} else {
			$all_names{$record_id} = "No label for $record_id";
			}

		###################################################
		# Add memberships
		#
		# People and units are stored in same hash but 
		# are treated differently based on ID pattern match
		###################################################
		foreach my $membership(@memberships) {
			##########################################
			# Ignore authors with no SCOPUS ID for now
			##########################################
			if (length($record_id) > 1) {
				push @{$organization_members{$member_of}}, $record_id;
				}
			}

		$scopus_id = '';
		$ohsu_id = '';
		$record_id = '';
		$label = '';
		$isunit = 0;
		@memberships = [];
		}
	}

	printOrgsAndMembers();
