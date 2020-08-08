#!/bin/sh

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     Y. Wan
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

# POSIX compliance notes: 
    # -o pipefail 
    # possibly `source activate conda-env`

set -euo pipefail

unset module

usage="Usage: $0 /path/to/config.yaml"

# custom exit function
die() {
    printf "ERROR: %s\n" "$*" 1>&2
    exit 1
}

config_file=""
if [ $# -eq 0 ]; then
    die "Please specify config file with full path.
$usage"
else 
    config_file=$1
fi

if [ ! -f "$config_file" ]; then
    die "Config file not found.
$usage"
fi

# note that this will only work for simple, single-level yaml
# and requires a whitespace between the key and value pair in the config
# (except for the cluster command, which requires single or double quotes)
exec_dir=$(awk '($0~/^exec_dir/){print $2}' "$config_file" | sed "s/['\"]//g")
out_dir=$(awk '($0~/^out_dir/){print $2}' "$config_file" | sed "s/['\"]//g") 
log_dir="${out_dir}/logs/"
temp_dir=$(awk '($0~/^temp_dir/){print $2}' "$config_file" | sed "s/['\"]//g")
num_jobs=$(awk '($0~/^num_jobs/){print $2}' "$config_file" | sed "s/['\"]//g")
latency=$(awk '($0~/^latency/){print $2}' "$config_file" | sed "s/['\"]//g")
cluster_line=$(awk '($0~/^cluster_mode/){print $0}' "$config_file" | sed "s/\"/'/g")
    # allows single or double quoting of the qsub command in the config file
cluster_mode='"'$(echo "$cluster_line" | awk -F\' '($0~/^cluster_mode/){print $2}')'"'
qiime2_version=$(awk '($0~/^qiime2_version/){print $2}' "$config_file" | sed "s/['\"]//g")

# TODO: enforce minimal version requirements
# check dependencies and print to stdout
echo "Dependencies:"
conda --version 2> /dev/null || die "conda not detected."
perl --version 2> /dev/null | head -n2 | tail -n1 || die "Perl not detected."
python --version 2> /dev/null || die "Python not detected."
printf "Snakemake: " 
snakemake --version 2> /dev/null || die "Snakemake not detected."
java -version 2>&1 | head -n1 || die "JDK not detected."
printf "bbtools: "
bbversion.sh || die "bbtools not detected."

# only allow tested and confirmed versions of Q2
if [ "$qiime2_version" != "2017.11" ] && [ "$qiime2_version" != "2019.1" ]; then
    die "QIIME2 version ${qiime2_version} is not supported.  Please select 2017.11 or 2019.1."
else
    source activate qiime2-"${qiime2_version}"
    qiime --version | head -n1
fi

# emit pipeline version
echo ""
echo "CGR QIIME pipeline version:"
git -C "${exec_dir}" describe 2> /dev/null || die "Unable to determine pipeline version information."
echo ""

# export temp directory (otherwise defaults to /tmp)
# https://forum.qiime2.org/t/tmp-directory-for-qiime-dada2-denoise-paired/6384
if [ ! -d "$temp_dir" ]; then
    mkdir -p "$temp_dir" || die "mkdir -p ${temp_dir} failed."
fi
export TMPDIR="$temp_dir"

# check config file for errors (TODO)
# perl ${execDir}/scripts/check_config.pl $config_file

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir" || die "mkdir -p ${log_dir} failed."
fi

DATE=$(date +"%Y%m%d%H%M")

cmd=""
if [ "$cluster_mode" = '"'"local"'"' ]; then
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile --rerun-incomplete &> ${log_dir}/Q2_${DATE}.out"
elif [ "$cluster_mode" = '"'"unlock"'"' ]; then
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile --unlock"  # convenience unlock
elif [ "$cluster_mode" = '"'"dryrun"'"' ]; then  
    cmd="conf=$config_file snakemake -n -p -s ${exec_dir}/Snakefile"  # convenience dry run
else
    cmd="conf=$config_file snakemake -p -s ${exec_dir}/Snakefile --rerun-incomplete --cluster ${cluster_mode} --jobs $num_jobs --latency-wait ${latency} &> ${log_dir}/Q2_${DATE}.out"
fi

echo "Command run: $cmd"
eval "$cmd"
