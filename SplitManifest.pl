#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use CPAN;
use List::MoreUtils qw(uniq);

#input:
##Requires 3 CML arguements-
	#1) fastq data abs file path
	#2) full path to QIIIME2 TSV manifests
	#3) full path to split manifest file(s)

#output:
## split txt manifest file(s), N=# of flowcells

#usage:
@ARGV==3 or die "
Usage: $0 /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/ /path/to/QIIME2_TSV_manifest /path/to/outputfile";

######################################################################################
								##Main Code##
######################################################################################
my $fastq_abs_path=$ARGV[0];
my $manifest_fullpath=$ARGV[1];
my $manifest_splitman=$ARGV[2];

my @lines;

read_manifest ($manifest_fullpath, \@lines);
create_manifest($fastq_abs_path, $manifest_splitman, \@lines);

######################################################################################
								##Subroutines##
######################################################################################
sub read_manifest{
	my ($manifest_fullpath, $lines)=@_;

	open my $in, "<:encoding(UTF-8)", $manifest_fullpath or die "$manifest_fullpath: $!";
	@$lines = <$in>; close $in;
	chomp @$lines;
}

sub create_manifest{
	#Initialize variables / Read in variables
	my ($fastq_abs_path, $manifest_splitman, $lines)=@_;
	my (@sampleid, @runid, @projectid);

	foreach (@lines){
		my @rows = split('\t',$_);

		push(@sampleid,$rows[0]);
		push(@runid,$rows[5]);
		push(@projectid,$rows[6]);
	}

	my $current_flowcell =$manifest_splitman;
	$current_flowcell=~ s/\/DCEG.*manifest_//;
	$current_flowcell =~ s/.txt//;

	#Create split manifests with sample ID's
	my $count = 1;
	my $i=0;

	#Open file for manifest split
	open my $fh, ">$manifest_splitman";
	print $fh "sample-id,absolute-filepath,direction\n";

	foreach my $flowcell (@runid){
		#If the flowcell of the sample matches the current flow cell
		if ($flowcell =~ $current_flowcell){

				#Generate file path
				#my $FastP_rel = "T:\\DCEG\\CGF\\Sequencing\\Illumina\\MiSeq\\PostRun_Analysis\\Data\\$runid[$i]\\CASAVA\\L1\\Project_$projectid[$i]\\$sample_name\\";
				my $FastP_abs = $fastq_abs_path;
				$FastP_abs .= "$runid[$i]/CASAVA/L1/Project_$projectid[$i]/Sample_$sampleid[$i]/";

				#Open File Directory and copy fastq file names
				opendir(DIR, $FastP_abs) or die "Can't open directory $FastP_abs!";
				my @fastq_temp = grep {/_001\.fastq\.gz$/} readdir(DIR);
				closedir(DIR);

				my $FastP1_abs = $FastP_abs;
				$FastP1_abs .=$fastq_temp[0];

				my $FastP2_abs = $FastP_abs;
				 $FastP2_abs .=$fastq_temp[1];

				#Print to file - if R1 was selected first
				if($FastP1_abs =~ /R1/){
					print $fh "$sampleid[$i],";
					print $fh "$FastP1_abs,";
					print $fh "forward\n";

					print $fh "$sampleid[$i],";
					print $fh "$FastP2_abs,";
					print $fh "reverse\n";
				#otherwise, if R2 was selected first
				} else{
					print $fh "$sampleid[$i],";
					print $fh "$FastP2_abs,";
					print $fh "forward\n";

					print $fh "$sampleid[$i],";
					print $fh "$FastP1_abs,";
					print $fh "reverse\n";
				}
			}
			$i++;
		}
		close $fh;
}
