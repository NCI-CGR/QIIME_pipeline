#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.rc

input_table_merged_final_qza=$1
shift
input_rooted_tree_qza=$1
shift
output_dir=$1
shift
Manifest_File=$1
shift
sampling_depth=$1
shift

#perform Alpha and beta diversity analysis
date
echo "Here we perform Alpha and beta diversity analysis "
echo "INPUT1:Tree = ${input_rooted_tree_qza} "
echo "INPUT2:Table = ${input_table_merged_final_qza}"
echo "INPUT3:Manifest-File = ${Manifest_File}"
echo "Sampling-Depth = ${sampling_depth}"
echo "OUTPUT-DIR = ${output_dir}"
echo

cmd="qiime diversity core-metrics-phylogenetic \
	  --i-phylogeny ${input_rooted_tree_qza} \
	  --i-table ${input_table_merged_final_qza} \
	  --p-sampling-depth ${sampling_depth} \
	  --m-metadata-file ${Manifest_File} \
	  --output-dir ${output_dir}"
	  
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo

## Here we Export the Alpha-Diversity Artifacts as an integrated Visualization Table"

cmd="qiime metadata tabulate \
	--m-input-file ${output_dir}/observed_otus_vector.qza \
	--m-input-file ${output_dir}/shannon_vector.qza \
	--m-input-file ${output_dir}/evenness_vector.qza \
	--m-input-file ${output_dir}/faith_pd_vector.qza \
	--o-visualization ${output_dir}/alpha-table.qzv"

echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo
	
	