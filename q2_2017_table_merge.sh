#!/bin/bash

# CGR QIIME2 pipeline for microbiome analysis.
# 
# AUTHORS:
#     S. Sevilla Chill
#     W. Zhou
#     B. Ballew
# 
# QIIME2 2017.11 (and possibly other ~contemporaneous versions)
# only offers pair-wise merging of feature/seqeunce tables,
# and does not permit same-table merging.  This script performs
# iterative pair-wise table merging, resulting in a single merged
# table of all (2+) flow cells.
# 
# INPUT:
#     - QIIME2-generated per-flow cell feature or sequence tables
#       in qza format
# 
# OUTPUT:
#     - Merged multi-flow cell feature or sequence table in qza
#       format

# POSIX note: -o pipefail and use of arrays is not POSIX compliant.

set -euo pipefail

usage="Usage: $0 [feature|sequence] /path/to/output/merged.qza /path/to/input_1.qza /path/to/input_2.qza ... /path/to/input_n.qza"

if [ $# -lt 4 ]; then
    printf "Please specify table type (\"feature\" or \"sequence\"), output file, and more than one input file.\n%s\n" "$usage" && exit 1
fi

table_type="$1"    # can use this script for feature or sequence table, but must specify here!
shift
out="$1"           # desired path and name of final merged table
shift
first_in="$1"      # first input file in the list passed in
shift
inputs=("${@}")    # rest of input files

out_path=${first_in%/*}
cp "${first_in}" "${out_path}/tempA.qza" || { echo "ERROR: Could not cp ${first_in}."; exit 1; }   # preserve pre-merge files for pipeline resumability

# qiime command differs for sequence and feature table merging
if [ "$table_type" = "feature" ]; then
    opt1="merge"
    opt2="table"
elif [ "$table_type" = "sequence" ]; then
    opt1="merge-seq-data"
    opt2="data"
else
    printf "Table type must be \"feature\" or \"sequence\".\n%s\n" "$usage" && exit 1
fi

for i in "${inputs[@]}"; do
    cmd="qiime feature-table ${opt1} --i-${opt2}1 ${out_path}/tempA.qza --i-${opt2}2 ${i} --o-merged-${opt2} ${out_path}/tempB.qza"
    echo "$cmd"
    $cmd || { echo "ERROR: Command exited with non-zero exit status."; exit 1; }
    mv "${out_path}/tempB.qza" "${out_path}/tempA.qza" || { echo "ERROR: Could not mv ${out_path}/tempB.qza."; exit 1; }
done

mv "${out_path}/tempA.qza" "${out}" || { echo "ERROR: Could not mv ${out_path}/tempA.qza."; exit 1; }

