#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

#input
##Requires 2 CML arguements -
##1) full path to split manifest files
##2) full path to the output files

#output
##symlinks for fasta files in split fasta directories

@ARGV==2 or die "
Usage: $0 /path/to/splitmanifest /path/to/splitfastaoutputdir";

my $manifest_file_split_fastq_dir =$ARGV[0];
my $fastq_dir=$ARGV[1];

create_symlinks($manifest_file_split_fastq_dir,$fastq_dir);

######################################################################################
								##Subroutines##
######################################################################################
sub create_symlinks2{
	my ($manifest_file_split_fastq,$fastq_dir)=@_;
	#Open split meta file
	open my $fh, "<:encoding(utf8)", $manifest_file_split_fastq or die "$manifest_file_split_fastq: $!";
	my @lines = <$fh>; close $fh;
	chomp @lines;
	shift @lines;

	foreach (@lines) {
		my @columns = split(',',$_);

		my $location_old = "$columns[1]";

		my $file_name = $location_old =~ /(SC[-_0-9A-Z]+001)/; $file_name=$1;
		my $location_new = "$fastq_dir/$file_name.fastq.gz";

		print "OLD: $location_old\n";
		print "NEW: $location_new\n\n";
		symlink($location_old, $location_new);
	}
}

sub create_symlinks{
	my ($manifest_file_split_fastq_dir,$fastq_dir)=@_;

	opendir(DIR, $manifest_file_split_fastq_dir) or die "Can't open directory $manifest_file_split_fastq_dir!";
	my @manifest_splits= grep {/.txt/} readdir(DIR);
	closedir(DIR);

	$fastq_dir =~ /_(\d+)/;
	my $flowcell_number=$1;

	my $manifest_file_split_fastq=$manifest_file_split_fastq_dir .="manifest_file_split_parts_fastq_import_$flowcell_number.txt";

	#Open split meta file
	open my $fh, "<:encoding(utf8)", $manifest_file_split_fastq or die "$manifest_file_split_fastq: $!";
	my @lines = <$fh>; close $fh;
	chomp @lines;
	shift @lines;

	foreach (@lines) {
		my @columns = split(',',$_);

		my $location_old = "$columns[1]";

		my $file_name = $location_old =~ /(SC[-_0-9A-Z]+001)/; $file_name=$1;
		my $location_new = "$fastq_dir/$file_name.fastq.gz";

		symlink($location_old, $location_new);
	}
}
exit;
