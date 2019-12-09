#!/bin/bash

set -euo pipefail

DATE=$(date +"%Y%m%d%H%M")
myExecPath="/DCEG/CGF/Bioinformatics/Production/Microbiome/QIIME_pipeline"
myOutPath="${myExecPath}/tests/out_${DATE}"
myTempPath="/scratch/microbiome/${DATE}"

MODES=("2017.11" "2019.1")

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
    echo "metadata_manifest: '${myExecPath}/tests/input/smaller_manifest.txt'" > ${outPath}/TESTconfig.yml
    echo "out_dir: '${outPath}'" >> ${outPath}/TESTconfig.yml
    echo "exec_dir: '${myExecPath}'" >> ${outPath}/TESTconfig.yml
    echo "fastq_abs_path: '/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/'" >> ${outPath}/TESTconfig.yml
    echo "temp_dir: '${tempPath}'" >> ${outPath}/TESTconfig.yml
    echo "denoise_method: 'dada2'" >> ${outPath}/TESTconfig.yml
    echo "dada2_denoise:" >> ${outPath}/TESTconfig.yml
    echo "  trim_left_forward: 0" >> ${outPath}/TESTconfig.yml
    echo "  trim_left_reverse: 0" >> ${outPath}/TESTconfig.yml
    echo "  truncate_length_forward: 0" >> ${outPath}/TESTconfig.yml
    echo "  truncate_length_reverse: 0" >> ${outPath}/TESTconfig.yml
    echo "phred_score: 33" >> ${outPath}/TESTconfig.yml
    echo "demux_param: 'paired_end_demux'" >> ${outPath}/TESTconfig.yml 
    echo "input_type: 'SampleData[PairedEndSequencesWithQuality]'" >> ${outPath}/TESTconfig.yml
    echo "filt_param: 1" >> ${outPath}/TESTconfig.yml
    echo "sampling_depth: 10000" >> ${outPath}/TESTconfig.yml
    echo "max_depth: 54000" >> ${outPath}/TESTconfig.yml
    echo "classify_method: 'classify-sklearn'" >> ${outPath}/TESTconfig.yml
    echo "cluster_mode: 'qsub -q xlong.q -V -j y -S /bin/bash -o ${outPath}/logs/ -pe by_node {threads}'" >> ${outPath}/TESTconfig.yml
    echo "num_jobs: 100" >> ${outPath}/TESTconfig.yml
    echo "latency: 120" >> ${outPath}/TESTconfig.yml

done

# 2017.11
echo "qiime2_version: '2017.11'" >> ${myOutPath}_2017.11/TESTconfig.yml
echo "reference_db:" >> ${myOutPath}_2017.11/TESTconfig.yml
echo "- '/DCEG/CGF/Bioinformatics/Production/Bari/refDatabases/scikit_0.19.1_q2_2017.11/gg-13-8-99-nb-classifier.qza'" >> ${myOutPath}_2017.11/TESTconfig.yml
echo "- '/DCEG/CGF/Bioinformatics/Production/Bari/refDatabases/scikit_0.19.1_q2_2017.11/silva-119-99-nb-classifier.qza'" >> ${myOutPath}_2017.11/TESTconfig.yml

# 2019.1
echo "qiime2_version: '2019.1'" >> ${myOutPath}_2019.1/TESTconfig.yml
echo "reference_db:" >> ${myOutPath}_2019.1/TESTconfig.yml
echo "- '/DCEG/CGF/Bioinformatics/Production/Bari/refDatabases/scikit_0.20.2_q2_2019.1/gg-13-8-99-nb-classifier.qza'" >> ${myOutPath}_2019.1/TESTconfig.yml
echo "- '/DCEG/CGF/Bioinformatics/Production/Bari/refDatabases/scikit_0.20.2_q2_2019.1/silva-132-99-nb-classifier.qza'" >> ${myOutPath}_2019.1/TESTconfig.yml

module load sge perl/5.18.0 miniconda/3 python3/3.6.3
unset module

for i in "${MODES[@]}"
do
    outPath="${myOutPath}_${i}/"
    cmd="qsub -q xlong.q -V -j y -S /bin/sh -o ${outPath} ${myExecPath}/Q2_wrapper.sh ${outPath}/TESTconfig.yml"
    echo "Command run: $cmd"
    eval "$cmd"
done
