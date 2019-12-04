#!/bin/bash

. ./global_config_bash.rc

part1=1


mkdir -p ${table_dada2_qza_merged_parts_final_dir} 2>/dev/null

mkdir -p ${repseqs_dada2_qza_merged_parts_final_dir} 2>/dev/null

mkdir -p $log_dir_stage_4 2>/dev/null

output_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
output_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza

cmd="cp ${table_dada2_qza_split_parts_dir}/${table_dada2_param}_${part1}.qza ${output_table_merged_final_qza}"
echo $cmd
eval $cmd

cmd="cp ${repseqs_dada2_qza_split_parts_dir}/${repseqs_dada2_param}_${part1}.qza ${output_repseqs_merged_final_qza}"
echo $cmd
eval $cmd

echo "All Done"