#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.sh

#Directories
input_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
input_rooted_tree_qza=${phylogeny_qza_dir}/${output4_param}.qza
output_dir=$core_metrics_output_dir
Manifest_File=$MANIFEST_FILE_qiime2_format
sampling_depth=$sampling_depth
alpha_rarefaction_qzv=${rarefaction_qzv_dir}/${rarefaction_param}.qzv
max_depth=${max_depth}
input_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
reference_classifier_1=${refernce_1}
reference_classifier_2=${refernce_2}
taxonomy_qza_1=${taxonomy_qza_dir}/${taxonomy_1}.qza
taxonomy_qza_2=${taxonomy_qza_dir}/${taxonomy_2}.qza
taxonomy_qzv_1=${taxonomy_qzv_dir}/${taxonomy_1}.qzv
taxonomy_qzv_2=${taxonomy_qzv_dir}/${taxonomy_2}.qzv
taxa_bar_plots_qzv_1=${taxonomy_qzv_dir}/${taxonomy_1}_bar_plots.qzv
taxa_bar_plots_qzv_2=${taxonomy_qzv_dir}/${taxonomy_2}_bar_plots.qzv

#5.1 Code
cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_5}/stage5.1_qiime2.stdout \
	-e ${log_dir_stage_5}/stage5.1_qiime2.stderr \
	-N stage5.1_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/substeps/Step5_1.sh \
	$input_table_merged_final_qza\
	$input_rooted_tree_qza \
	$output_dir \
	$Manifest_File \
	$sampling_depth"
	
echo $cmd
eval $cmd
echo

#5.2 Code
cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_5}/stage5.2_qiime2.stdout \
	-e ${log_dir_stage_5}/stage5.2_qiime2.stderr \
	-N stage5.2_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/substeps/Step5_2.sh \
	$input_table_merged_final_qza \
	$input_rooted_tree_qza \
	$Manifest_File \
	$alpha_rarefaction_qzv \
	$max_depth"
	
echo $cmd
eval $cmd
echo

#5.3 Code
cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_5}/stage5.3_qiime2.stdout \
	-e ${log_dir_stage_5}/stage5.3_qiime2.stderr \
	-N stage5.3_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/substeps/Step5_3.sh \
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