######################################################################################
								##NOTES##
######################################################################################
###This script converts the manifest file from LIMS to the correct UNIX manifest needed 
###for QIIME2 analysis

# Name of file: Manifest_Convert.pl
# Your name: Samantha Sevilla
# Date: 4/23/18
######################################################################################
								##Main Code##
######################################################################################
use warnings; use strict;
use Cwd; use File::chdir; use File::Copy;
my $logs;

#Ask user if they want to create, or check a manifest
print "Do you want to create (1), or check(2) a manifest?\n";
my $ans = <STDIN>; chomp $ans;

if ($ans==1){
	#Ask user for the manifest file location
	print "What is the path to your manifest file (generated from LIMS)\n";
	my $dir_path = <STDIN>; chomp $dir_path;
	#	my $dir_path="T:\\DCEG\\CGF\\TechTransfer\\Microbiome\\Extraction\\Optimization\\Fresh Fecal Optimization_2017.08\\Analysis"; ##Testing
	
	#Ask user for QIIME2 path folder
	print "\nWhat is the path to the QIIME analysis folder\n";
	my $anal_path = <STDIN>; chomp $anal_path;
	#	my $anal_path = "T:\\DCEG\\Projects\\Microbiome\\CGR_MB\\MicroBiome\\Project_NP0084_MB4and5"; ##Testing
		
	#Call Sub-Routes
	convertfile($dir_path, $anal_path);
} else {
	#Ask user for QIIME2 path folder
	print "\nWhat is the path to the QIIME analysis folder\n";
	my $anal_path = <STDIN>; chomp $anal_path;

	#Call Sub-Routes
	checkfile($anal_path);

}
#################################################################################################################################
							##SUBROUTINES##
#################################################################################################################################

sub convertfile {
	
	#Initialize variables
	my($dir_path, $anal_path)=@_;
	my @manifest; my @storage;
	
	#Change directory to the manifest location
	$CWD=$dir_path;
	
	#Store the manifest file
	opendir(DIR, $dir_path) or die "Can't open directory $dir_path!";
	@manifest = grep (-f, <*.txt>);
	closedir(DIR);
	
	#Read in manifest file
	open(READ_FILE, $manifest[0]);
	my @temp = <READ_FILE>;
	close (READ_FILE);
	
	#Read through each line of the directory
	for my $line (@temp) {
		#Remove carriage return
		$line =~  s/\r\n$/\n/;		

		#Store each files data
		push(@storage, $line);
	}

	#Change directory to the final file location
	$CWD=$anal_path;

	#Name the new file
	my $new_file="manifest.txt";
		
	#Print the compiled log to a new file
	open (FILE, ">$new_file") or die "Error creating new file";
		print (FILE @storage);
		close (FILE);
		
	print "\n***Manifest conversion complete***\n";
	print "File stored: $anal_path\n";
}

sub checkfile{

	#Initialize variables
	my($anal_path)=@_;
	my @manifest; my @storage;
	
	#Change directory to the manifest location
	$CWD=$anal_path;
	
	#Store the manifest file
	opendir(DIR, $anal_path) or die "Can't open directory $anal_path!";
	@manifest = grep (-f, <*.txt>);
	closedir(DIR);
	
	#Read in manifest file
	open(READ_FILE, $manifest[0]);
	my @temp = <READ_FILE>;

	#Read through each line of the directory
	for my $line (@temp) {
		print "$line";
	}
}