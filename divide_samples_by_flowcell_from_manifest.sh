#!/bin/bash

echo
echo "Author: Shalabh Suman"

. ./global_config_bash.rc

	echo
	echo "Here we will process the Manifest File to divide the samples by flowcell"
	echo "Based on the template of Manifest file that was decided, we are assuming RUN ID field is Column 8"
	echo
	echo "Original Mapping File=${MANIFEST_FILE}"
	
	count_for_flowcells=$(cat $MANIFEST_FILE | awk -F "\t" '{print $8}' | sort | uniq | wc -l)
	echo "Total number of Unique Flowcells = $count_for_flowcells"
	echo
	
	names_for_flowcells=$TEMP_DIR/$(basename $MANIFEST_FILE .txt)_names_for_flowcells.txt
	cat $MANIFEST_FILE | awk -F "\t" '{print $8}' | sort | uniq > $names_for_flowcells
	echo "File with List of Unique Flowcells = $names_for_flowcells"
	echo
	#echo $names_for_flowcells
	echo "List of Unique Flowcells:"
	cat $names_for_flowcells;
	echo
	echo
	
	
	count=0;
	for i in $(cat $names_for_flowcells | awk -F "\t" '{print $1}'); do
	
		count=$(( count + 1 ))
		
		run_id=$i;
		#echo $run_id;
		
		echo "Part $count RUN ID = $run_id"
		
		manifest_file_split_part=$MANIFEST_FILE_SPLIT_PARTS_DIR/$(basename $MANIFEST_FILE .txt)_split_part_${count}.txt
		
		echo "Part $count Manifest File = $manifest_file_split_part"
		
		cat $MANIFEST_FILE | awk -F "\t" -OF "\t" -v spx=$run_id '{if ($8 == spx) {print $0}}' > $manifest_file_split_part
		
		echo
		
		#exit 1;
		
	done
	
	echo "All done"