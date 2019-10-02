# CGR QIIME2 Microbiome Pipeline

This is the Cancer Genomics Research Laboratory's (CGR) microbiome analysis pipeline. This pipeline utilizes [QIIME2](https://qiime2.org/).

- Testing examples:
`/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Project_NP0501_MB1and2`
`/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Project_NP0440_MB4_Complete`

## Workflow summary

- Step1
  - Create project directory folders
  - Creates QIIME2 TSV formatted manifest file
  - Creates FASTQ directories and moves files to folders

- Step2
  - Demultiplexes data
  - Creates features tables and sequencing tables

- Step3
  - Will merge split data into one file file or rename file to match multiple flowcell outputs
  - Removes samples with zero reads from subsequent analysis

- Step4
  - Creates sequencing summary visuals
  - Maps and aligns sequences
  - Creates rooted and unrooted tree files

- Step5
  - Performs alpha and beta diversity
  - Performs taxonomic assignment using both greengenes and silva references
  - Creates barplot visuals for both references

## Output directory structure (within parent directory `<project>/Output/`):
```
.
├── qza_results
│   ├── abundance_qza_results
│   ├── core_metrics_results
│   │   ├── alpha-table.qzv
│   │   ├── bray_curtis_distance_matrix.qza
│   │   ├── bray_curtis_emperor.qzv
│   │   ├── bray_curtis_pcoa_results.qza
│   │   ├── evenness_vector.qza
│   │   ├── faith_pd_vector.qza
│   │   ├── jaccard_distance_matrix.qza
│   │   ├── jaccard_emperor.qzv
│   │   ├── jaccard_pcoa_results.qza
│   │   ├── observed_otus_vector.qza
│   │   ├── rarefied_table.qza
│   │   ├── shannon_vector.qza
│   │   ├── unweighted_unifrac_distance_matrix.qza
│   │   ├── unweighted_unifrac_emperor.qzv
│   │   ├── unweighted_unifrac_pcoa_results.qza
│   │   ├── weighted_unifrac_distance_matrix.qza
│   │   ├── weighted_unifrac_emperor.qzv
│   │   └── weighted_unifrac_pcoa_results.qza
│   ├── demux_qza_split_parts
│   │   └── paired_end_demux_1.qza
│   ├── phylogeny_qza_results
│   │   ├── aligned_rep_seqs.qza
│   │   ├── masked_aligned_rep_seqs.qza
│   │   ├── rooted_tree.qza
│   │   └── unrooted_tree.qza
│   ├── repseqs_dada2_qza_merged_parts_final
│   │   └── repseqs_dada2_merged_final.qza
│   ├── repseqs_dada2_qza_merged_parts_tmp
│   ├── repseqs_dada2_qza_split_parts
│   │   └── repseqs_dada2_1.qza
│   ├── table_dada2_qza_merged_parts_final
│   │   └── table_dada2_merged_final.qza
│   ├── table_dada2_qza_merged_parts_tmp
│   ├── table_dada2_qza_split_parts
│   │   └── table_dada2_1.qza
│   └── taxonomy_qza_results
│       ├── taxonomy_greengenes.qza
│       └── taxonomy_silva.qza
└── qzv_results
    ├── demux_qzv_split_parts
    │   └── paired_end_demux_1.qzv
    ├── otu_relative_abundance_results
    ├── rarefaction_qzv_results
    │   └── rarefaction.qzv
    ├── repseqs_dada2_qzv_merged_parts_final
    │   └── repseqs_dada2_merged_final.qzv
    ├── table_dada2_qzv_merged_parts_final
    │   └── table_dada2_merged_final.qzv
    ├── taxonomy_qzv_results
    │   ├── taxonomy_greengenes_bar_plots.qzv
    │   ├── taxonomy_greengenes.qzv
    │   ├── taxonomy_silva_bar_plots.qzv
    │   └── taxonomy_silva.qzv
    └── taxonomy_relative_abundance_results
```
## Input Requirements
- Edited config.yaml file
- LIMS downloaded (w/ or w/o metadata added) manifest txt file

## Workflow Details

### Manifest
QIIME2 has specific metadata requirements for headers and columns, and as the user is creating manifest (likely) in Excel, need to parse files to ensure that it meets requirements. Samples are run at a flowcell level, and manifest files are generated to include sample lists by flowcell.

__Note:__ Samples are run at a flowcell level, due to DADA2 run requirements. The algorithm that DADA2 uses includes an error model that assumes one sequencing run. The pitfall of merging them together prior to running DADA2 is that a lower-quality run (but still passing threshold) may have samples thrown out because they are significantly lower than a high performing run.

### Symlinks
Investigators need access to FASTQ files, as they are not able to access these files from our network directly.

### Demultiplexed Summaries
Flowcells are processed and summary information including sequence reads by sample, is generated in QIIME2 artifact format (QZA) and in visualization format (QZV).

### Step 1

Using the command line, the project directory and manifest text file are input. Directories are created, a manifest file in the qiime2 format (TSV) is created, FASTQ directories are created (based on the number of flowcells), and soft links to FASTQ files are placed in correct directories.
- Project folder creation
- QIIME2 TSV file creation
- Split manifest

Required scripts:
  - Step1.pl

__Note:__	After creating the QIIME2 manifest file, www.keemi.qiime2.org can be used from Google Chrome to verify the manifest is in the correct format.

__Note:__ Samples are run at a flowcell level, due to DADA2 run requirements. The algorithm that DADA2 uses includes an error model that assumes one sequencing run. The pitfall of merging them together prior to running DADA2 is that a lower-quality run (but still passing threshold) may have samples thrown out because they are significantly lower than a high performing run.

### Step 2

Inputs the split fastq manifest(s) and creates QC summaries, including visualizations for sample quality
- Demultiplexing FastQ Summary
- Create demultiplexing visual
- Create feature tables

Required scripts:
- Global.rc
- Step2.sh
  - Step2_1.sh

### Step 3

This step will merge multiple flowcells into one file, or rename the singular flowcell to match requirements.
- If multiple flowcells:
  - Merge multiple flowcells (table merging)
  - Finalize multiple flowcells
  - Merge multiple flowcells (Repseq merging)
  - Finalize Multiple Flowcells (Repseq)
  - Filter zero reads
- If single flowcell:
  - Finalize single flowcell (Table)
  - Finalize single flowcell (RepSeq)
  - Filter zero reads

Required scripts:
- Global.sh
- Step3.sh
  - Step3_1.sh
  - Step3_2.sh

### Step 4

This step creates sequencing summary visuals, maps and aligns sequences, and creates rooted and unrooted tree files.
- General table sequencing summary
- General mapping
- Alignment
- Masked alignment
- Unrooted tree
- Rooted tree

Required scripts:
- Global.sh
- Step4.sh
  - Step4_1.sh
  - Step4_2.sh

### Step 5

This step performs alpha and beta diversity, taxonomic assignment using both greengenes and silva references, and creates barplot visuals for both references.
- Alpha and Beta Diversity
- Creates Alpha Visualizations
- Greengenes:
  - Taxonomy results
  - Taxonomy results visualization
  - Taxonomic bar plot visualization
- Silva:
  - Taxonomy results
  - Taxonomy results visualization
  - Taxonomic bar plot visualization

Required scripts:
- Global.sh
- Step5.sh
  - Step5_1.sh
  - Step5_2.sh
  - Step5_3.sh
