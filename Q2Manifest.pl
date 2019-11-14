#!/usr/bin/env perl -w

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     S. Sevilla Chill
#     W. Zhou
#     B. Ballew

use strict;
use warnings;
use File::Basename;

@ARGV==1 or die "
Usage: $0 /path/to/manifest.txt\n
Manifest will be checked for the following QIIME2 requirements:
  - First field of header row must be one of the following:
  \tCase insensitive: id, sampleid, sample id, sample-id, featureid, feature id, feature-id;
  \tCase sensitive: \#SampleID, \#Sample ID, \#OTUID, \#OTU ID, sample_name
  - No empty header fields
  - No \\, /, *, or ? characters
  - No duplicates in header fields
  - No overlap with allowable sample field labels
  - No overlap bewteen sample IDs and allowable sample field labels
  - No empty IDs (note that leading/trailing whitespaces are ignored throughout)
  - Sample IDs can contain only alphanumerics, period, or dash
  - Sample IDs must be <= 36 characters
  - Sample IDs can't start with \"#\" but comment lines can
  - Missing data must be represented by a blank field, not NA, nan, etc
  - Numeric metadata fields <=15 chars
  - At least one line of data
  - No duplicate sample IDs
See QIIME documentation and/or keemei.qiime2.org for more details.\n";
# was anything about the manifest being changed when printed?

my $in_file=$ARGV[0];

chomp( $in_file );
die "ERROR: $in_file is not readable or contains no data.\n" if( ! -r $in_file || ! -s $in_file );

open( my $in, "<:encoding( UTF-8 )", $in_file ) or die "ERROR: Can't open $in_file: $!";

my $first_line = <$in>;  # separate header line
my @headers = split( /\t/, $first_line );
my $first_header = shift( @headers );

# QIIME req: First variable of header row must be one of the following;
# @sample_headers1 are case-insensitive; @sample_headers2 are case-sensitive
my @sample_headers1 = ( "id", "sampleid", "sample id", "sample-id", "featureid", "feature id", "feature-id" );
my @sample_headers2 = ( "#SampleID", "#Sample ID", "#OTUID", "#OTU ID", "sample_name" );
if( ! check_allowed_sample_labels( \@sample_headers1, \@sample_headers2, $first_header )) {
    my $err_msg = "ERROR: First field of header line must be one of the following:\n";
    print_sample_labels( \@sample_headers1, \@sample_headers2, $err_msg );
    die "\n";
}

# HEADER CHECKS:
our %dups; # lexically scoped but globally aliased so it doesn't need to be passed to subroutines - makes unit testing much easier when just returning 0/1 vs. that plus a reference
my $i = 0;
foreach( @headers ) {
    $i++;
    # QIIME req: No empty header fields.
    die "ERROR: Empty header field detected in column $i.\n" if ( ! check_no_empty_fields( $_ ));
    # QIIME req: No special characters. (Poorly defined in 2017.  2019 allows all unicode chars.)
    die "ERROR: Prohibited character detected in header \"$_\".\n" if( ! check_header_reqs( $_ ));
    # QIIME req: No duplicates in header fields.
    die "ERROR: Duplicate values \"$_\" detected in header.\n" if( ! check_no_duplicates( $_ ));
    # QIIME req: No overlap with allowable sample field labels.
    if( check_allowed_sample_labels( \@sample_headers1, \@sample_headers2, $_ )) {
        my $err_msg = "ERROR: \"$_\" prohibited.  Except for the first field, headers may not include:\n";
        print_sample_labels( \@sample_headers1, \@sample_headers2, $err_msg );
        die "\n";
    }
}

# SAMPLE AND METADATA CHECKS:
my @sample_ids;
my $line_count = 0;
my $j = 0;
while( my $row = <$in> ) {  # operate on input manifest line-by-line instead of reading into memory
    $j++;
    if( $row =~ /\S/ ) {
        $line_count++;  # increment line count for non-empty lines only
        my @line = split( /\t/, $row );
        my $sample_id = shift( @line );
        push( @sample_ids, $sample_id);
        # QIIME req: No overlap bewteen sample IDs and allowable sample field labels
        if( check_allowed_sample_labels( \@sample_headers1, \@sample_headers2, $sample_id )) {
            my $err_msg = "ERROR: \"$sample_id\" prohibited.  Sample IDs may not include:\n";
            print_sample_labels( \@sample_headers1, \@sample_headers2, $err_msg );
            die "\n";
        }
        # QIIME req: No empty IDs (note that leading/trailing whitespaces are ignored throughout)
        die "ERROR: Empty sample ID field detected in row $j.\n" if ( ! check_no_empty_fields( $sample_id ));
        # QIIME req: Sample IDs can contain only alphanumerics, period, or dash
        die "ERROR: Sample ID \"$sample_id\" contains prohibited characters.\n" if( ! check_sample_id_chars( $sample_id ));
        # QIIME req: Sample IDs must be <= 36 characters
        die "ERROR: Sample ID \"$sample_id\" is longer than 36 characters.\n" if ( ! check_sample_id_len( $sample_id ));
        # QIIME req: Sample IDs can't start with "#" but comment lines can
        warn "WARNING: Rows starting with the pound sign (#) will be ignored.\n" if( $sample_id =~ /^#/ );
        foreach( @line ) {
            # QIIME req: Missing data must be represented by a blank field, not NA, nan, etc.
            die "ERROR: Missing data must be represented as a blank field, not \"$_\".\n" if( ! check_metadata_missing( $_ ));
            # QIIME req: (From Sam) Numeric fields <=15 chars
            die "ERROR: \"$_\" too long.  Numeric metadata fields must have 15 or fewer characters.\n" if( ! check_metadata_len( $_ ));
        }
    }
}

# ROW CHECKS:
# QIIME req: At least one line of data
die "ERROR: No non-empty data lines detected.\n" if( $line_count == 0 );
# QIIME req: No duplicate sample IDs
foreach( @sample_ids ) {
    die "ERROR: Duplicate sample IDs \"$_\" detected.\n" if( ! check_no_duplicates( $_ ));
    # note that the above relies on the same "our %dups" as headers - only a
    # problem if headers have the same names as samples, which shouldn't happen.
}


sub check_allowed_sample_labels {
    # returns true if label matches one of the allowed values
    my( $sample_headers1, $sample_headers2, $field ) = @_;
    my @sample_headers1 = @{$sample_headers1};
    my @sample_headers2 = @{$sample_headers2};
    my $sample_flag = 0;
    foreach( @sample_headers1 ) {
        if( lc( $field ) eq lc( $_ )) {
            $sample_flag = 1;
        }
    }
    foreach( @ sample_headers2 ) {
        if( $field eq $_ ) {
            $sample_flag = 1;
        }
    }
    return $sample_flag;
}

sub print_sample_labels {
    my( $sample_headers1, $sample_headers2, $msg ) = @_;
    my @sample_headers1 = @{$sample_headers1};
    my @sample_headers2 = @{$sample_headers2};
    print( $msg );
    print( "Case insensitive:\n" );
    foreach( @sample_headers1 ) {
        print( "\t$_\n" );
    }
    print( "Case sensitive:\n" );
    foreach( @sample_headers2 ) {
        print( "\t$_\n" );
    }
}

sub check_no_duplicates {
    # returns true if no dups found
    # relies on a hash declared with "our" - lexical but
    # aliased to variable of same name in current pkg
    my ( $field ) = @_;
    $dups{$field}++ ? return (0) : return (1);
}

sub check_no_empty_fields {
    # returns true if any non-whitespace char is found
    my ( $field ) = $_[0];
    $field !~ /\S/ ? return 0 : return 1;
}

sub check_header_reqs {
    # returns true if string does not contain prohibited chars
    my ( $field ) = $_[0];
    # QIIME documentation for 2017.11 states "cannot contain certain 
    # special characters (e.g. /, \, *, ?, etc.)"
    # We don't know what "etc" includes, so just checking for the
    # explicitly listed chars.
    ( $field =~ /[\/\\\*?]/ ) ? return 0 : return 1;
}

sub check_sample_id_chars {
    # returns true if sample name has only allowed chars
    my ( $sample ) = $_[0];
    ( $sample !~ /^\s*[A-Za-z0-9\.-]+\s*$/ ) ? return 0 : return 1;
}

sub check_sample_id_len {
    # returns true if sample name isn't too long
    my ( $sample ) = $_[0];
    ( length( $sample ) > 36 ) ? return 0 : return 1;
}

sub check_metadata_missing {
    # returns true if metadata does not contain na/nan
    my ( $field ) = $_[0];
    ( lc( $field ) =~ /^\s*nan\s*$|^\s*na\s*$/ ) ? return 0 : return 1;
}

sub check_metadata_len {
    # returns true if metadata meets length req
    my ( $field ) = $_[0];
    ( $field =~ /^\s*[0-9\.,Ee\-+]+\s*$/ && length( $field ) > 15 ) ? return 0 : return 1;
}