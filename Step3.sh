#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.sh


output_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
output_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
TOTAL_RUNS=$(ls -v $MANIFEST_FILE_SPLIT_PARTS_FASTQ_IMPORT_DIR/* | wc -l)
echo $TOTAL_RUNS


#If there is more than one flowcell
if [ $TOTAL_RUNS -gt 1 ]; then
	cmd="qsub -cwd \
		-pe by_node 10 \
		-q ${QUEUE} \
		-o ${log_dir_stage_3}/stage3_qiime2.stdout \
		-e ${log_dir_stage_3}/stage3_qiime2.stderr \
		-N stage3_qiime2 \
		-S /bin/sh \
		${SCRIPT_DIR}/substeps/Step3_1.sh"
	echo $cmd
	eval $cmd
	echo

#If there is only one flow cell
else
	cmd="cp ${table_dada2_qza_split_parts_dir}/${table_dada2_param}_1.qza ${output_table_merged_final_qza}"
	echo $cmd
	eval $cmd

	cmd="cp ${repseqs_dada2_qza_split_parts_dir}/${repseqs_dada2_param}_1.qza ${output_repseqs_merged_final_qza}"
	echo $cmd
	eval $cmd
	echo "All Done"
fi
