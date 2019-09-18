#!/bin/bash
# Generating a Visualization for the demultiplexing results

#input
##Requires 1 arguments -
	#1) full path to QZA file
		##Example: path/to/projectdirectory/Output/qza_results/demux_qza_split_parts

#output
	#1) QZV file(s) named {demux_param}_{runid}.qzv in path/to/projectdirectory/Output/qzv_results/demux_qzv_split_parts

module load miniconda/3 #only needed if running stand-alone
source activate qiime2-2017.11 #only needed if running stand-alone

demux_qza_split_part=$1
shift

if [ "$#" -ne 0 ]; then
  echo "Usage: $0 /path/to/demuxqzafile" >&2
  exit 1
fi

#Will replace QZA from directory and file named
#Example QZA: path/to/projectdirectory/Output/qza_results/demux_qza_split_parts/paired_end_demux_180112_M01354_0104_000000000-BFN3F.qza
#Example QZV: path/to/projectdirectory/Output/qzv_results/demux_qzv_split_parts/paired_end_demux_180112_M01354_0104_000000000-BFN3F.qzv
demux_qzv_split_part=$demux_qza_split_part
demux_qzv_split_part=$(sed -e "s/qza/qzv/g" <<< $demux_qzv_split_part)

cmd="qiime demux summarize \
  	--i-data ${demux_qza_split_part} \
  	--o-visualization ${demux_qzv_split_part}"
echo $cmd
eval $cmd
