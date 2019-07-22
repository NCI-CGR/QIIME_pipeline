#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2/Global.rc

input_repseqs_merged_final_qza=$1
shift
output1_qza=$1
shift
output2_qza=$1
shift
output3_qza=$1
shift
output4_qza=$1
shift

#Step 1: First, we perform a multiple sequence alignment of the sequences
date
echo "Here we perform a multiple sequence alignment of the sequences"
echo "INPUT = ${input_repseqs_merged_final_qza}"
echo "OUTPUT = ${output1_qza}"
echo
cmd="qiime alignment mafft \
  	--i-sequences ${input_repseqs_merged_final_qza} \
  	--o-alignment ${output1_qza}"
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo  
  
#Step 2: Here, we mask (or filter) the alignment to remove positions that are highly variable
date
echo "Here we mask (or filter) the alignment to remove positions that are highly variable"
echo "INPUT = ${output1_qza}"
echo "OUTPUT = ${output2_qza}"
echo
cmd="qiime alignment mask \
  --i-alignment ${output1_qza} \
  --o-masked-alignment ${output2_qza}"
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo

#Step 3: Here, we’ll apply FastTree to generate a phylogenetic tree from the masked alignment
date
echo "Here we’ll apply FastTree to generate a phylogenetic tree from the masked alignment"
echo "INPUT = ${output2_qza}"
echo "OUTPUT = ${output3_qza}"
echo
cmd="qiime phylogeny fasttree \
  --i-alignment ${output2_qza} \
  --o-tree ${output3_qza}"
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo
  
#Step 4: Here, we apply midpoint rooting to place the root of the tree at the midpoint of the longest tip-to-tip distance in the unrooted tree
date
echo "Here  we apply midpoint rooting to place the root of the tree at the midpoint of the longest tip-to-tip distance in the unrooted tree"
echo "INPUT = ${output3_qza}"
echo "OUTPUT = ${output4_qza}"
echo
cmd="qiime phylogeny midpoint-root \
  --i-tree ${output3_qza} \
  --o-rooted-tree ${output4_qza}"
  
echo $cmd
eval $cmd
echo
date
echo "Done"
echo
echo
	
	