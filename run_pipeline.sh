#!/bin/sh

source /etc/profile.d/modules.sh; module load sge perl/5.18.0 python3/3.6.3 miniconda/3
source activate qiime2-2017.11

cmd="bash /DCEG/CGF/Bioinformatics/Production/Bari/QIIME_pipeline/Q2_wrapper.sh ${PWD}/config.yml"
echo "Command run: $cmd"
eval $cmd

# cmd="qsub -q long.q -V -j y -S /bin/sh -o ${PWD} $path/to/pipeline/Q2_wrapper.sh ${PWD}/config.yml"
# echo "Command run: $cmd"
# eval $cmd