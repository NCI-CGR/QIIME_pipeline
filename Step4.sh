#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.rc

#Directories
input_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
output_table_merged_final_qzv=${table_dada2_qzv_merged_parts_final_dir}/${table_dada2_merged_final_param}.qzv
input_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
output_repseqs_merged_final_qzv=${repseqs_dada2_qzv_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qzv
Manifest_File=$MANIFEST_FILE_qiime2_format
output1_qza=${phylogeny_qza_dir}/${output1_param}.qza
output2_qza=${phylogeny_qza_dir}/${output2_param}.qza
output3_qza=${phylogeny_qza_dir}/${output3_param}.qza
output4_qza=${phylogeny_qza_dir}/${output4_param}.qza

#4.1 Code
cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_4}/stage4.1_qiime2.stdout \
	-e ${log_dir_stage_4}/stage4.1_qiime2.stderr \
	-N stage4.1_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/substeps/Step4_1.sh \
	$input_table_merged_final_qza \
	$output_table_merged_final_qzv \
	$input_repseqs_merged_final_qza \
	$output_repseqs_merged_final_qzv \
	$Manifest_File"
	
echo $cmd
eval $cmd
echo

#4.2 Code
cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_4}/stage4.2_qiime2.stdout \
	-e ${log_dir_stage_4}/stage4.2_qiime2.stderr \
	-N stage4.2_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/substeps/Step4_2.sh \
	$input_repseqs_merged_final_qza \
	$output1_qza \
	$output2_qza \
	$output3_qza \
	$output4_qza"
	
echo $cmd
eval $cmd
echo