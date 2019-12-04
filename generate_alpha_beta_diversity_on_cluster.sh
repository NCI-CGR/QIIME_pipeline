#!/bin/bash


. ./global_config_bash.rc


input_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
input_rooted_tree_qza=${phylogeny_qza_dir}/${output4_param}.qza

output_dir=$core_metrics_output_dir

Manifest_File=$MANIFEST_FILE_qiime2_format

sampling_depth=$sampling_depth

rm -rf ${output_dir}

#mkdir -p ${output_dir} 2>/dev/null

mkdir -p $log_dir_stage_7 2>/dev/null

cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_7}/stage7_qiime2.stdout \
	-e ${log_dir_stage_7}/stage7_qiime2.stderr \
	-N stage7_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/generate_alpha_beta_diversity.sh \
	$input_table_merged_final_qza\
	$input_rooted_tree_qza \
	$output_dir \
	$Manifest_File \
	$sampling_depth"
	
echo $cmd
eval $cmd
	
echo