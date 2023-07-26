#!/bin/bash

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     W. Zhou
#     B. Ballew
#     Y. Wan
#     S. Sevilla Chill
# 
# TO RUN:
#     Have perl and conda in $PATH
#     Have QIIME2 conda environment set up as in Q2 docs
#     Copy config.yaml to local dir and edit as needed
#     Edit below and then run: `bash run_pipeline.sh`

set -euo pipefail

. /etc/profile.d/modules.sh; module load slurm singularity bbmap python3  

unset module

#cmd="qsub -q long.q -V -j y -S /bin/sh -cwd path_to_pipeline/workflow/scripts/Q2_wrapper.sh ${PWD}/config.yaml"
cmd="sbatch -p myqueueq --mem 32g --cpus-per-task=8 --time 24:00:00 -o snakemake-%j.out -e snakemake-%j.err /path_to_pipeline/workflow/scripts/Q2_wrapper.sh ${PWD}/config.yaml"
echo "Command run: $cmd"
eval "$cmd"


