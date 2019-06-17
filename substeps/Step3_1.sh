#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.sh

TOTAL_RUNS=$(ls -v $MANIFEST_FILE_SPLIT_PARTS_FASTQ_IMPORT_DIR/* | wc -l)
echo $TOTAL_RUNS

# Tables Merging	

count=1

while [ $count -le 1 ]

do
	echo $count
	
	part1=$count
	part2=$(( count + 1 ))
	
	input_table_qza_1=${table_dada2_qza_split_parts_dir}/${table_dada2_param}_${part1}.qza
	input_table_qza_2=${table_dada2_qza_split_parts_dir}/${table_dada2_param}_${part2}.qza
	output_table_temp_qza=${table_dada2_qza_merged_parts_tmp_dir}/${table_dada2_merged_temp_param}_${part2}.qza
	
	cmd="qiime feature-table merge \
  		--i-table1 $input_table_qza_1 \
  		--i-table2 $input_table_qza_2 \
  		--o-merged-table $output_table_temp_qza"
  		
  	echo $cmd
  	eval $cmd
  		
  		
	count=$(( count + 1 ))
	
done



while [ $count -gt 1 ] && [ $count -lt $TOTAL_RUNS ]

do
	echo $count
	
	part1=$count
	part2=$(( count + 1 ))
	
	input_table_qza_1=${table_dada2_qza_merged_parts_tmp_dir}/${table_dada2_merged_temp_param}_${part1}.qza
	input_table_qza_2=${table_dada2_qza_split_parts_dir}/${table_dada2_param}_${part2}.qza
	output_table_temp_qza=${table_dada2_qza_merged_parts_tmp_dir}/${table_dada2_merged_temp_param}_${part2}.qza
	
	cmd="qiime feature-table merge \
  		--i-table1 $input_table_qza_1 \
  		--i-table2 $input_table_qza_2 \
  		--o-merged-table $output_table_temp_qza"
  		
  	echo $cmd
  	eval $cmd
  		
  		
	count=$(( count + 1 ))
	
done

last_true_part=$count
echo $last_true_part
output_table_merged_temp_qza=${table_dada2_qza_merged_parts_tmp_dir}/${table_dada2_merged_temp_param}_${last_true_part}.qza
output_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
cmd="cp ${output_table_merged_temp_qza} ${output_table_merged_final_qza}"
echo $cmd
eval $cmd



###############

# Rep-Seqs Merging	
	
	
count=1

while [ $count -le 1 ]

do
	echo $count
	
	part1=$count
	part2=$(( count + 1 ))
	
	input_repseqs_qza_1=${repseqs_dada2_qza_split_parts_dir}/${repseqs_dada2_param}_${part1}.qza
	input_repseqs_qza_2=${repseqs_dada2_qza_split_parts_dir}/${repseqs_dada2_param}_${part2}.qza
	output_repseqs_temp_qza=${repseqs_dada2_qza_merged_parts_tmp_dir}/${repseqs_dada2_merged_temp_param}_${part2}.qza
	
	cmd="qiime feature-table merge-seq-data \
  		--i-data1 $input_repseqs_qza_1 \
  		--i-data2 $input_repseqs_qza_2 \
  		--o-merged-data $output_repseqs_temp_qza"
  		
  	echo $cmd
  	eval $cmd
  		
  		
	count=$(( count + 1 ))
	
done



while [ $count -gt 1 ] && [ $count -lt $TOTAL_RUNS ]

do
	echo $count
	
	part1=$count
	part2=$(( count + 1 ))
	
	input_repseqs_qza_1=${repseqs_dada2_qza_merged_parts_tmp_dir}/${repseqs_dada2_merged_temp_param}_${part1}.qza
	input_repseqs_qza_2=${repseqs_dada2_qza_split_parts_dir}/${repseqs_dada2_param}_${part2}.qza
	output_repseqs_temp_qza=${repseqs_dada2_qza_merged_parts_tmp_dir}/${repseqs_dada2_merged_temp_param}_${part2}.qza
	
	cmd="qiime feature-table merge-seq-data \
  		--i-data1 $input_repseqs_qza_1 \
  		--i-data2 $input_repseqs_qza_2 \
  		--o-merged-data $output_repseqs_temp_qza"
  		
  		
  	echo $cmd
  	eval $cmd
  		
  		
	count=$(( count + 1 ))
	
done

last_true_part=$count
echo $last_true_part
output_repseqs_merged_temp_qza=${repseqs_dada2_qza_merged_parts_tmp_dir}/${repseqs_dada2_merged_temp_param}_${last_true_part}.qza
output_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
cmd="cp ${output_repseqs_merged_temp_qza} ${output_repseqs_merged_final_qza}"
echo $cmd
eval $cmd
	
	