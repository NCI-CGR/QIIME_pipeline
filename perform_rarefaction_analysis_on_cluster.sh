#!/bin/bash


. ./global_config_bash.rc

mkdir -p ${rarefaction_qzv_dir} 2>/dev/null
mkdir -p ${log_dir_stage_8} 2>/dev/null

input_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
input_rooted_tree_qza=${phylogeny_qza_dir}/${output4_param}.qza

Manifest_File=$MANIFEST_FILE_qiime2_format

alpha_rarefaction_qzv=${rarefaction_qzv_dir}/${rarefaction_param}.qzv

max_depth=${max_depth}


cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_8}/stage8_qiime2.stdout \
	-e ${log_dir_stage_8}/stage8_qiime2.stderr \
	-N stage8_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/perform_rarefaction_analysis.sh \
	$input_table_merged_final_qza \
	$input_rooted_tree_qza \
	$Manifest_File \
	$alpha_rarefaction_qzv \
	$max_depth"
	
echo $cmd
eval $cmd
	
echo