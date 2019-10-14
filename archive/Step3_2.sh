#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.rc

# Filter samples

output_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
output_table_merged_final_filt_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_filt_param}.qza

date
echo "Here we filter samples with 0 reads"
echo "INPUT = ${table_dada2_merged_final_param}"
echo "OUTPUT = ${table_dada2_merged_final_filt_param}"
echo

cmd="qiime feature-table filter-samples \
  	--i-table $output_table_merged_final_qza \
  	--p-min-features ${filt_param} \
  	--o-filtered-table $output_table_merged_final_filt_qza"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo
