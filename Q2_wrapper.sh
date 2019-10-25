#!/bin/sh

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     S. Sevilla Chill
#     W. Zhou
#     B. Ballew
# 
# TO RUN:
#     Have perl and conda in $PATH
#     Have QIIME2 conda environment set up as in Q2 docs
#     Copy config.yaml to local dir and edit as needed
#     Submit this script to a cluster or run locally
#     See run_pipeline.sh for example

set -euo pipefail

# custom exit function
die() {
    echo "ERROR: $*" 1>&2
    exit 1
}

config_file=""
if [ $# -eq 0 ]; then
    die "Please specify config file with full path."
else 
    config_file=$1
fi

if [ ! -f "$config_file" ]; then
    die "Config file not found."
fi

# note that this will only work for simple, single-level yaml
# and requires a whitespace between the key and value pair in the config
# (except for the cluster command, which requires single or double quotes)
exec_dir=$(awk '($0~/^exec_dir/){print $2}' $config_file | sed "s/['\"]//g")
out_dir=$(awk '($0~/^out_dir/){print $2}' $config_file | sed "s/['\"]//g") 
log_dir="${out_dir}/logs/"
# tempDir=$(awk '($0~/^tempDir/){print $2}' $config_file | sed "s/['\"]//g")
num_jobs=$(awk '($0~/^num_jobs/){print $2}' $config_file | sed "s/['\"]//g")
latency=$(awk '($0~/^latency/){print $2}' $config_file | sed "s/['\"]//g")
cluster_line=$(awk '($0~/^cluster_mode/){print $0}' $config_file | sed "s/\"/'/g")
    # allows single or double quoting of the qsub command in the config file
cluster_mode='"'$(echo $cluster_line | awk -F\' '($0~/^cluster_mode/){print $2}')'"'
qiime2_version=$(awk '($0~/^qiime2_version/){print $2}' $config_file | sed "s/['\"]//g")


# TODO: enforce minimal version requirements
# check dependencies and print to stdout
echo "Dependencies:"
conda --version || die "conda not detected."
perl --version | head -n2 | tail -n1 || die "Perl not detected."
python --version || die "Python not detected."

# only allow tested and confirmed versions of Q2
if [[ "$qiime2_version" != "2017.11" ]] && [[ "$qiime2_version" != "2019.1" ]]; then
    die "QIIME2 version ${qiime2_version} is not supported.  Please select 2017.11 or 2019.1."
else
    source activate qiime2-${qiime2_version}
    qiime --version | head -n1
fi

# check config file for errors (TODO)
# perl ${execDir}/scripts/check_config.pl $config_file

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir" || die "mkdir -p ${log_dir} failed."
fi

DATE=$(date +"%Y%m%d%H%M")

cmd=""
if [ "$cluster_mode" == '"'"local"'"' ]; then
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile --rerun-incomplete &> ${log_dir}/Q2_${DATE}.out"
elif [ "$cluster_mode" = '"'"unlock"'"' ]; then
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile --unlock"  # convenience unlock
elif [ "$cluster_mode" = '"'"dryrun"'"' ]; then  
    cmd="conf=$config_file snakemake -n -p -s ${exec_dir}/Snakefile"  # convenience dry run
else
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile --rerun-incomplete --cluster ${cluster_mode} --jobs $num_jobs --latency-wait ${latency} &> ${log_dir}/Q2_${DATE}.out"
fi

echo "Command run: $cmd"
eval $cmd 
