#!/bin/bash

#input
	#1) input directory for individual table files
	#2) output file full path
		#Example: /path/to/output/directory/table/final_dada2.qza

#output
	#If there is more than one flow cell: a merged table file called final_{demux_param}.qza
	#If there is only one flow cell: the flowcell table.qza renamed to final_{demux_param}.qza

#usage

INPUT_DIR=$1
shift

OUTPUT_DIR=$1
shift

count=1

total_cells=$(ls -v $INPUT_DIR/* | wc -l)

final_merged=$OUTPUT_DIR

for flowcells in $(ls -v $INPUT_DIR/*); do
	#If there more than one flowcell, cells need to be merged in a step-wise fashion
	#Example: flowcell1 + flowcell2= mergedcell_2 | mergedcell2 + flowcell3 = mergedcell3
	if  [ $total_cells != 1 ]; then

		#if this is the first loop, assign the first flow cell to avoid duplicating
		#sample ID's and failing the qiime command
		if [ $count == 1 ]; then
				flowcell_input1=$flowcells
				((count++))
		else
			flowcell_input2=$flowcells

			flowcell_output="merged_"$count.qza

			# cmd="qiime feature-table merge \
			# 	--i-table1 $flowcell_input1 \
			# 	--i-table2 $flowcell_input2 \
			# 	--o-merged-table $flowcell_output"

			((count++))

		fi

		#Rename the final iteration as the final file
		cmd="cp ${flowcell_output} ${OUTPUT_DIR}"

	else

		#Rename the only flowcell as the final file
		cmd="cp $flowcells $final_merged"

		eval $cmd

	fi

done
