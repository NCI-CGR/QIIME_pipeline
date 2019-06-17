#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.rc

demux_qza_split_part=$1 
#demux_qza_split_part=${demux_qza_split_parts_dir}/paired_end_demux_1.qza
shift

demux_qzv_split_part=$1 
#demux_qzv_split_part=${demux_qzv_split_parts_dir}/paired_end_demux_1.qzv
shift

table_dada2_split_part=$1 
#table_dada2_split_part=${table_dada2_qza_split_parts_dir}/table_dada2_1.qza
shift

repseqs_dada2_split_part=$1 
#repseqs_dada2_split_part=${repseqs_dada2_qza_split_parts_dir}/repseqs_dada2_1.qza
shift

pe_manifest=$1
shift

# Importing Casava 1.8 paired-end demultiplexed fastq
date
echo "Here we import Casava 1.8 paired-end demultiplexed fastq "
echo "INPUT = $pe_manifest"
echo "OUTPUT = $demux_qza_split_part"
echo

cmd="qiime tools import \
  	--type 'SampleData[PairedEndSequencesWithQuality]' \
  	--input-path ${pe_manifest}\
  	--output-path ${demux_qza_split_part}\
  	--source-format PairedEndFastqManifestPhred${Phred_score}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo


# Generating a Visualization for the demultiplexing results
date
echo "Here we generate a Visualization for the demultiplexing results"
echo "INPUT = $demux_qza_split_part"
echo "OUTPUT = $demux_qzv_split_part"
echo

cmd="qiime demux summarize \
  	--i-data ${demux_qza_split_part} \
  	--o-visualization ${demux_qzv_split_part}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo


# Sequence quality control and feature table construction: DADA2
date
echo "Here we perform sequence quality control and feature table construction using DADA2 Plugin"
echo "INPUT = $demux_qza_split_part"
echo "OUTPUT 1= $table_dada2_split_part"
echo "OUTPUT 2= $repseqs_dada2_split_part"
echo

cmd="qiime dada2 denoise-paired \
  	--i-demultiplexed-seqs ${demux_qza_split_part} \
  	--o-table ${table_dada2_split_part} \
  	--o-representative-sequences ${repseqs_dada2_split_part} \
  	--p-trim-left-f 0 \
  	--p-trim-left-r 0 \
  	--p-trunc-len-f 0 \
	--p-trunc-len-r 0"
  	

echo $cmd
eval $cmd

echo
date
echo "Done"
echo
echo
