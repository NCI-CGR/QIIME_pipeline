#!/bin/bash
# Importing Casava 1.8 paired-end demultiplexed fastq
split_man_dir=$1
shift

phred_score=$1
shift

input_type=$1
shift

module load miniconda/3
source activate qiime2-2017.11

for manifest_file_split_parts_fastq_import in $(ls -v $split_man_dir/*); do

	split_man_path=$manifest_file_split_parts_fastq_import
	echo $split_man_path
	runid=$manifest_file_split_parts_fastq_import
	runid=$(sed -e "s/\/DCEG.*manifest_//g" <<< $runid)
	runid=$(sed -e "s/.txt//g" <<< $runid)

	demux_qza_split_part=$manifest_file_split_parts_fastq_import/Output/qza_results/demux_qza_split_parts_$runid.qza
	demux_qza_split_part=$(sed -e "s/\Input.*txt\///g" <<< $demux_qza_split_part)

	cmd="qiime tools import \
  	--type ${input_type} \
  	--input-path ${split_man_path}\
  	--output-path ${demux_qza_split_part}\
  	--source-format PairedEndFastqManifestPhred${phred_score}"
	echo $cmd
	eval $cmd
done
