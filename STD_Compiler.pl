######################################################################################
								##NOTES##
######################################################################################
###This script compiles either the STDOUT or STDERR files from QIIME2 Microbiome pipeline V1
###and prints them to a txt file

# Name of file: STD_Compiler.pl
# Your name: Samantha Sevilla
# Date: 4/8/18
######################################################################################
								##Main Code##
######################################################################################
use warnings; use strict;
use Cwd; use File::chdir; use File::Copy;
my $logs;

#Ask user for the log file location
print "What is the path to your Log files\n";
my $dir_path = <STDIN>; chomp $dir_path;

#Ask user for which file type
print "\nWhich files do you want to compile\n";
print "   1: STOUT\n";
print "   2: STDERROR\n";
my $type = <STDIN>; chomp $type;

#Ask user if complete or parital logs
print "\nDo you want to run complete, or partial (C or P)?\n";
my $complete = <STDIN>; chomp $complete;
if ($complete=~"P"){
	print "\nHow many logs have completed (3-8)?\n";
	$logs =<STDIN>; chomp $logs;
	} else {$logs =9};

#Call Sub-Routes
read_file($dir_path, $type, $logs);

#################################################################################################################################
							##SUBROUTINES##
#################################################################################################################################

sub read_file {
	
	#Initialize variables
	my($master_path, $type, $logs)=@_;
	my @files; my @temp; my @storage;
	my $end; my $file_path; my $new_file;
	my $n=3; my $dir_path; my @header;
	$CWD=$master_path;
	
	#Determine which type of file to compile; Name output text file
	if($type==1){
		$end =".stdout";
		$new_file="STD_OUT_compiled.txt";
	} else{
		$end=".stderr";
		$new_file="STD_ERR_compiled.txt";
	}
	
	#For each of the stages (3-9), open the directory, read in all of the specified file types, and print to a text file
	until ($n>$logs){
		
		#Create path for each stage (3-9)
		$dir_path= $master_path;
		$dir_path.="\\stage$n\_qiime2";
		
		#Run through each directory, find specific file type
		opendir(DIR, $dir_path) or die "Can't open directory $dir_path!";
		@files = grep {/$end$/} readdir(DIR);
		closedir(DIR);

		#Store the stage information which will be printed to text file
		@header = ("***************************************", "STAGE $n INFORMATION", "***************************************");
		for my $line (@header){
			push (@storage, $line)
		} push (@storage, "\n\n");
		
		#Read through each file of the directory
		for my $file (@files) {
			
			#Move through each file path
			$file_path = $dir_path; $file_path .= "\\$file";
			
			#If filename not provided, give error message and close
			unless (open(READ_FILE, $file_path)) {
				print "Cannot open file \$file_path\"\n\n";
				exit;
			}
			
			#Store each files data
			@temp = <READ_FILE>;
			push(@storage, @temp);
		}
		$n++;
	}
	
	#Print the compiled log to a new file
	open (FILE, ">$new_file") or die;
		print (FILE @storage);
		close (FILE);
		
	print "\n***Compilation Completed***\n";
	print "Compiled file stored: $master_path\n";

}