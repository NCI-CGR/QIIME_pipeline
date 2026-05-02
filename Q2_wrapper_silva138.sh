#!/bin/bash

# Modified CGR QIIME2 pipeline wrapper for SILVA 138 updates.
# Uses native QIIME 2 2024.5 installation.

set -eo pipefail

# Load necessary modules
module load python || true
module load bbmap || true

unset module

usage="Usage: $0 /path/to/config.yaml"

die() {
    printf "ERROR: %s\n" "$*" 1>&2
    exit 1
}

config_file=""
if [ $# -eq 0 ]; then
    die "Please specify config file with full path.
$usage"
else 
    # Get absolute path even if realpath behaves oddly
    config_file=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
fi

if [ ! -f "$config_file" ]; then
    die "Config file not found.
$usage"
fi

exec_dir=$(awk '($0~/^exec_dir/){print $2}' "$config_file" | sed "s/['\"]//g")
out_dir=$(awk '($0~/^out_dir/){print $2}' "$config_file" | sed "s/['\"]//g") 
log_dir="${out_dir}/logs/"
temp_dir=$(awk '($0~/^temp_dir/){print $2}' "$config_file" | sed "s/['\"]//g")
num_jobs=$(awk '($0~/^num_jobs/){print $2}' "$config_file" | sed "s/['\"]//g")
latency=$(awk '($0~/^latency/){print $2}' "$config_file" | sed "s/['\"]//g")
cluster_line=$(awk '($0~/^cluster_mode/){print $0}' "$config_file" | sed "s/\"/'/g")
cluster_mode='"'$(echo "$cluster_line" | awk -F\' '($0~/^cluster_mode/){print $2}')'"'
qiime2_version=$(awk '($0~/^qiime2_version/){print $2}' "$config_file" | sed "s/['\"]//g")

# Activate native QIIME 2 environment
if [ "$qiime2_version" == "2024.5" ]; then
    if [ -f "/DCEG_Vdrive/Resources/Tools/anaconda/anaconda3-2021.11/etc/profile.d/conda.sh" ]; then
        source "/DCEG_Vdrive/Resources/Tools/anaconda/anaconda3-2021.11/etc/profile.d/conda.sh"
    else
        eval "$(conda shell.bash hook)"
    fi
    
    conda activate qiime2-amplicon-2024.5 || die "Failed to activate qiime2-amplicon-2024.5"
    export PATH="/home/wany/.conda/envs/qiime2-amplicon-2024.5/bin:$PATH"
    
    unset SINGULARITY_BINDPATH
    unset APPTAINER_BINDPATH
    
    echo "Using QIIME 2 version:"
    qiime --version | head -n1 || echo "QIIME info still caching..."
else
    die "This wrapper is configured for QIIME2 version 2024.5 only. Got: $qiime2_version"
fi

# Export temp directory
if [ ! -d "$temp_dir" ]; then
    mkdir -p "$temp_dir" || die "mkdir -p ${temp_dir} failed."
fi
export TMPDIR="$temp_dir"

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir" || die "mkdir -p ${log_dir} failed."
fi

# IMPORTANT: Change to the output directory to avoid lock conflicts between runs
echo "Changing directory to $out_dir"
cd "$out_dir" || die "cd to $out_dir failed"

DATE=$(date +"%Y%m%d%H%M")

# Export conf environment variable for the Snakefile
export conf="$config_file"

# Add --touch and --cores 1 to ensure upstream results are considered up-to-date
echo "Touching existing results..."
snakemake --touch -s ${exec_dir}/workflow/Snakefile --cores 1 || true

# Main run
echo "Starting re-analysis from taxonomy..."
cmd="snakemake -p -s ${exec_dir}/workflow/Snakefile --rerun-incomplete --forcerun taxonomic_classification --cluster ${cluster_mode} --jobs $num_jobs --latency-wait ${latency} &> ${log_dir}/Q2_${DATE}.out"

if [ "$cluster_mode" = '"local"' ]; then
    cmd="snakemake -p -s ${exec_dir}/workflow/Snakefile --rerun-incomplete --forcerun taxonomic_classification &> ${log_dir}/Q2_${DATE}.out"
elif [ "$cluster_mode" = '"unlock"' ]; then
    cmd="snakemake -p -s ${exec_dir}/workflow/Snakefile --unlock --cores 1"
elif [ "$cluster_mode" = '"dryrun"' ]; then  
    cmd="snakemake -n -p -s ${exec_dir}/workflow/Snakefile --forcerun taxonomic_classification --cores 1"
fi

echo "Command run: $cmd"
eval "$cmd"
