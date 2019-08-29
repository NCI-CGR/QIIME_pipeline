#!/usr/bin/perl
use strict;
use warnings;
use Cwd;


######################################################################################
								##NOTES##
######################################################################################
##Create symlinks for fastq files

######################################################################################
								##Subroutines##
######################################################################################


	my $manifest_file_split_fastq="/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Project_NP0501_MB1and2/Completed_WithMetadata/Input/manifest_file_split_parts_fastq_import/manifest_file_split_parts_fastq_import_1_sym.txt";
			
	#Set pathway for FASTQ files to be copied
	my $fastq_store="/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Project_NP0501_MB1and2/Completed_WithMetadata/Input/Fasta/fasta_dir_split_part_1";
			
	#Open split meta file
	open my $fh1, "<:encoding(utf8)", $manifest_file_split_fastq or die "$manifest_file_split_fastq: $!";
	my @lines = <$fh1>; close $fh1;
	chomp @lines;
	shift @lines;	
	foreach (@lines) {
		my @columns = split('\t',$_);
		
		my $orifile = "$columns[0]";
		my $filename = $fastq_store; $filename .= "/$columns[1]";
		
		symlink($orifile, $filename);
	}
	
	close $fh1;	