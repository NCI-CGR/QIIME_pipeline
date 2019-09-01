#!/DCEG/Resources/Tools/perl/5.18.0/bin/perl -w
use strict;
use warnings;

#input
#output
#usage

@ARGV==4 or die "wrong number of arguments";

my $project_dir =$ARGV[0];
my $manifest_fullpath=$ARGV[1];
my $manifest_input=$ARGV[2];
my $manifest_output=$ARGV[3];

my @lines;

read_manifest ($manifest_fullpath, \@lines);
create_manifest($project_dir,$manifest_output,\@lines);

sub read_manifest{
	my ($manifest_fullpath, $lines)=@_;

	open my $in, "<:encoding(UTF-8)", $manifest_fullpath or die "$manifest_fullpath: $!";
	@$lines = <$in>; close $in;
	chomp @$lines;
}

sub create_manifest{
	my ($project_dir, $manifest_output, $lines)=@_;

	open my $fh, ">$manifest_output";

	foreach (@lines) {
		my @columns = split('\t',$_);

		my $n=0;
		until ($n+1 > scalar(@columns)){
			print $fh "$columns[$n]\t";
			$n++;
		}
		print $fh "\n";
	}
}
exit;
