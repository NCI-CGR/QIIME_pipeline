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
check_input($project_dir,\$flag,\@lines);
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
	my ($project_dir,$flag, $lines)=@_;
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
	my $checkheader=0;
	if($header[0] ne "#SampleID"){
		$checkheader=1;
		$$flag=1;
	}

	#All header varibles and SampleIDs col must be unique and cannot be empty.
	#If there are duplicate sample ID's, error for the user to fix and re-try
	my @checkduplicates; my $checkempty=0;
	foreach my $sample (@sampleids){
		if(length($sample)<1){
			$checkempty++;
			$$flag=1;
		}
		$seen{$sample}++;
		if($seen{$sample}>1){
			push(@checkduplicates,$sample);
			$$flag=1;
		}
	}

	foreach my $headerval (@header){
		if(length($headerval)<1){
			$checkempty++;
			$$flag=1;
		}
		$seen{$headerval}++;
		if($seen{$headerval}>1){
			push(@checkduplicates,$headerval);
			$$flag=1;
		}
	}

	#All other cell rules
	my @checknumlength; my @checkna;
	foreach my $metadata (@metavalues){
		if ($metadata =~ /^[0-9,.E]+$/ ) {
			if(length($metadata)>15){ #Numeric metadata values have a 15 digit length
				push(@checknumlength,$metadata);
				$$flag=1;
			}
		} else{
			if($metadata=~"NAN" || $metadata=~"nan"){ #QIIME will accept, but gives warning for downstream problems
				push (@checkna, $metadata);
				$$flag=1;
			}
		}
	}

	#Print out errors found to output file
	if($$flag==1){
		#my $errorfile = $project_dir .= "errors.txt";
		open my $fh,">$project_dir/errors.csv";

		if($checkheader==1){
			print $fh "First column must be #SampleID - check file and re-submit\n\n";
		}

		if(scalar @checkduplicates>0){
			print $fh "There were duplicate ID's or header names found in your manifest - correct and resubmit:\n";
			print $fh join( ',', @checkduplicates); print $fh "\n\n";
		}

		if($checkempty>0){
			print $fh "There were blank ID's or header names found in your manifest - correct and resubmit\n\n";
		}

		if (scalar @checknumlength>0){
			print $fh "Numeric metadata values must be less than 15 digits - correct and resubmit\n";
			print $fh join( ',', @checknumlength); print$fh "\n\n";
		}

		if(scalar @checkna>0){
			print $fh "Metadata can only contain empty cells or NA for missing data - NAN/nan are not accepted\n";
			print $fh join( ',', @checkna); print$fh "\n\n";
		}

	}
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
