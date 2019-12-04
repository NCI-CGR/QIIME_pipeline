#!/bin/bash

. ./global_config_bash.rc


echo " Here we will process the Original Manifest File and generate the corresponding 'QIIME-compatible' version"

echo -e "#SampleID\tSampleType\tSourceMaterial" > ${MANIFEST_FILE_qiime2_format}
for i in $(cat $MANIFEST_FILE| awk -F "\t" -v spx=${SAMPLE_PREFIX} ' {print $1"#"$8"#"$2"_"$7"#"$10"#"$3"#"$4}'); do
SN=$(echo ${i}|cut -f1 -d'#');
FN=$(echo $i | cut -f2 -d'#');
ID=$(echo ${i}|cut -f3 -d'#' | sed s/-/_/g);
PN=$(echo $i | cut -f4 -d'#');
ST=$(echo $i | cut -f5 -d'#');
SM=$(echo $i | cut -f6 -d'#');
#echo $ID;
#echo $PN;
echo -e $ID"\t"$ST"\t"$SM;
done >> ${MANIFEST_FILE_qiime2_format}


echo "DONE"
echo "****************"
echo

