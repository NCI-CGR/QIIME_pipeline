#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use CPAN;
use File::Copy;
use List::MoreUtils qw(uniq);
use Win32::OLE;

######################################################################################
								##NOTES##
######################################################################################
##This script is to complete the pre-processng tasks needed for the QIIME2 pipeline
##Search for ###TESTING to find testing variables

######################################################################################
								##Main Code##
######################################################################################
my (@runid_unique, @projectid, @fastq_files);

#Ask user where the project directory is
print "Where is the project directory?\n";
print "ANS: ";
#my $project_dir = <STDIN>; chomp $project_dir;

#Ask user what type of file is being used
print "\n\nWhat is the name of the manifest file (without .txt)?\n";
print "ANS: ";
#my $manifest_ori=<STDIN>; chomp $manifest_ori;
#$manifest_ori .=".txt";

###Testing
my $project_dir =("T:\\DCEG\\Projects\\Microbiome\\CGR_MB\\MicroBiome\\Testing\\Project_NP0440_MB4_SSC");
my $manifest_ori="NP0440_MB4.txt";

######################################################################################
								##Subroutines##
######################################################################################
print "######################################\n";
print "#              Workflow               #\n";
print "######################################\n";
print "1) Create directories\n";
print "2) QIIME2 manifest generation\n";
print "3) Create meta-data split manifests\n";
print "4) Create directories for FASTQ files\n";
print "5) Create and place links for FASTQ files in directories\n";
print "######################################\n\n";

print "######################################\n";
print "#              Process                #\n";
print "######################################\n";

#Create directories within Input folder
makedirect_input($project_dir);

#Create QIIME2 manifest
manifest_qiime2($project_dir, $manifest_ori);

#Create split manifests with metadata
manifest_meta($project_dir, $manifest_ori, @runid_unique);

#Creates directories for flowcells
makedirect_output($project_dir,\@runid_unique);

#Create split manifests with softlinks
fastqfiles($project_dir, \@runid_unique);

sub makedirect_input{
	#Initialize / Read in variables
	my ($project_dir)=@_;
	my $dir_path; 
	
	#Make Input directories nested under Project
	my $inp_dir = $project_dir;
	$inp_dir.= "\\Input";
	mkdir($inp_dir);
	
	#Make directories nested under Input
	my @directory_list = ("\\tmp", "\\manifest_file_split_parts", "\\manifest_file_split_parts_fastq_import", "\\Fasta");
		
	#Create new directories from list	
	foreach my $dir_new (@directory_list){
		
		#Add Input to the directory path
		$dir_path = $inp_dir;
		$dir_path .= $dir_new;
		
		#Make new directory
		mkdir($dir_path);
	}

	#MakeOutput directories nested under Project
	my $outp_dir = $project_dir;
	$outp_dir .= "\\Output";
	mkdir($outp_dir);
	
	#Make directories nested under Output
	@directory_list = ("\\Log", "\\qza_results", "\\qzv_results");
		
	#Create new directories from list	
	foreach my $dir_new (@directory_list){
		
		#Add Input to the directory path
		$dir_path = $outp_dir;
		$dir_path .= $dir_new;
		
		#Make new directory
		mkdir($dir_path);
	}
		
	#Make QZA directories
	$outp_dir = $project_dir;
	$outp_dir.= "\\Output\\qza_results";
	
	#Make directories nested under Input \ QZA
	@directory_list = ("\\abundance_qza_results", "\\demux_qza_split_parts", "\\phylogeny_qza_results", "\\repseqs_dada2_qza_merged_parts_final","\\repseqs_dada2_qza_merged_parts_tmp", "\\repseqs_dada2_qza_split_parts", "\\table_dada2_qza_merged_parts_final", "\\table_dada2_qza_merged_parts_tmp", "\\table_dada2_qza_split_parts", "\\taxonomy_qza_results");
	
	#Create new directories from list
	foreach my $dir_new (@directory_list){
		
		#Add Input to the directory path
		$dir_path = $outp_dir;
		$dir_path .= $dir_new;
		
		#Make new directory
		mkdir($dir_path);
	}
	
	#Make QZV directories
	$outp_dir = $project_dir;
	$outp_dir.= "\\Output\\qzv_results";
	
	#Make directories nested under Input \ QZV
	@directory_list = ("\\demux_qzv_split_parts", "\\otu_relative_abundance_results", "\\rarefaction_qzv_results", "\\repseqs_dada2_qzv_merged_parts_final", "\\table_dada2_qzv_merged_parts_final","\\taxonomy_qzv_results", "\\taxonomy_relative_abundance_results");
		
	#Make new directories from list	
	foreach my $dir_new (@directory_list){
		
		#Add Input to the directory path
		$dir_path = $outp_dir;
		$dir_path .= $dir_new;
		
		#Make new directory
		mkdir($dir_path);
	}
	
	#Make Log directories
	$outp_dir = $project_dir;
	$outp_dir.= "\\Output\\Log";
	
	#Make directories nested under Input \ Log
	@directory_list = ("\\stage2_qiime2", "\\stage3_qiime2", "\\stage4_qiime2", "\\stage5_qiime2");
	
	#Make new directories from list	
	foreach my $dir_new (@directory_list){
		
		#Add Input to the directory path
		$dir_path = $outp_dir;
		$dir_path .= $dir_new;
		
		#Make new directory
		mkdir($dir_path);
	}
	print "\n\n***********************************";
	print "Step 1 COMPLETE - Generated directories";
}

sub manifest_qiime2{
	#Initialize variables / Read in variables
	my ($project_dir, $manifest_ori)=@_;
	my $i=1;

	#Set pathway for original manifest
	my $manifest_path=$project_dir; $manifest_path.="\\";
	$manifest_path.= $manifest_ori; 

	#Set pathway and name for qiime2 file
	my $MANIFEST_FILE_QIIME = $project_dir; $MANIFEST_FILE_QIIME .="\\Input\\manifest_qiime2.tsv";
	open my $fh, ">$MANIFEST_FILE_QIIME";
	
	#Open, read original manifest file
	open my $in, "<:encoding(utf8)", $manifest_path or die "$manifest_path: $!";
	my @lines = <$in>; close $in;
	chomp @lines;
	
	#Run through each line and save relevant information
	foreach (@lines) {
		my @columns = split('\t',$_);
		
		#For the header row
		if ($i==1){
			print $fh "#SampleID\t";
			print $fh "CGR ID\t";
			
			my $n=1; #Skip "SampleID header - changed to CGR ID"
			until ($n+1 > scalar(@columns)){
				print $fh "$columns[$n]\t";
				$n++;
			}
			print $fh "\n";
			$i++;
		} else{
		
			#Created new SampleID name from ExternalID (col1)_ SourcePCRPlate (col4), print to QIIME2 file
			print $fh "$columns[1]";
			print $fh "_";
			print $fh "$columns[4]\t";
			
			#Print other data to QIIME2 File
			my $n=0;
			until ($n+1 > scalar(@columns)){
				print $fh "$columns[$n]\t";
				$n++;
			}
			print $fh "\n";
			$i++;
		} 
	}
	
	print "\n\n***********************************";
	print "Step 2 COMPLETE - Generated QIIME2 manifest\n";
}

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
		push(@sourcepcrplate, $columns[5]); #Souce Plate ID - skip #4 Extraction Batch ID
		push (@runid, $columns[6]); #RunID
		push (@projectid, $columns[7]); #Project ID
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
		
		#Open two files, one for manifest split, and one for QIIME input
		open my $fh, ">$manifest_file_split_parts";

		#Print header
		#print $fh "Sample ID\t External ID\t Sampletype \t sourcematerial \t plateid\t runid\t projectid\t R1path\t R2path\t R1name\t R2name\n";
		
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
