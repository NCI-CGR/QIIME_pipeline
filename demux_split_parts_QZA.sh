#!/bin/bash
# Importing Casava 1.8 paired-end demultiplexed fastq

#input
##Requires 3 CML arguments -
	#1) full path to split manifest directory
		##Example: {proj_dir}/Output/qza_results/demux_qza_split_parts/
	#2) phred score for project (set in yaml file)
		##Example: 33
	#3) input type (set in yaml file)
		##Example: 'SampleData[PairedEndSequencesWithQuality]'
	#4) demux_param (st in yaml file)
		##Example: paired_end_demux


#output
	#1) QZA file(s) named demux_param}_{runid}.qza in path/to/projectdirectory/Output/qza/demux_qza_split_parts

#module load miniconda/3 #only needed if running stand-alone
#source activate qiime2-2017.11 #only needed if running stand-alone

split_man_dir=$1
shift

demux_param=$1
shift

input_type=$1
shift

phred_score=$1
shift

if [ "$#" -ne 4 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 /path/to/splitmanifests/ demux_param input_type phred_score" >&2
  exit 1
fi

#Searches for all split_manifest files created, where # of files = # of flowcells for project
for split_parts_manifests in $(ls -v $split_man_dir/*); do

	split_man_path=$split_parts_manifests

	#Parse only the runid from the full path - need this to name the output file
	runid=$split_parts_manifests
	runid=$(sed -e "s/\/DCEG.*manifest_//g" <<< $runid)
	runid=$(sed -e "s/.txt//g" <<< $runid)

	#Example name: {proj_dir}Output/qza_results/demux_qza_split_parts/paired_end_demux_180112_M01354_0104_000000000-BFN3F.qza
	demux_qza_split_part=$split_parts_manifests/Output/qza_results/demux_qza_split_parts/$demux_param_$runid.qza
	demux_qza_split_part=$(sed -e "s/\Input.*txt\///g" <<< $demux_qza_split_part)

	cmd="qiime tools import \
  	--type ${input_type} \
  	--input-path ${split_man_path}\
  	--output-path ${demux_qza_split_part}\
  	--source-format PairedEndFastqManifestPhred${phred_score}"
	echo $cmd
	eval $cmd
done
