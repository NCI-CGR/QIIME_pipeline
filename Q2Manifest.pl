#!/DCEG/Resources/Tools/perl/5.18.0/bin/perl -w
use strict;
use warnings;

@ARGV==2 or die "wrong number of arguments";

#Create QIIME2 manifest
my $project_dir =$ARGV[0];
my $manifest_ori=$ARGV[1];

manifest_qiime2 ($project_dir,$manifest_ori);

sub manifest_qiime2{
	#Initialize variables / Read in variables
	my ($project_dir, $manifest_ori)=@_;

	#Set pathway for original manifest
	my $manifest_path=$project_dir; $manifest_path.="//";
	$manifest_path.= $manifest_ori;

	#Set pathway and name for qiime2 file
	my $MANIFEST_FILE_QIIME = $project_dir; $MANIFEST_FILE_QIIME .="//manifest_qiime2.tsv";
	open my $fh, ">$MANIFEST_FILE_QIIME";

	#Open, read original manifest file
	open my $in, "<:encoding(UTF-8)", $manifest_path or die "$manifest_path: $!";
	my @lines = <$in>; close $in;
	chomp @lines;

	#Run through each line and save relevant information
	foreach (@lines) {
		my @columns = split('\t',$_);

		#Print other data to QIIME2 File
		my $n=0;
		until ($n+1 > scalar(@columns)){
			print $fh "$columns[$n]\t";
			$n++;
		}
		chomp $fh;
	}
}
exit;
