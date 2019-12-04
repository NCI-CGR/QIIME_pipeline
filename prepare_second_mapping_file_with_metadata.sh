#!/bin/bash

. ./global_config_bash.rc


echo " Here we will process the Original Manifest File and generate the corresponding 'QIIME-compatible' version"

echo -e "#SampleID\tSampleType\tSourceMaterial\tCGRID\tSeq_Plate\tType\tResidual\tInstrument\tExtKit\tBatch\tSubjectID\tVialID" > ${MANIFEST_FILE_qiime2_format}
for i in $(cat $MANIFEST_FILE| awk -F "\t" -v spx=${SAMPLE_PREFIX} ' {print $1"#"$8"#"$2"_"$7"#"$10"#"$3"#"$4"#"$11"#"$12"#"$13"#"$14"#"$15"#"$16"#"$17"#"$18"#"$19}'); do
SN=$(echo ${i}|cut -f1 -d'#');
FN=$(echo $i | cut -f2 -d'#');
ID=$(echo ${i}|cut -f3 -d'#' | sed s/-/_/g);
PN=$(echo $i | cut -f4 -d'#');
ST=$(echo $i | cut -f5 -d'#');
SM=$(echo $i | cut -f6 -d'#');
Q1=$(echo $i | cut -f7 -d'#');
Q2=$(echo $i | cut -f8 -d'#');
Q3=$(echo $i | cut -f9 -d'#');
Q4=$(echo $i | cut -f10 -d'#');
Q5=$(echo $i | cut -f11 -d'#');
Q6=$(echo $i | cut -f12 -d'#');
Q7=$(echo $i | cut -f13 -d'#');
Q8=$(echo $i | cut -f14 -d'#');
Q9=$(echo $i | cut -f15 -d'#');
#echo $ID;
#echo $PN;
echo -e $ID"\t"$ST"\t"$SM"\t"$Q1"\t"$Q2"\t"$Q3"\t"$Q4"\t"$Q5"\t"$Q6"\t"$Q7"\t"$Q8"\t"$Q9;
done >> ${MANIFEST_FILE_qiime2_format}


echo "DONE"
echo "****************"
echo

