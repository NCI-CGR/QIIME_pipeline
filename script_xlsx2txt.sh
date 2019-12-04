#!/bin/bash

. ./global_config_bash.rc


echo "INPUT=$MANIFEST_FILE_XLSX"
echo "Output1=$MANIFEST_FILE_TXT_WITH_HEADER"
echo "Output2=$MANIFEST_FILE"
echo "Output3=$MANIFEST_FILE_qiime2_format"

module load python3

input_file=$1
cmd="python3 ./common_xlsx2txt.pl $MANIFEST_FILE_XLSX $MANIFEST_FILE_TXT_WITH_HEADER"
echo $cmd
#eval $cmd

tail -n +2 $MANIFEST_FILE_TXT_WITH_HEADER > ${MANIFEST_FILE}

#Here we convert the TXT-Manifest into QIIME-version of Manifest
cmd="sh ${SCRIPT_DIR}/prepare_second_mapping_file.sh"
echo $cmd
eval $cmd