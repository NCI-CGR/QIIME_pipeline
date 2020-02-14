#!/bin/bash

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     B. Ballew

stamp=$1
myExecPath="${PWD}/.."
obsBasePath="${PWD}/out_${stamp}"
expBasePath="${PWD}/expected_output"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <datestamp (YYYYMMDDHHmm)>"
    exit 1
fi

MODES=("2017.11_internal" "2019.1_internal" "2017.11_external" "2019.1_external" "2019.1_internal_all_fail_low_reads" "2019.1_internal_one_passing_sample" "external_config_no_fq1" "config_no_Run-ID" "config_dup_IDs")

check_manifests()
{
    local manifest_flag=0
    for j in "${1}/manifests/"*; do
        k="${j##*/}"
        if ! diff -q "${j}" "${2}/manifests/${k}" &>/dev/null; then
            manifest_flag=1
        fi
    done
    if [ "$manifest_flag" == 0 ]; then
        printf "PASS: All manifest files are as expected.\n\n" >> "${1}/diff_tests.txt"
    else
        printf "FAIL: Manifest files in ${1}/manifests do not match expected output ${2}/manifests.\n\n" >> "${1}/diff_tests.txt"
    fi
}

sort_with_headers()
{
    awk '(NR<2||$0~/^#/){print;next}{print | "sort"}' </dev/stdin
}

transpose()
{
    awk 'BEGIN{FS=OFS="\t"}{for(i=1;i<=NF;i++){a[NR,i]=$i}}NF>p{p=NF}END{for(j=1;j<=p;j++){str=a[1,j];for(i=2;i<=NR;i++){str=str"\t"a[i,j]}print str}}' </dev/stdin
}

module load python3

for i in "${MODES[@]}"; do
    echo "Comparing ${i} to expected output" | tee -a "${PWD}/out_${stamp}_report"
    obsPath="${obsBasePath}_${i}"
    expPath="${expBasePath}/${i}"

    # unzip qza and qzv files, and convert biom to tsv
    echo "Unzipping qza and qzv files..." | tee -a "${obsPath}/diff_tests.txt"
    for j in "${obsPath}"/*/*.qza "${obsPath}"/*/*/*.qza; do [ -f ${j} ] && unzip -q ${j} -d ${j%.*}_qza && mv ${j%.*}_qza/*/data ${j%.*}_qza/; done
    for j in "${obsPath}"/*/*.qzv "${obsPath}"/*/*/*.qzv; do [ -f ${j} ] && unzip -q ${j} -d ${j%.*}_qzv && mv ${j%.*}_qzv/*/data ${j%.*}_qzv/; done
    echo "Converting biom files to tsv..." | tee -a "${obsPath}/diff_tests.txt"
    for j in "${obsPath}"/*/*_qz*/data/*.biom "${obsPath}"/*/*/*_qz*/data/*.biom; do [ -f ${j} ] && biom convert -i ${j} -o ${j}.txt --to-tsv && rm ${j}; done

    # check manifests
    [ -d "${expPath}/manifests" ] && check_manifests "$obsPath" "$expPath"

    # check for expected manifest errors
    if [ "$i" == "external_config_no_fq1" ]; then
        if grep -q "ERROR: Manifest file ${myExecPath}/tests/input/test_12_samples_external_data_no_fq1.txt must contain headers Run-ID, Project-ID, fq1, and fq2" "${obsPath}/logs/Q2"*".out"; then
            printf "PASS: Expected fq1 header error confirmed.\n\n" >> "${obsPath}/diff_tests.txt"
        else
            printf "FAIL: Expected fq1 header error not found.\n\n" >> "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "config_no_Run-ID" ]; then
        if grep -q "ERROR: Manifest file ${myExecPath}/tests/input/test_12_samples_no_Run-ID.txt must contain headers Run-ID and Project-ID" "${obsPath}/logs/Q2"*".out"; then
            printf "PASS: Expected Run-ID header error confirmed.\n\n" >> "${obsPath}/diff_tests.txt"
        else
            printf "FAIL: Expected Run-ID header error not found.\n\n" >> "${obsPath}/diff_tests.txt"
        fi
    elif [ "$i" == "config_dup_IDs" ]; then
        if grep -q "ERROR: Duplicate sample IDs detected in" "${obsPath}/logs/Q2"*".out"; then
            printf "PASS: Expected duplicate sample ID error confirmed.\n\n" >> "${obsPath}/diff_tests.txt"
        else
            printf "FAIL: Expected duplicate sample ID error not found.\n\n" >> "${obsPath}/diff_tests.txt"
        fi
    elif [[ "$i" == "201"*"ternal"* ]]; then

        # check unzipped qza/qzv outputs
        if [ "$i" == "2019.1_internal_all_fail_low_reads" ]; then
            if grep -q "No features remain after denoising. Try adjusting your truncation and trim parameter settings." "${obsPath}/logs/snakejob.dada2_denoise"*; then
                printf "PASS: Rule dada2_denoise failed as expected when all samples have low read counts.\n\n" >> "${obsPath}/diff_tests.txt"
            else
                printf "FAIL: Rule dada2_denoise did not fail as expected when all samples have low read counts.\n\n" >> "${obsPath}/diff_tests.txt"
           fi
        elif [ "$i" == "2019.1_internal_one_passing_sample" ]; then
            if grep -q "(core dumped)" "${obsPath}/logs/snakejob.alpha_beta_diversity"*; then
                printf "PASS: Rule alpha_beta_diversity failed as expected when there is only one passing sample.\n\n" >> "${obsPath}/diff_tests.txt"
            else
                printf "FAIL: Rule alpha_beta_diversity did not fail as expected when there is only one passing sample.\n\n" >> "${obsPath}/diff_tests.txt"
            fi
        fi
        for f in ${expPath}/*/*_qz*/data/* ${expPath}/*/*/*_qz*/data/*; do
            if [[ "${f}" == *.biom.txt || "${f}" == *.csv || "${f}" == *.fasta || "${f}" == *MANIFEST || "${f}" == *.tsv || "${f}" == *.yml ]]; then
                g=$(sed "s|${expPath}|${obsPath}|" <(echo "${f}"))
                dos2unix -q "${f}" "${g}"
                # matrices output by qiime have columns in random order.  sort by row and column as follows.
                if [[ "${f}" == *.fasta ]]; then
                    cmd="cmp -s <(sort "${f}") <(sort "${g}") && echo \"PASS: files are identical\" || echo \"FAIL: files not identical\""
                elif [[ "${f}" == *diversity_core_metrics/*  ]]; then
                    if [[ "${f}" == *.csv ]]; then
                        cmd="python3 array_compare.py <(grep -v \"^#\" "${f}" | tr \",\" \"\\t\" | sort_with_headers | transpose | sort_with_headers | transpose | tail -n +2 | cut -f2-) <(grep -v \"^#\" "${g}" | tr \",\" \"\\t\" | sort_with_headers | transpose | sort_with_headers | transpose | tail -n +2 | cut -f2-)"
                    else
                        cmd="python3 array_compare.py <(grep -v \"^#\" "${f}" | sort_with_headers | transpose | sort_with_headers | transpose | tail -n +2 | cut -f2-) <(grep -v \"^#\" "${g}" | sort_with_headers | transpose | sort_with_headers | transpose | tail -n +2 | cut -f2-)"
                    fi
                elif [[ "${f}" == *.tsv  && "${f}" != *taxonomic_classification/*classifier_qz*/data/*.tsv ]]; then
                    cmd="cmp -s <(grep -v \"^#\" "${f}" | sort_with_headers | transpose | sort_with_headers | transpose) <(grep -v \"^#\" "${g}" | sort_with_headers | transpose | sort_with_headers | transpose) && echo \"PASS: files are identical\" || echo \"FAIL: files not identical\""
                elif [[ "${f}" == *.biom.txt ]]; then
                    cmd="cmp -s <(tail -n +2 "${f}" | sort_with_headers | transpose | sort_with_headers | transpose ) <(tail -n +2 "${g}" | sort_with_headers | transpose | sort_with_headers | transpose ) && echo \"PASS: files are identical\" || echo \"FAIL: files not identical\""
                elif [[ "${f}" == *.csv && "${f}" != *number-summaries* && "${f}" != *fastq-counts* ]]; then
                    cmd="cmp -s <(grep -v \"^#\" "${f}" | tr \",\" \"\t\" | sort_with_headers | transpose | sort_with_headers | transpose ) <(grep -v \"^#\" "${g}" | tr \",\" \"\t\" | sort_with_headers | transpose | sort_with_headers | transpose ) && echo \"PASS: files are identical\" || echo \"FAIL: files not identical\""
                elif [[  "${f}" != *number-summaries* && "${f}" != *fastq-counts* && "${f}" != *taxonomic_classification/*classifier_qz*/data/*.tsv ]]; then
                    cmd="cmp -s <(cat "${f}" | sort_with_headers | transpose | sort_with_headers | transpose) <(cat "${g}" | sort_with_headers | transpose | sort_with_headers | transpose) && echo \"PASS: files are identical\" || echo \"FAIL: files not identical\""
                fi
                echo $cmd >> "${obsPath}/diff_tests.txt"
                eval $cmd >> "${obsPath}/diff_tests.txt"
                echo "" >> "${obsPath}/diff_tests.txt"
            fi
        done
    fi

    echo "Failing tests:" | tee -a "${PWD}/out_${stamp}_report"
    grep -c "^FAIL" "${obsPath}/diff_tests.txt" | tee -a "${PWD}/out_${stamp}_report"
    echo "Passing tests:" | tee -a "${PWD}/out_${stamp}_report"
    grep -c "^PASS" "${obsPath}/diff_tests.txt" | tee -a "${PWD}/out_${stamp}_report"
    echo "" | tee -a "${PWD}/out_${stamp}_report"
done

