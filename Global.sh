#!/bin/bash

#################################################
# QIIME version
qiime_version=2017.11

# Initiate QIIME
module load miniconda/3
source activate qiime2-${qiime_version}

# Parameters
QUEUE=seq-gvcf.q
SAMPLE_PREFIX=SC
Phred_score=33

#################################################
# TO UPDATE
PROJECT_DIR=/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Testing/Project_NP0440_MB4_SSC
MANIFEST_FILE=${PROJECT_DIR}/NP0440_MB4.txt

#################################################
# Input Directories/Files
SCRIPT_DIR=/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V2
TEMP_DIR=${PROJECT_DIR}/Input/tmp
RESOURCES_DIR=${SCRIPT_DIR}/resources
FASTA_DIR=${PROJECT_DIR}/Input/Fasta
MANIFEST_FILE_SPLIT_PARTS_DIR=${PROJECT_DIR}/Input/manifest_file_split_parts
MANIFEST_FILE_SPLIT_PARTS_FASTQ_IMPORT_DIR=${PROJECT_DIR}/Input/manifest_file_split_parts_fastq_import
MANIFEST_FILE_qiime2_format=${PROJECT_DIR}/Input/manifest_qiime2.tsv

# Output Directories
QZA_RESULTS_DIR=${PROJECT_DIR}/Output/qza_results
QZV_RESULTS_DIR=${PROJECT_DIR}/Output/qzv_results
LOG_DIR=${PROJECT_DIR}/Output/Log

#################################################
## Stage 2
demux_qza_split_parts_dir=${QZA_RESULTS_DIR}/demux_qza_split_parts
demux_qzv_split_parts_dir=${QZV_RESULTS_DIR}/demux_qzv_split_parts
table_dada2_qza_split_parts_dir=${QZA_RESULTS_DIR}/table_dada2_qza_split_parts
repseqs_dada2_qza_split_parts_dir=${QZA_RESULTS_DIR}/repseqs_dada2_qza_split_parts
log_dir_stage_2=${LOG_DIR}/stage2_qiime2

# Stage 2 Parameters
demux_param=paired_end_demux
table_dada2_param=table_dada2
repseqs_dada2_param=repseqs_dada2

#################################################
# Stage 3 Directories
table_dada2_qza_merged_parts_tmp_dir=${QZA_RESULTS_DIR}/table_dada2_qza_merged_parts_tmp
table_dada2_qza_merged_parts_final_dir=${QZA_RESULTS_DIR}/table_dada2_qza_merged_parts_final
repseqs_dada2_qza_merged_parts_tmp_dir=${QZA_RESULTS_DIR}/repseqs_dada2_qza_merged_parts_tmp
repseqs_dada2_qza_merged_parts_final_dir=${QZA_RESULTS_DIR}/repseqs_dada2_qza_merged_parts_final
log_dir_stage_3=${LOG_DIR}/stage3_qiime2

# Stage 3 Parameters
table_dada2_merged_temp_param=table_dada2_merged_temp
table_dada2_merged_final_param=table_dada2_merged_final
repseqs_dada2_merged_temp_param=repseqs_dada2_merged_temp
repseqs_dada2_merged_final_param=repseqs_dada2_merged_final

################################################
# Stage 4 Directories
table_dada2_qzv_merged_parts_final_dir=${QZV_RESULTS_DIR}/table_dada2_qzv_merged_parts_final
repseqs_dada2_qzv_merged_parts_final_dir=${QZV_RESULTS_DIR}/repseqs_dada2_qzv_merged_parts_final
log_dir_stage_4=${LOG_DIR}/stage4_qiime2
phylogeny_qza_dir=${QZA_RESULTS_DIR}/phylogeny_qza_results

# Stage 4 Parameters
table_dada2_merged_final_param=table_dada2_merged_final
repseqs_dada2_merged_final_param=repseqs_dada2_merged_final
output1_param=aligned_rep_seqs
output2_param=masked_aligned_rep_seqs
output3_param=unrooted_tree
output4_param=rooted_tree

###############################################
# Stage 5 Directories
core_metrics_output_dir=${QZA_RESULTS_DIR}/core_metrics_results
log_dir_stage_5=${LOG_DIR}/stage5_qiime2
rarefaction_qzv_dir=${QZV_RESULTS_DIR}/rarefaction_qzv_results
taxonomy_qza_dir=${QZA_RESULTS_DIR}/taxonomy_qza_results
taxonomy_qzv_dir=${QZV_RESULTS_DIR}/taxonomy_qzv_results

# Stage 5 Parameters
sampling_depth=10000
rarefaction_param=rarefaction
max_depth=62000
refernce_1=${RESOURCES_DIR}/gg-13-8-99-nb-classifier.qza
refernce_2=${RESOURCES_DIR}/silva-119-99-nb-classifier.qza
taxonomy_1=taxonomy_greengenes
taxonomy_2=taxonomy_silva

###############################################
#REPORT_DIR=${PROJECT_DIR}/Input/Reports
#SAMPLE_PREFIX=SC
#Mapping_File_Mock_Samples=${PROJECT_DIR}/mock_samples_list.txt
#Mapping_File_Non_Samples=${PROJECT_DIR}/non_samples_list.txt
#REPORT_FILE1=${REPORT_DIR}/Fastq_Seq_Count.txt
#REPORT_FILE2=${REPORT_DIR}/Fastq_with_zero.txt
#PRE_DATA_PREP_FLAG_RUNNING=${PROJECT_DIR}/Pre_Data_Prep_Analysis.running
#PRE_DATA_PREP_FLAG_DONE=${PROJECT_DIR}/Pre_Data_Prep_Analysis.done
#REPORT_FILE_FLAG_RUNNING=${PROJECT_DIR}/Report_File_Analysis.running
#REPORT_FILE_FLAG_DONE=${PROJECT_DIR}/Report_File_Analysis.done
