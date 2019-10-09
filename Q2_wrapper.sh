#!/bin/sh

set -euo pipefail

die() {
    echo "ERROR: $* (status $?)" 1>&2
    exit 1
}

config_file=""
if [ $# -eq 0 ]; then
    echo "ERROR: Please specify config file with full path."
    exit 1
else 
    config_file=$1
fi

if [ ! -f "$config_file" ]; then
    echo "ERROR: Config file not found."
    exit 1
fi

# note that this will only work for simple, single-level yaml
# this also requires a whitespace between the key and value pair in the config (except for the cluster command, which requires single or double quotes)
exec_dir=$(awk '($0~/^exec_dir/){print $2}' $config_file | sed "s/['\"]//g")
out_dir=$(awk '($0~/^out_dir/){print $2}' $config_file | sed "s/['\"]//g") 
log_dir="${out_dir}/QIIME2/logs/"
# tempDir=$(awk '($0~/^tempDir/){print $2}' $config_file | sed "s/['\"]//g")
num_jobs=$(awk '($0~/^num_jobs/){print $2}' $config_file | sed "s/['\"]//g")
latency=$(awk '($0~/^latency/){print $2}' $config_file | sed "s/['\"]//g")
cluster_line=$(awk '($0~/^cluster_mode/){print $0}' $config_file | sed "s/\"/'/g")  # allows single or double quoting of the qsub command in the config file
cluster_mode='"'$(echo $cluster_line | awk -F\' '($0~/^cluster_mode/){print $2}')'"'

# check config file for errors (TODO)
# perl ${execDir}/scripts/check_config.pl $config_file

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir" || die "mkdir ${log_dir} failed"
fi

if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir" || die "mkdir ${out_dir} failed"
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
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile_SV_scaffold --rerun-incomplete --cluster ${cluster_mode} --jobs $num_jobs --latency-wait ${latency} &> ${log_dir}/Q2_${DATE}.out"
fi

echo "Command run: $cmd"
eval $cmd 
