#!/usr/bin/env perl -w

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     S. Sevilla Chill
#     W. Zhou
#     B. Ballew

use strict;
use warnings;
use Test::More qw(no_plan);

do "Q2Manifest.pl";


print("\ncheck_allowed_sample_labels:\n");
my @sample_headers1 = ( "id", "sampleid", "sample id", "sample-id", "featureid", "feature id", "feature-id" );
my @sample_headers2 = ( "#SampleID", "#Sample ID", "#OTUID", "#OTU ID", "sample_name" );
is(check_allowed_sample_labels(\@sample_headers1, \@sample_headers2, "sample id"), 1, "Passes sample id.");
is(check_allowed_sample_labels(\@sample_headers1, \@sample_headers2, "Sample id"), 1, "Passes Sample id.");
is(check_allowed_sample_labels(\@sample_headers1, \@sample_headers2, "#Sample ID"), 1, "Passes #Sample ID.");
is(check_allowed_sample_labels(\@sample_headers1, \@sample_headers2, "#Sample id"), 0, "Detects #Sample id.");
is(check_allowed_sample_labels(\@sample_headers1, \@sample_headers2, "adsf"), 0, "Detects adsf.");

print("\ncheck_no_duplicates:\n");
our %dups;
$dups{"abc"} = 1;
is(check_no_duplicates("def"), 1, "Passes unique sample ID.");
is(check_no_duplicates("abc"), 0, "Detects non-unique sample ID.");
is(check_no_duplicates("abc-1"), 1, "Passes unique but similar sample ID.");

print("\ncheck_no_empty_fields:\n");
is(check_no_empty_fields(" lsfkj	"), 1, "Detects non-empty field.");
is(check_no_empty_fields(" 	"), 0, "Detects empty field with whitespace.");
is(check_no_empty_fields(""), 0, "Detects empty field without whitespace.");

print("\ncheck_header_reqs:\n");
is(check_header_reqs("asfd89.&-_"), 1, "Passes headers without prohibited chars.");
is(check_header_reqs("asfd*89.&-_"), 0, "Detects headers with prohibited * chars.");
is(check_header_reqs("asfd?89.&-_"), 0, "Detects headers with prohibited ? chars.");
is(check_header_reqs("asfd/89.&-_"), 0, "Detects headers with prohibited / chars.");
is(check_header_reqs("asfd\\89.&-_"), 0, "Detects headers with prohibited \\ chars.");

print("\ncheck_sample_id_chars:\n");
is(check_sample_id_chars("1234"), 1, "Passes number-only sample names.");
is(check_sample_id_chars("Sc1234.-"), 1, "Passes alphanumeric, dash, period sample names.");
is(check_sample_id_chars(" Sc1234.-	"), 1, "Passes alphanumeric, dash, period sample names with whitespace.");
is(check_sample_id_chars(" sdf2 098"), 0, "Detects sample names with illegal whitespace.");
is(check_sample_id_chars("asfd98_sfd"), 0, "Detects sample names with illegal characters.");

print("\ncheck_sample_id_len:\n");
is(check_sample_id_len("1234"), 1, "Passes sample name length.");
is(check_sample_id_len("Sc12312312312312312398347584771309234747836afkdjf4.-"), 0, "Detects too-long sample names.");

print("\ncheck_metadata_missing:\n");
is(check_metadata_missing("na"), 0, "Detects na.");
is(check_metadata_missing(" na	"), 0, "Detects na with whitespace.");
is(check_metadata_missing("NA"), 0, "Detects NA.");
is(check_metadata_missing("nan"), 0, "Detects nan.");
is(check_metadata_missing("NAN"), 0, "Detects NAN.");
is(check_metadata_missing("NaN"), 0, "Detects NaN.");
is(check_metadata_missing(""), 1, "Passes blank fields.");

print("\ncheck_metadata_len:\n");
is(check_metadata_len("12.345123123123123123123E-49"), 0, "Detects too-long numbers.");
is(check_metadata_len(" 12.345123123123123123123E-49"), 0, "Detects too-long numbers with whitespace.");
is(check_metadata_len("sdfs90	2^830!#*.&#^s d"), 1, "Passes non-numeric, non-na/nan fields.");