#!/bin/bash


. ./global_config_bash.rc


mkdir -p $taxonomy_qza_dir 2>/dev/null
mkdir -p $taxonomy_qzv_dir 2>/dev/null
mkdir -p $log_dir_stage_9 2>/dev/null

input_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
input_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
Manifest_File=$MANIFEST_FILE_qiime2_format
reference_classifier_1=${refernce_1}
reference_classifier_2=${refernce_2}
taxonomy_qza_1=${taxonomy_qza_dir}/${taxonomy_1}.qza
taxonomy_qza_2=${taxonomy_qza_dir}/${taxonomy_2}.qza
taxonomy_qzv_1=${taxonomy_qzv_dir}/${taxonomy_1}.qzv
taxonomy_qzv_2=${taxonomy_qzv_dir}/${taxonomy_2}.qzv
taxa_bar_plots_qzv_1=${taxonomy_qzv_dir}/${taxonomy_1}_bar_plots.qzv
taxa_bar_plots_qzv_2=${taxonomy_qzv_dir}/${taxonomy_2}_bar_plots.qzv

cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_9}/stage9_qiime2.stdout \
	-e ${log_dir_stage_9}/stage9_qiime2.stderr \
	-N stage9_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/perform_taxonomic_analysis.sh \
	$input_table_merged_final_qza \
	$input_repseqs_merged_final_qza \
	$Manifest_File \
	$reference_classifier_1 \
	$reference_classifier_2	\
	$taxonomy_qza_1	\
	$taxonomy_qza_2	\
	$taxonomy_qzv_1	\
	$taxonomy_qzv_2	\
	$taxa_bar_plots_qzv_1 \
	$taxa_bar_plots_qzv_2"
	
echo $cmd
eval $cmd
	
echo