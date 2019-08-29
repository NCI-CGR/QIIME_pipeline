#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use CPAN;
use File::Copy;
use List::MoreUtils qw(uniq);

#NOTES:
##This script is to complete the pre-processng tasks needed for the QIIME2 pipeline

#input:
## -project directory location
## -text file manifest name

#output:
##

######################################################################################
								##Main Code##
######################################################################################
my (@runid_unique, @projectid, @fastq_files);

my ($project_dir, $manifest_ori)=<STDIN>;

###Testing
#my $project_dir =("T:\\DCEG\\Projects\\Microbiome\\CGR_MB\\MicroBiome\\Project_NP0440_MB4_Complete");
#my $manifest_ori="NP0440_MB4.txt";
# BB: Rather than hard-coding variables, have a testing config file and expected outputs for automated comparisons.
# BB: This should be done entirely in unix, so there should be no windows-style paths.  Changing platforms within a single pipeline can introduce unexpected results.

######################################################################################
								##Subroutines##
######################################################################################

#Create split manifests with metadata
manifest_meta($project_dir, $manifest_ori, @runid_unique);

#Creates directories for flowcells
makedirect_output($project_dir,\@runid_unique);

#Create split manifests with softlinks
fastqfiles($project_dir, \@runid_unique);

manifest_qiime2($project_dir, $manifest_ori);


# BB: Design subroutines to be testable and single-purpose.  Consider how each subroutine can be unit tested.
# BB: Let's be careful not to duplicate effort - snakemake will be used for directory management.  Let's try to leverage that as much as possible.


sub manifest_meta{
	#Initialize variables / Read in variables
	my ($project_dir, $manifest_ori, $runid_unique)=@_;
	my (@sampleid, @externalid, @sampletype, @sourcematerial, @sourcepcrplate, @runid);

	#Set pathway for manifest
	my $manifest_path=$project_dir; $manifest_path.="\\";
	$manifest_path.= $manifest_ori;

	#Open text file
	open my $in, "<:encoding(utf8)", $manifest_path or die "$manifest_path: $!";
	my @lines = <$in>; close $in;
	chomp @lines;

	#Run through each line and save relevant information
	foreach (@lines) {
		my @columns = split('\t',$_);
		push(@sampleid, $columns[0]); #SampleID
		push (@externalid, $columns[1]); #External ID
		push(@sampletype, $columns[2]); #Sample Type
		push(@sourcematerial, $columns[3]); #Source Material
		push(@sourcepcrplate, $columns[4]); #Souce Plate ID
		push (@runid, $columns[5]); #RunID
		push (@projectid, $columns[6]); #Project ID
	}

	#Find all unique run ID's
	@runid_unique = uniq @runid;
	shift @runid_unique;

	#Create split manifests with sample ID's
	my $count = 1;
	my $i=0;

	#Create manifests for each RunID
	foreach my $flowcell_unique (@runid_unique){

		#Create new manifest file based on current count
		my $manifest_file_split_parts = $project_dir;
		$manifest_file_split_parts .= "\\Input\\manifest_file_split_parts\\manifest_split_part_";
		$manifest_file_split_parts .= $count; $manifest_file_split_parts .= ".txt";

		#Open file for manifest split
		open my $fh, ">$manifest_file_split_parts";

		foreach my $flowcell (@runid){
			#If the flowcell of the sample matches the current flow cell
			if ($flowcell =~ $flowcell_unique){
				print $fh "$sampleid[$i]\t";
				print $fh "$externalid[$i]\t";
				print $fh "$sampletype[$i] \t";
				print $fh "$sourcematerial[$i]\t";
				print $fh "$sourcepcrplate[$i]\t";
				print $fh "$runid[$i]\t";
				print $fh "$projectid[$i]\t";

				#Create sample ID name with prefix
				my $sample_name = "Sample_";
				$sample_name .= $sampleid[$i];

				#Generate file path
				my $FastP_rel = "T:\\DCEG\\CGF\\Sequencing\\Illumina\\MiSeq\\PostRun_Analysis\\Data\\$runid[$i]\\CASAVA\\L1\\Project_$projectid[$i]\\$sample_name\\";
				my $FastP_abs = "/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/$runid[$i]/CASAVA/L1/Project_$projectid[$i]/$sample_name/";

				#Open File Directory and copy fastq file names
				opendir(DIR, $FastP_rel) or die "Can't open directory $FastP_rel!";
				my @fastq_temp = grep {/_001\.fastq\.gz$/} readdir(DIR);
				closedir(DIR);

				#Create full file path for each fastq file - Relative
				my $FastP1_rel = $FastP_rel; my $FastP2_rel = $FastP_rel;
				$FastP1_rel .=$fastq_temp[0]; $FastP2_rel .=$fastq_temp[1];

				#Create full file path for each fastq file - Absolute
				my $FastP1_abs = $FastP_abs; my $FastP2_abs = $FastP_abs;
				$FastP1_abs .=$fastq_temp[0]; $FastP2_abs .=$fastq_temp[1];

				#Print to file - if R1 was selected first
				if($FastP1_rel =~ /R1/){
					print $fh "$FastP1_rel\t"; print $fh "$FastP2_rel\t"; #Relative
					print $fh "$fastq_temp[0]\t"; print $fh "$fastq_temp[1]\t"; #File name
					print $fh "$FastP1_abs\t"; print $fh "$FastP2_abs\n"; #Absolute
				#otherwise, if R2 was selected first
				} else{
					print $fh "$FastP2_rel\t"; print $fh "$FastP1_rel\t";
					print $fh "$fastq_temp[1]\t"; print $fh "$fastq_temp[0]\t";
					print $fh "$FastP2_abs\t"; print $fh "$FastP1_abs\n"; #Absolute
				}
			}
			$i++;
		}
		$i=0;
		close $fh;
		$count++;
	}
	print "\n***********************************";
	print "Step 3 COMPLETE - Generated metadata split manifests\n";
}

sub makedirect_output{
	#Initialize variables / Read in variables
	my ($project_dir, $runid_unique)=@_;
	my $dir_path;

	#Make Input directory
	my $inp_dir = $project_dir;
	$inp_dir.= "\\Input\\Fasta";

	my $count=1;

	foreach my $dir_new (@$runid_unique){

		#Add Input to the directory path
		my $dir_name = $inp_dir;
		$dir_name .="\\fasta_dir_split_part_";
		$dir_name .= $count;

		#Make new directory
		mkdir($dir_name);
		$count++;
	}

	my $length = scalar (@$runid_unique);
	print "\n***********************************";
	print "Step 4 COMPLETE - Generated directories for $length flowcell(s)\n";
}

sub fastqfiles{
	#Initialize variables / Read in variables
	my ($project_dir, $runid_unique)=@_;
	my $count=1;
	my $wsh = new Win32::OLE 'WScript.Shell';

	#Set pathway for manifest (split meta files)
	my $manifest_path=$project_dir; $manifest_path.="\\Input\\manifest_file_split_parts\\manifest_split_part_";

	#Set pathway for FASTQ files to be copied
	my $fastq_parent=$project_dir; $fastq_parent.="\\Input\\Fasta\\fasta_dir_split_part_";

	#Create new manifest file based on current count
	my $manifest_file_split_fastq = $project_dir;
	$manifest_file_split_fastq .= "\\Input\\manifest_file_split_parts_fastq_import\\manifest_file_split_parts_fastq_import_";

	#Determine number of flowcells
	my $count_flowcells = scalar(@$runid_unique);

	while ($count_flowcells>$count-1){

		#Split meta file full path
		my $file1 = $manifest_path;
		$file1.= $count; $file1 .= ".txt";

		#Open split meta file
		open my $fh1, "<:encoding(utf8)", $file1 or die "$file1: $!";
		my @lines = <$fh1>; close $fh1;
		chomp @lines;

		#New split fastq file
		my $file2 = $manifest_file_split_fastq;
		$file2.= $count; $file2 .= ".txt";

		#Open split fastq file, print header
		open my $fh2, ">$file2";
		print $fh2 "sample-id,absolute-filepath,direction\n";

		#Fastq full path
		my $fastq_dest = $fastq_parent; $fastq_dest.= $count;

		#Print message for user to know status
		print "\n***********************************";
		print "Creating links and manifest for $runid_unique[$count-1]";

		#add each line to new file
		foreach (@lines) {
			my @columns = split('\t',$_);

			#Forward
			print $fh2 "$columns[0],";
			print $fh2 "$columns[11],"; #absolute path
			print $fh2 "forward\n";

			#Generate new link name
			my $link_new = $fastq_dest; $link_new.="\\"; $link_new .= $columns[9]; $link_new .=".lnk";

			#Create soft links
			my $lnk_path = $link_new;
			my $target_path = $columns[7]; #relative path
			my $shcut = $wsh->CreateShortcut($lnk_path) or die "Can't create $lnk_path";
			$shcut->{'TargetPath'} = $target_path;
			$shcut->Save;

			#Reverse
			print $fh2 "$columns[0],";
			print $fh2 "$columns[12],"; #relative path
			print $fh2 "reverse\n";

			#Generate new link
			$link_new = $fastq_dest; $link_new.="\\"; $link_new .= $columns[10]; $link_new .=".lnk";

			#Create soft links
			$lnk_path = $link_new;
			$target_path = $columns[8];
			$shcut = $wsh->CreateShortcut($lnk_path) or die "Can't create $lnk_path";
			$shcut->{'TargetPath'} = $target_path;
			$shcut->Save;
		}
		$count ++;
		close $fh1;
		close $fh2;
	}

	print "\n***********************************";
	print "Step 5 COMPLETE - Generated QIIME2 split manifests and transferring all FASTQ files\n";
}

#7/10/19 - fixed columns to remove skips in old manifest format
