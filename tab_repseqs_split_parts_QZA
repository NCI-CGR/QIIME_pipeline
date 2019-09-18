#!/bin/bash
# Sequence quality control and feature table construction: DADA2

#input
##Requires 2 arguments -
	#1) full path to QZA file
		##Example: path/to/projectdirectory/Output/qza_results/demux_split_parts_qza
	#2) denoise method
		##Example: dada2

#output
	#1) table
		##Example: /path/to/projectdirectory/Output/qza_results/table_split_parts_qza/table_dada2_180112_M01354_0104_000000000-BFN3F.qza
	#2) repseqs
		##Example: /path/to/projectdirectory/Output/qza_results/repseqs_split_parts_qza/repseqs_dada2_180112_M01354_0104_000000000-BFN3F.qza

module load miniconda/3 #only needed if running stand-alone
source activate qiime2-2017.11 #only needed if running stand-alone

demux_qza_split_part=$1
shift

demux_param=$1
shift

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 /path/to/demuxqzafile denoise_method" >&2
  exit 1
fi

table_split_part=$demux_qza_split_part
table_split_part=$(sed -e "s/_demux.*demux/table/g" <<< $table_split_part)

repseqs_split_part=$demux_qza_split_part
repseqs_split_part=$(sed -e "s/_demux.*demux/repseqs/g" <<< $repseq_split_part)

cmd="qiime $denoise_method denoise-paired \
  	--i-demultiplexed-seqs ${demux_qza_split_part} \
  	--o-table ${table_split_part} \
  	--o-representative-sequences ${repseqs_split_part} \
  	--p-trim-left-f 0 \
  	--p-trim-left-r 0 \
  	--p-trunc-len-f 0 \
	--p-trunc-len-r 0"


echo $cmd
eval $cmd
