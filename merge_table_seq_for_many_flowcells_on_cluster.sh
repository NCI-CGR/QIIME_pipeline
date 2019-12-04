#!/bin/bash

. ./global_config_bash.rc


mkdir -p ${table_dada2_qza_merged_parts_tmp_dir} 2>/dev/null
mkdir -p ${table_dada2_qza_merged_parts_final_dir} 2>/dev/null

mkdir -p ${repseqs_dada2_qza_merged_parts_tmp_dir} 2>/dev/null
mkdir -p ${repseqs_dada2_qza_merged_parts_final_dir} 2>/dev/null

mkdir -p $log_dir_stage_4 2>/dev/null


	
cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_4}/stage4_qiime2.stdout \
	-e ${log_dir_stage_4}/stage4_qiime2.stderr \
	-N stage4_qiime2_${part} \
	-S /bin/sh \
	${SCRIPT_DIR}/merge_table_seq_for_many_flowcells.sh"


echo $cmd
eval $cmd

echo