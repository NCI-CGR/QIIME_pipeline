#!/DCEG/Resources/Tools/perl/5.18.0/bin/perl -w
use strict;
use warnings;

#input
#output
#usage

@ARGV==3 or die "wrong number of arguments";

my $project_dir =$ARGV[0];
my $manifest_fullpath=$ARGV[1];
my $manifest_input=$ARGV[2];

my @lines;

read_manifest ($manifest_fullpath, \@lines);
#create_manifest(_);

sub read_manifest{
	my ($manifest_fullpath, $lines)=@_;

	open my $in, "<:encoding(UTF-8)", $manifest_fullpath or die "$manifest_fullpath: $!";
	@$lines = <$in>; close $in;
	chomp @$lines;
}

sub create_manifest{
	my ($project_dir, $manifest_fullpath, $manifest_input)=@_;

	my $MANIFEST_FILE_QIIME = $project_dir; $MANIFEST_FILE_QIIME .="//manifest_qiime2.tsv";
	open my $fh, ">$MANIFEST_FILE_QIIME";

	open my $in, "<:encoding(UTF-8)", $manifest_fullpath or die "$manifest_fullpath: $!";
	my @lines = <$in>; close $in;
	chomp @lines;

	foreach (@lines) {
		my @columns = split('\t',$_);

		my $n=0;
		until ($n+1 > scalar(@columns)){
			print $fh "$columns[$n]\t";
			$n++;
		}
		chomp $fh;
	}
}
exit;
