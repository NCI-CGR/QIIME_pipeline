#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.sh

input_table_merged_final_qza=$1
shift
input_repseqs_merged_final_qza=$1
shift
Manifest_File=$1
shift
reference_classifier_1=$1
shift
reference_classifier_2=$1
shift
taxonomy_qza_1=$1
shift
taxonomy_qza_2=$1
shift
taxonomy_qzv_1=$1
shift
taxonomy_qzv_2=$1
shift
taxa_bar_plots_qzv_1=$1
shift
taxa_bar_plots_qzv_2=$1
shift


# Taxonomic Classification for GreenGenes Refernce
cmd="qiime feature-classifier classify-sklearn \
  	--i-classifier ${reference_classifier_1} \
  	--i-reads ${input_repseqs_merged_final_qza} \
  	--o-classification ${taxonomy_qza_1}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo

cmd="qiime metadata tabulate \
  	--m-input-file ${taxonomy_qza_1}\
  	--o-visualization ${taxonomy_qzv_1}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo 	
  	
cmd="qiime taxa barplot \
  	--i-table ${input_table_merged_final_qza} \
  	--i-taxonomy ${taxonomy_qza_1} \
  	--m-metadata-file ${Manifest_File} \
  	--o-visualization ${taxa_bar_plots_qzv_1}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo



# Taxonomic Classification for Silva Refernce
cmd="qiime feature-classifier classify-sklearn \
  	--i-classifier ${reference_classifier_2} \
  	--i-reads ${input_repseqs_merged_final_qza} \
  	--o-classification ${taxonomy_qza_2}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo

cmd="qiime metadata tabulate \
  	--m-input-file ${taxonomy_qza_2}\
  	--o-visualization ${taxonomy_qzv_2}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo 	
  	
cmd="qiime taxa barplot \
  	--i-table ${input_table_merged_final_qza} \
  	--i-taxonomy ${taxonomy_qza_2} \
  	--m-metadata-file ${Manifest_File} \
  	--o-visualization ${taxa_bar_plots_qzv_2}"
  	
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo