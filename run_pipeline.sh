#!/bin/bash

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
#     Edit below and then run: `bash run_pipeline.sh`

set -euo pipefail

#. /etc/profile.d/modules.sh; module load sge miniconda/3 
unset module

cmd="qsub -q long.q -V -j y -S /bin/sh -cwd Q2_wrapper.sh ${PWD}/config/config.yaml"
echo "Command run: $cmd"
eval "$cmd"


