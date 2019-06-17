#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.sh

input_table_merged_final_qza=$1
shift
output_table_merged_final_qzv=$1
shift

input_repseqs_merged_final_qza=$1
shift
output_repseqs_merged_final_qzv=$1
shift

Manifest_File=$1
shift

#Generate information on how many sequences are associated with each sample and with each feature, histograms of those distributions, and some related summary statistics
date
echo "Here we Generate information on how many sequences are associated with each sample and with each feature, histograms of those distributions, and some related summary statistics "
echo "INPUT1 = ${input_table_merged_final_qza}"
echo "INPUT2 = ${Manifest_File}"
echo "OUTPUT = ${output_table_merged_final_qzv}"
echo

cmd="qiime feature-table summarize \
  	--i-table ${input_table_merged_final_qza} \
  	--o-visualization ${output_table_merged_final_qzv} \
  	--m-sample-metadata-file ${Manifest_File}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo

  	
# Generate a mapping of feature IDs to sequences, and provide links to easily BLAST each sequence against the NCBI nt database
date
echo "Here we generate a mapping of feature IDs to sequences, and provide links to easily BLAST each sequence against the NCBI nt database "
echo "INPUT = ${input_repseqs_merged_final_qza}"
echo "OUTPUT = ${output_repseqs_merged_final_qzv}"
echo	
  	
cmd="qiime feature-table tabulate-seqs \
  	--i-data ${input_repseqs_merged_final_qza} \
  	--o-visualization ${output_repseqs_merged_final_qzv}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
	
	