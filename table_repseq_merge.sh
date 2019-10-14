#!/bin/bash

#input
	#1) input directory for individual table or repseq files
		#Example: /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Testing/Project_NP0084-MB4/QIIME2_Test/QIIME2/qza_results/table
		#Example: /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Testing/Project_NP0084-MB4/QIIME2_Test/QIIME2/qza_results/repseq

	#2) output file name full path
		#Example: /path/to/output/directory/qza_results/table/final_dada2.qza
		#Example: /path/to/output/directory/qza_results/repseq/final_dada2.qza

#output
	#If there is more than one flow cell: a merged table file called final_{demux_param}.qza
	#If there is only one flow cell: the flowcell table.qza renamed to final_{demux_param}.qza

#usage

INPUT_DIR=$1
shift

OUTPUT_FILE=$1
shift

count=1

total_cells=$(ls -v $INPUT_DIR/* | wc -l)

for flowcells in $(ls -v $INPUT_DIR*); do
	#if this is the first loop, assign the first flow cell as flowcell_input1 - This
	#will become the new merged file for runs with more than one flowcell
	if [ $count == 1 ]; then

			flowcell_input1=$flowcells

			flowcell_output=$OUTPUT_FILE

	fi

	#If there more than one flowcell, cells need to be merged in a step-wise fashion
	#Example: flowcell1 + flowcell2= mergedcell_2 | mergedcell2 + flowcell3 = mergedcell3
	if  [ $total_cells != 1 ] && [ $count -gt 1 ]; then
			flowcell_input2=$flowcells

			flowcell_output=$INPUT_DIR"merged_"$count.qza

			#qiime command differs for repseq and feature table merging
			if [[ $flowcell_output =~ "repseq" ]]; then
				cmd="qiime feature-table merge-seq-data \
			  		--i-data1 $flowcell_input1 \
			  		--i-data2 $flowcell_input2 \
			  		--o-merged-data $flowcell_output"
			else
				cmd="qiime feature-table merge \
					--i-table1 $flowcell_input1 \
					--i-table2 $flowcell_input2 \
					--o-merged-table $flowcell_output"
			fi

			echo $cmd
			eval $cmd

			#New flowcell_input1 is the previous merged file to avoid duplicating sample ID's
			flowcell_input1=$flowcell_output
	fi

	#If there is only one flow cell or we've reached the last flowcell, then the cell
	#needs to be renamed to match multiple flowcell naming IE. final_paired_end_demux.qza
	if [ $total_cells == $count ]; then
		#Rename the only flowcell as the final file
		cmd="cp $flowcell_input1 $OUTPUT_FILE"

		echo $cmd
		eval $cmd

	fi

	((count++))

done
