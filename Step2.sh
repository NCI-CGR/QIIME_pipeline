#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.rc

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
		-o ${log_dir_stage_2}/stage2_qiime2.stdout \
		-e ${log_dir_stage_2}/stage2_qiime2.stderr \
		-N stage2_qiime2_${part} \
		-S /bin/sh \
		${SCRIPT_DIR}/substeps/Step2_1.sh \
		$demux_qza_split_part \
		$demux_qzv_split_part \
		$table_dada2_split_part \
		$repseqs_dada2_split_part \
		$pe_manifest"
	
	echo $cmd
	eval $cmd
done
