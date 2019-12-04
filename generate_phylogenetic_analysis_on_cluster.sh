#!/bin/bash

. ./global_config_bash.rc


mkdir -p ${phylogeny_qza_dir} 2>/dev/null

mkdir -p $log_dir_stage_6 2>/dev/null

input_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
output1_qza=${phylogeny_qza_dir}/${output1_param}.qza
output2_qza=${phylogeny_qza_dir}/${output2_param}.qza
output3_qza=${phylogeny_qza_dir}/${output3_param}.qza
output4_qza=${phylogeny_qza_dir}/${output4_param}.qza



cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_6}/stage6_qiime2.stdout \
	-e ${log_dir_stage_6}/stage6_qiime2.stderr \
	-N stage6_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/generate_phylogenetic_analysis.sh \
	$input_repseqs_merged_final_qza \
	$output1_qza \
	$output2_qza \
	$output3_qza \
	$output4_qza"
	
echo $cmd
eval $cmd
	
echo