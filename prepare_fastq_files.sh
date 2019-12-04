#!/bin/bash

. ./global_config_bash.rc

	echo
	echo "Here we will process the Manifest File and will generate a Second Mapping File that will be used for the Mock Samples"

	echo "Mapping File=${Mapping_File_Mock_Samples}"
	for i in $(cat $MANIFEST_FILE | awk -F "\t" -v spx=${SAMPLE_PREFIX} ' {print $1"#"$8"#"$2"_"$7"#"$10"#"$3}'); do
		SN=$(echo ${i}|cut -f1 -d'#');
		FN=$(echo $i | cut -f2 -d'#');
		ID=$(echo ${i}|cut -f3 -d'#' | sed s/-/_/g);
		PN=$(echo $i | cut -f4 -d'#');
		ST=$(echo $i | cut -f5 -d'#');
		#echo $ID;
		#echo $PN;
		#FRP=$(find /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/${FN}/CASAVA/L1/Project_${PN}/Sample_${SN}/${SN}*R1_001.fastq.gz);
		#RRP=$(find /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/${FN}/CASAVA/L1/Project_${PN}/Sample_${SN}/${SN}*R2_001.fastq.gz);
		#FRN=$(basename ${FRP});
		#RRN=$(basename ${RRP});]
		#echo $ST;
		if [[ "$ST" == "artificial" ]]; then
		echo -e $ID"\t"$ST"\t"$SN;
		#exit 1;
		fi
	done > ${Mapping_File_Mock_Samples}