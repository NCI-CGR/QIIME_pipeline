#!/bin/bash

. ./global_config_bash.rc



rm -rf ${FASTA_DIR}/*
rm -rf ${FASTA_DIR_TOTAL}/*
rm -rf ${MANIFEST_FILE_SPLIT_PARTS_FASTQ_IMPORT_DIR}/*

count=0

for manifest_file_split_part in $(ls -v ${MANIFEST_FILE_SPLIT_PARTS_DIR}/*txt); do	

		count=$(( count + 1 ))
		
		
		# Directories
		fasta_dir_split_part=${FASTA_DIR}/fasta_dir_split_part_${count}
		mkdir -p $fasta_dir_split_part 2>/dev/null
		
		manifest_file_split_parts_fastq_import=${MANIFEST_FILE_SPLIT_PARTS_FASTQ_IMPORT_DIR}/manifest_file_split_parts_fastq_import_${count}.txt
		
		
				
		echo "Analysis for Part $count"
		echo "Input Part Manifest file = $manifest_file_split_part"
		echo "Output Part Fasta Directory = $fasta_dir_split_part"
		echo "Output Part Fastq-Demuliplexed-Sample-Sheet = $manifest_file_split_parts_fastq_import"
		
		
		# Step 1: FastQ Folder Generation Starts
		echo
		echo "Step 1: Here we will process the manifest file and locate the sample level Fasta files from the flowcell directory, then make a soft link for those files in the project directory"

		


		for i in $(cat $manifest_file_split_part | awk -F "\t" -v spx=${SAMPLE_PREFIX} ' {print $1"#"$8"#"$10}'); do
			SN=$(echo $i|cut -f1 -d'#');
			FN=$(echo $i | cut -f2 -d'#');
			PN=$(echo $i | cut -f3 -d'#');
			#echo $PN;
			#echo "OK";
			FRP=$(find /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/${FN}/CASAVA/L1/Project_${PN}/Sample_${SN}/${SN}*R1_001.fastq.gz);
			RRP=$(find /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/${FN}/CASAVA/L1/Project_${PN}/Sample_${SN}/${SN}*R2_001.fastq.gz);
			#echo $FRP
			FRN=$(basename ${FRP});
			#echo $FRN
			CFR="ln -fs ${FRP} ${FRN}";
			RRN=$(basename ${RRP});
			CRR="ln -fs ${RRP} ${RRN}";
			cd $fasta_dir_split_part;
			#echo $CFR;
			eval $CFR;
			#echo $CRR;
			eval $CRR;
			#exit 1;
		done


		# Step 2: FastQ Files Collection Starts
		echo
		echo "Step 2: Here we will make a Copy of the FastQ files (links) inside Production Data Directory"
		cmd="cp -P ${fasta_dir_split_part}/*fastq.gz ${FASTA_DIR_TOTAL}"
		echo $cmd
		eval $cmd
	

		# Step 3: Fastq-Demuliplexed-Sample-Sheet Generation Starts
		echo
		echo "Step 3: Here we will process the Split Manifest File and generate the corresponding 'Fastq-Demuliplexed-Sample-Sheet' that will be utilized for generation of QIIME artifacts"

		echo "sample-id,absolute-filepath,direction" > ${manifest_file_split_parts_fastq_import}
		for i in $(cat $manifest_file_split_part| awk -F "\t" -v spx=${SAMPLE_PREFIX} ' {print $1"#"$8"#"$2"_"$7"#"$10}'); do
			SN=$(echo ${i}|cut -f1 -d'#');
			FN=$(echo $i | cut -f2 -d'#');
			ID=$(echo ${i}|cut -f3 -d'#' | sed s/-/_/g);
			PN=$(echo $i | cut -f4 -d'#');
			#echo $ID;
			#echo $PN;
			FRP=$(find /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/${FN}/CASAVA/L1/Project_${PN}/Sample_${SN}/${SN}*R1_001.fastq.gz);
			RRP=$(find /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/${FN}/CASAVA/L1/Project_${PN}/Sample_${SN}/${SN}*R2_001.fastq.gz);
			echo -e $ID","$FRP",forward";
			echo -e $ID","$RRP",reverse";
			#exit 1;
		done >> ${manifest_file_split_parts_fastq_import}
	
		#exit 1;
		
		echo "Part $count DONE"
		echo "****************"
		echo
done

















