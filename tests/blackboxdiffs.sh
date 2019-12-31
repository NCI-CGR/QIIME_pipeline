#!/bin/bash

stamp=$1
obsBasePath="${PWD}/out_${stamp}"
expPath="${PWD}/expected_output"

if [ $# -eq 0 ]
  then
    echo "Usage: $0 <datestamp (YYYYMMDDHHmm)>"
    exit 1
fi

# for all samples fail:
# No features remain after denoising. Try adjusting your truncation and trim parameter settings.
# in logs/snakejob.dada2_denoise

MODES=("2017.11_internal" "2019.1_internal" "2017.11_external" "2019.1_external" "2019.1_internal_all_fail_low_reads" "2019.1_internal_one_passing_sample" "external_config_no_fq1" "config_no_Run-ID" "config_dup_IDs")

check_manifests() {    
    local manifest_flag=0
    for j in "${expPath}/${1}/"*
    do
        k="${j##*/}"
        if ! diff -q "${expPath}/${1}/${k}" "${obsPath}/manifests/${k}" &>/dev/null; then
            manifest_flag=1
        fi
    done
    if [ "$manifest_flag" == 0 ]; then
        echo "PASS: All manifest files are as expected" | tee -a "${obsPath}/diff_tests.txt"
    else
        echo "FAIL: Manifest file ${obsPath}/manifests/${k} does not match expected output ${expPath}/${1}/${k}" | tee -a "${obsPath}/diff_tests.txt"
    fi
}


for i in "${MODES[@]}"
do
    echo "$i"
    obsPath="${obsBasePath}_${i}"

    if [ "$i" == "2019.1_internal_all_fail_low_reads" ]; then
        check_manifests "internal_all_fail_low_reads"
        # check import/demux qza/v
        if grep -q "No features remain after denoising. Try adjusting your truncation and trim parameter settings." "${obsPath}/logs/snakejob.dada2_denoise"*; then
            echo "PASS: Rule dada2_denoise failed as expected when all samples have low read counts" | tee -a "${obsPath}/diff_tests.txt"
        else
            echo "ERROR: Rule dada2_denoise did not fail as expected when all samples have low read counts" | tee -a "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "2019.1_internal_one_passing_sample" ]; then
        check_manifests "internal_one_passing_sample"
        # check import/demux qza/v
        # 
        if grep -q "(core dumped)" "${obsPath}/logs/snakejob.alpha_beta_diversity"*; then
            echo "PASS: Rule alpha_beta_diversity failed as expected when there is only one passing sample" | tee -a "${obsPath}/diff_tests.txt"
        else
            echo "ERROR: Rule alpha_beta_diversity did not fail as expected when there is only one passing sample" | tee -a "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "external_config_no_fq1" ]; then
        if grep -q "ERROR: Manifest file /DCEG/CGF/Bioinformatics/Production/Microbiome/QIIME_pipeline/tests/input/test_12_samples_external_data_no_fq1.txt must contain headers Run-ID, Project-ID, fq1, and fq2" "${obsPath}/logs/Q2"*".out"; then
            echo "PASS: Expected fq1 header error confirmed." | tee -a "${obsPath}/diff_tests.txt"
        else
            echo "ERROR: Expected fq1 header error not found." | tee -a "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "config_no_Run-ID" ]; then
        if grep -q "ERROR: Manifest file /DCEG/CGF/Bioinformatics/Production/Microbiome/QIIME_pipeline/tests/input/test_12_samples_no_Run-ID.txt must contain headers Run-ID and Project-ID" "${obsPath}/logs/Q2"*".out"; then
            echo "PASS: Expected Run-ID header error confirmed." | tee -a "${obsPath}/diff_tests.txt"
        else
            echo "ERROR: Expected Run-ID header error not found." | tee -a "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "config_dup_IDs" ]; then
        if grep -q "ERROR: Duplicate sample IDs detected in/DCEG/CGF/Bioinformatics/Production/Microbiome/QIIME_pipeline/tests/input/test_12_samples_dup_IDs.txt" "${obsPath}/logs/Q2"*".out"; then
            echo "PASS: Expected duplicate sample ID error confirmed." | tee -a "${obsPath}/diff_tests.txt"
        else
            echo "ERROR: Expected duplicate sample ID error not found." | tee -a "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "2017.11_internal" ]; then
        check_manifests "internal"
        # check import/demux qza/v
        # 
    elif [ "$i" == "2019.1_internal" ]; then
        check_manifests "internal"
        # check import/demux qza/v
        # 
    elif [ "$i" == "2017.11_external" ]; then
        check_manifests "external"
        # check import/demux qza/v
        # 
    elif [ "$i" == "2019.1_external" ]; then
        check_manifests "external"
        # check import/demux qza/v
        # 
    fi

    echo ""
done

# tree in "expected_outputs":