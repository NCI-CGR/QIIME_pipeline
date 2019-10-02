#!/bin/bash

#input
	#1) input directory for individual table files
	#2) output file full path

count=1

for flowcells in $(ls -v $table_split_parts_dir/*); do
	while [ $count -le 2 ]

	do
		echo $count
		flowcell_merged_1 = flowcells

		count=$(( count + 1 ))

	while [ $count -gt 1 ]

	do
		echo $count
		flowcell_merged_2=$flowcells

		cmd="qiime feature-table merge \
				--i-table1 $flowcell_merged_1 \
				--i-table2 $flowcell_merged_2 \
				--o-merged-table $output_table_temp_qza" #fix

			echo $cmd
			eval $cmd


		flowcell_merged_1=output_table #fix

		count=$(( count + 1 ))

Rename flowcells
	while [ $count -le 2 ]

	do
		echo $count
		flowcell_merged_1=table_dada2_merged_final
		cmd="cp ${output_table_merged_temp_qza} ${output_table_merged_final_qza}"
		echo $cmd
		eval $cmd

	while [ $count -gt 1 ]

	do
		table_count = table_dada2_merged_final
		cmd="cp ${output_table_merged_temp_qza} ${output_table_merged_final_qza}"
		echo $cmd
		eval $cmd
