#!/usr/bin/perl

use strict;
use warnings;
 use List::MoreUtils qw(uniq);

my $infile = 'ohsu-metadata.owl';
my $outfile = 'author-data.txt';

open (PARENTORGS, '>:utf8', 'parentorgs.js');
print PARENTORGS "var parentorgs = new Object();\n";
open (SUBORGS, '>:utf8', 'suborgs.js');
print SUBORGS "var suborgs = new Object();\n";
open (AUTHORS, '>:utf8', 'authors.js');
print AUTHORS 'var authors=\'';

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
my %org_hierarchy = ();
my %processed_organizations = ();

my $contains_organizations = '';
my $isunit = 0;
my $record = '';
my $ohsu_id = '';
my $scopus_id = '';
my $record_id = '';
my $members = '';
my $member_of = '';
my $memberships = '';
my $label = '';
my $line = '';

my @source_data = [];
my @indiv_memberships = [];
my @all_organization_members = [];
my @contains_organizations = [];

local $/ = undef;
$/ = "\n";


sub listMembers {
	my ($member_key) = @_;

	for my $member(@{$organization_members{$member_key}}) {
		if ($member =~ /[a-z]/) {
			if (!exists($processed_organizations{$member})) {
				##########################################################
				# Remember processed organization in hash to prevent loops
				##########################################################
				$processed_organizations{$member} = 1;
				push @all_organization_members, $member;
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

sub printOrgHierarchy {
	my @org_keys = keys %org_hierarchy;
	my $entry = '';
	for my $org(@org_keys) {
		$entry = '';
		for my $parent(@{$org_hierarchy{$org}}) {
			if ($entry eq '') {
				$entry = $all_names{$parent};
				} else {
				$entry .= " | $all_names{$parent}";
				}
			if ($entry) {
				print PARENTORGS "parentorgs[\"$org\"]=\"$entry\";\n";
				}
			}
		}
	}

sub printOrgsAndMembers {
	######################
	# iterate through keys
	######################
	my @sorted_orgs = [];
	
	for my $org_key(keys %organization_members) {
		#######################################################################
		# Hash to keep track of processed organizations to avoid recursive loops
		#######################################################################
		%processed_organizations = ();
		$processed_organizations{$org_key} = 1;
		@all_organization_members = [];
		@contains_organizations = [];
		
		$members = '';
		$contains_organizations = '';

		listMembers($org_key);
		$contains_organizations= '';
		@sorted_orgs = [];
		@contains_organizations = [];

		################################################
		# Generate the list of names to string match on 
		################################################

		for my $member(@all_organization_members) {
			if (substr($member,0,5) ne 'ARRAY') {
				if ($member =~ /[a-z]/) {
					push @contains_organizations, "<li>$all_names{$member}</li>";
					if ($contains_organizations eq '') {
						$contains_organizations = "<li>$all_names{$member}</li>";
						} else {
						$contains_organizations .= "<li>$all_names{$member}</li>";
						}
					} else {
						if ($members eq '') {
							$members = $member;
							} else {
							$members .= ", $member";
							}
					}
				}
			}
		#####################################################
		# Generate javascript hash containing the memberships
		#####################################################
		if (length($org_key) > 1 && length($members) > 1 && defined($all_names{$org_key})) {
			print AUTHORS "$org_key\t$all_names{$org_key}\t$members" . '@';
			if ($contains_organizations ne '') {
				@sorted_orgs = sort @contains_organizations;
				$contains_organizations = join(" ", @sorted_orgs);
				$contains_organizations =~ s/ ARRAY.*$//;
				print SUBORGS "suborgs[\"$org_key\"]=\"$contains_organizations\";\n";
				}
			}
		}
	}

open (INFILE, $infile) or die("Unable to open data file \"$infile\"");
@source_data = <INFILE>;
close $infile;

foreach $line(@source_data) {
	######################################
	# Get OHSU identifier. This is the
	# beginning of a record
	######################################
	if ($line =~ /$ohsu_regex/) {
		$ohsu_id = $1;
		$ohsu_id =~ s/[^0-9a-z\-]//g;
		$member_of = '';
		}
	if ($line =~ /$label_regex/) {
		$label = $1;
		}
	if ($line =~ /$scopus_regex/) {
		$scopus_id = $1;
		$scopus_id =~ s/[^0-9]//g;
		$record_id = $scopus_id;
		}

	if ($line =~ /$member_of_regex/) {
		$member_of = $1;	
		###############################################
		# keep a list of memberships until we know this 
		# record is for a person or unit
		###############################################
		}
	if ($line =~ /$detectunit_regex/) {
		$isunit = 1;	
		$record_id = $ohsu_id;
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
		foreach my $membership(@indiv_memberships) {
			##########################################
			# Ignore authors with no SCOPUS ID for now
			##########################################
			if (length($record_id) > 1 && length($member_of) > 1) {
				push @{$organization_members{$member_of}}, $record_id;
				######################################################
				# Print to the hierarcy file so context for orgs
				# is obvious in search results
				# ####################################################
				if ($record_id =~ /[a-z]/) {
					push @{$org_hierarchy{$record_id}}, $member_of;
					}
				}
			}

		$scopus_id = '';
		$ohsu_id = '';
		$record_id = '';
		$label = '';
		$member_of = '';
		$isunit = 0;
		@indiv_memberships = [];
		}
	}

	printOrgsAndMembers();
	printOrgHierarchy();
	print AUTHORS '\';';
	close (AUTHORS);
	close (SUBORGS);
	close (PARENTORGS);
