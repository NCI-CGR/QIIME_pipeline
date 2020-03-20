#!/bin/bash

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     B. Ballew

set -euo pipefail

DATE=$(date +"%Y%m%d%H%M")
myExecPath="${PWD}/.."
myOutPath="${PWD}/out_${DATE}"
myTempPath="/scratch/microbiome/${DATE}"
myDBPath="/DCEG/CGF/Bioinformatics/Production/Bari/refDatabases"
myFqPath="/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/"  # for testing of internal CGR runs
# NOTE: edit cluster submission strings as needed depending on environment

MODES=("2017.11_internal" "2019.1_internal" "2017.11_external" "2019.1_external" "2019.1_internal_all_fail_low_reads" "2019.1_internal_one_passing_sample" "external_config_no_fq1" "config_no_Run-ID" "config_dup_IDs")

for i in "${MODES[@]}"
do

    outPath="${myOutPath}_${i}"
    tempPath="${myTempPath}_${i}"

    if [ ! -d "$outPath" ]; then
        mkdir -p "$outPath" || die "mkdir ${outPath} failed"
    else
        echo "${outPath} already exists!"
    fi

    # generate a test config:
    echo "out_dir: '${outPath}'" >> ${outPath}/TESTconfig.yml
    echo "exec_dir: '${myExecPath}'" >> ${outPath}/TESTconfig.yml
    echo "fastq_abs_path: '${myFqPath}'" >> ${outPath}/TESTconfig.yml
    echo "temp_dir: '${tempPath}'" >> ${outPath}/TESTconfig.yml
    echo "denoise_method: 'dada2'" >> ${outPath}/TESTconfig.yml
    echo "dada2_denoise:" >> ${outPath}/TESTconfig.yml
    echo "  trim_left_forward: 0" >> ${outPath}/TESTconfig.yml
    echo "  trim_left_reverse: 0" >> ${outPath}/TESTconfig.yml
    echo "  truncate_length_forward: 0" >> ${outPath}/TESTconfig.yml
    echo "  truncate_length_reverse: 0" >> ${outPath}/TESTconfig.yml
    echo "  min_fold_parent_over_abundance: 2.0" >> ${outPath}/TESTconfig.yml
    echo "phred_score: 33" >> ${outPath}/TESTconfig.yml
    echo "demux_param: 'paired_end_demux'" >> ${outPath}/TESTconfig.yml 
    echo "input_type: 'SampleData[PairedEndSequencesWithQuality]'" >> ${outPath}/TESTconfig.yml
    echo "min_num_features_per_sample: 1" >> ${outPath}/TESTconfig.yml 
    echo "min_num_reads_per_sample: 1" >> ${outPath}/TESTconfig.yml
    echo "min_num_reads_per_feature: 1" >> ${outPath}/TESTconfig.yml
    echo "min_num_samples_per_feature: 1" >> ${outPath}/TESTconfig.yml
    echo "sampling_depth: 10000" >> ${outPath}/TESTconfig.yml
    echo "max_depth: 54000" >> ${outPath}/TESTconfig.yml
    echo "classify_method: 'classify-sklearn'" >> ${outPath}/TESTconfig.yml
    echo "cluster_mode: 'qsub -q xlong.q -V -j y -S /bin/bash -o ${outPath}/logs/ -pe by_node {threads}'" >> ${outPath}/TESTconfig.yml
    echo "num_jobs: 100" >> ${outPath}/TESTconfig.yml
    echo "latency: 120" >> ${outPath}/TESTconfig.yml
    echo "metadata_manifest: '${myExecPath}/tests/input/test_12_samples.txt'" >> ${outPath}/TESTconfig.yml
    echo "data_source: 'internal'" >> ${outPath}/TESTconfig.yml
    echo "qiime2_version: '2017.11'" >> ${outPath}/TESTconfig.yml
    echo "reference_db:" >> ${outPath}/TESTconfig.yml
    echo "- '${myDBPath}/scikit_0.19.1_q2_2017.11/gg-13-8-99-nb-classifier.qza'" >> ${outPath}/TESTconfig.yml
    echo "- '${myDBPath}/scikit_0.19.1_q2_2017.11/silva-119-99-nb-classifier.qza'" >> ${outPath}/TESTconfig.yml

done

mode=2017.11_internal
# no changes

mode=2019.1_internal
sed -i "s/qiime2_version: '2017.11'/qiime2_version: '2019.1'/" ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/gg-13-8-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/gg-13-8-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/silva-119-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/silva-132-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml

mode=2017.11_external
sed -i 's/input\/test_12_samples.txt/input\/test_12_samples_external_data.txt/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i "s/data_source: 'internal'/data_source: 'external'/" ${myOutPath}_${mode}/TESTconfig.yml

mode=2019.1_external
sed -i 's/input\/test_12_samples.txt/input\/test_12_samples_external_data.txt/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i "s/data_source: 'internal'/data_source: 'external'/" ${myOutPath}_${mode}/TESTconfig.yml
sed -i "s/qiime2_version: '2017.11'/qiime2_version: '2019.1'/" ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/gg-13-8-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/gg-13-8-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/silva-119-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/silva-132-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml

mode=external_config_no_fq1
sed -i 's/input\/test_12_samples.txt/input\/test_12_samples_external_data_no_fq1.txt/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i "s/data_source: 'internal'/data_source: 'external'/" ${myOutPath}_${mode}/TESTconfig.yml

mode=config_no_Run-ID
sed -i 's/input\/test_12_samples.txt/input\/test_12_samples_no_Run-ID.txt/' ${myOutPath}_${mode}/TESTconfig.yml

mode=config_dup_IDs
sed -i 's/input\/test_12_samples.txt/input\/test_12_samples_dup_IDs.txt/' ${myOutPath}_${mode}/TESTconfig.yml

mode=2019.1_internal_all_fail_low_reads
sed -i 's/input\/test_12_samples.txt/input\/all_low_read_samples.txt/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i "s/qiime2_version: '2017.11'/qiime2_version: '2019.1'/" ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/gg-13-8-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/gg-13-8-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/silva-119-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/silva-132-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml

mode=2019.1_internal_one_passing_sample
sed -i 's/input\/test_12_samples.txt/input\/single_passing_sample.txt/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i "s/qiime2_version: '2017.11'/qiime2_version: '2019.1'/" ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/gg-13-8-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/gg-13-8-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml
sed -i 's/scikit_0.19.1_q2_2017.11\/silva-119-99-nb-classifier.qza/scikit_0.20.2_q2_2019.1\/silva-132-99-nb-classifier.qza/' ${myOutPath}_${mode}/TESTconfig.yml

module load sge perl/5.18.0 miniconda/3 python3/3.6.3
unset module

for i in "${MODES[@]}"
do
    outPath="${myOutPath}_${i}/"
    cmd="qsub -q xlong.q -V -j y -S /bin/sh -o ${outPath} ${myExecPath}/Q2_wrapper.sh ${outPath}/TESTconfig.yml"
    sleep 10
    echo "Command run: $cmd"
    eval "$cmd"
done
