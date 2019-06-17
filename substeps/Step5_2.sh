#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.sh

input_table_merged_final_qza=$1
shift
input_rooted_tree_qza=$1
shift
Manifest_File=$1
shift
alpha_rarefaction_qzv=$1
shift
max_depth=$1
shift

cmd="qiime diversity alpha-rarefaction \
  	--i-table ${input_table_merged_final_qza} \
  	--i-phylogeny ${input_rooted_tree_qza} \
  	--p-max-depth ${max_depth} \
  	--m-metadata-file ${Manifest_File} \
  	--o-visualization ${alpha_rarefaction_qzv}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo