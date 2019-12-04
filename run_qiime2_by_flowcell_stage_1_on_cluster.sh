#!/bin/bash

. ./global_config_bash.rc


mkdir -p $demux_qza_split_parts_dir 2>/dev/null
mkdir -p $demux_qzv_split_parts_dir 2>/dev/null
mkdir -p $table_dada2_qza_split_parts_dir 2>/dev/null
mkdir -p $repseqs_dada2_qza_split_parts_dir 2>/dev/null
mkdir -p $log_dir_stage_3 2>/dev/null


for manifest_file_split_parts_fastq_import in $(ls -v $MANIFEST_FILE_SPLIT_PARTS_FASTQ_IMPORT_DIR/*); do
	
	#echo $manifest_file_split_parts_fastq_import
	pe_manifest=$manifest_file_split_parts_fastq_import
	echo $pe_manifest
	
	part=$(basename $manifest_file_split_parts_fastq_import | cut -f1 -d'.' | rev | cut -f1 -d'_' |rev)
	echo "Part $part"
	
	demux_qza_split_part=${demux_qza_split_parts_dir}/${demux_param}_${part}.qza
	
	demux_qzv_split_part=${demux_qzv_split_parts_dir}/${demux_param}_${part}.qzv
	
	table_dada2_split_part=${table_dada2_qza_split_parts_dir}/${table_dada2_param}_${part}.qza
	
	repseqs_dada2_split_part=${repseqs_dada2_qza_split_parts_dir}/${repseqs_dada2_param}_${part}.qza
	
	cmd="qsub -cwd \
		-pe by_node 10 \
		-q ${QUEUE} \
		-o ${log_dir_stage_3}/stage3_qiime2_${part}.stdout \
		-e ${log_dir_stage_3}/stage3_qiime2_${part}.stderr \
		-N stage3_qiime2_${part} \
		-S /bin/sh \
		${SCRIPT_DIR}/run_qiime2_by_flowcell_stage_1.sh \
		$demux_qza_split_part \
		$demux_qzv_split_part \
		$table_dada2_split_part \
		$repseqs_dada2_split_part \
		$pe_manifest"
	
	echo $cmd
	eval $cmd
	
	echo
	#exit 1;
	
	
done