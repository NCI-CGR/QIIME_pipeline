#!/DCEG/Resources/Tools/perl/5.18.0/bin/perl -w
use strict;
use warnings;

#input
##Requires 3 CML arguements -
##1) full path to project directory
##2) full path to the manifest file
##3) full path to output file

#output
##QIIME2 TSV formatted metadata file, in /path/to/projectdirectory/Input

@ARGV==3 or die "
Usage: $0 /path/to/projectdirectory /path/to/manifest /path/to/outputfile";

my $project_dir =$ARGV[0]; #Ex: /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Testing/Project_NP0084-MB4/
my $manifest_fullpath=$ARGV[1]; #Ex: {$project_dir}/NP0084-MB4_08_29_19_metadata_test.txt
my $manifest_output=$ARGV[2]; #Ex: {$project_dir}/Input/manifest_qiime2.tsv

my @lines; my $flag=0;

read_manifest ($manifest_fullpath, \@lines);
check_input(\$flag,\@lines);
if($flag!=1){create_manifest($manifest_output,\@lines);}

sub read_manifest{
	my ($manifest_fullpath, $lines)=@_;

	open my $in, "<:encoding(UTF-8)", $manifest_fullpath or die "$manifest_fullpath: $!";
	@$lines = <$in>; close $in;
	chomp @$lines;

	#Example file
	#SampleID	External-ID	Sample-Type	Source-Material	Source-PCR-Plate	Run-ID	Project-ID	Reciept	Sample_Cat	SubjectID	Sample_Aliquot	Ext_Company	Ext_Kit	Ext_Robot	Homo_Method	Homo-Holder	Homo-Holder2	AFA Setting1	AFA Setting2	Extraction Batch	Residual or Original	Row	Column
	#SC249358	DZ35322 0006_01	ArtificialColony	CGR	PC04924_A_01	180112_M01354_0104_000000000-BFN3F	NP0084-MB4	sFEMB-001-R-002	ExtControl	DZ35322	0	CGR	DSP Virus	QIASymphony	V Adaptor	Tubes	NA	NA	NA	2	Original	A	1
	#SC249359-PC04924-B-01	Stool_20	Stool	CGR	PC04924_B_01	180112_M01354_0104_000000000-BFN3F	NP0084-MB4	sFEMB-001-R-002	Study	IE_Stool	20	CGR	DSP Virus	QIASymphony	V Adaptor	Tubes	NA	NA	NA	2	Original	B	1

	#NOTE: Headers SampleID through Receipt are constant - all other variables may change depending on projects neeeds
}

sub check_input{
	my ($flag, $lines)=@_;
	my $n=1;
	my @header; my @sampleids; my @metavalues;
	my %seen;

	foreach (@lines){
		my @rows = split('\t',$_);

		if ($n==1){
			foreach (@rows){
				push (@header,$_); #Header row has specific reqs
			}
		} else{
			push(@sampleids,$rows[0]); shift @rows; #SampleID col has specific reqs
			foreach (@rows){
				push(@metavalues,$_); #all other columns have specific reqs
			};
		};
		$n++;
	}

	#First variable of header row must be #SampleID.
	#If any other value found, error for the user to fix the manifest and re-try
	if($header[0] ne "#SampleID"){
		print "First column must be #SampleID - check file and re-submit";
		$$flag=1;
	}

	#SampleIDs col must be unique.
	#If there are duplicate sample ID's, error for the user to fix and re-try
	my @duplicates;
	foreach my $sample (@sampleids){
		$seen{$sample}++;
		if($seen{$sample}>1){
			push(@duplicates,$sample);
		}
	}

	if(scalar @duplicates>0){
		print "\nThere were duplicate ID's found in your manifest - correct and resubmit:\n";
		print join( ',', @duplicates); print"\n\n";
		$$flag=1;
	}

	#All other cell rules
}

sub create_manifest{
	my ($manifest_output, $lines)=@_;

	open my $fh, ">$manifest_output";

	foreach (@lines) {
		my $n=0;
		my @columns = split('\t',$_);

		until ($n+1 > scalar(@columns)){
			print $fh "$columns[$n]\t";
			$n++;
		}
		print $fh "\n";
	}
}

exit;
