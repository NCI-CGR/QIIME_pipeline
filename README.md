# CGR QIIME2 Microbiome Pipeline

This is the Cancer Genomics Research Laboratory's (CGR) microbiome analysis pipeline. This pipeline utilizes [QIIME2](https://qiime2.org/) to classify sequence data, calculate relative abundance, and perform alpha- and beta-diversity analysis.

## How to run

### Input requirements

- Manifest file
    - First X columns are required as shown here: (update!)
    ```
    #SampleID   External-ID    Sample-Type Source-Material  Source-PCR-Plate  Run-ID    Project-ID  Reciept   Sample_Cat SubjectID    Sample_Aliquot  Ext_Company   ...
    ```
- config.yaml
- (for production runs) run_pipeline.sh


### Options to run the pipeline (choose one)

A. Production run: Copy `run_pipeline.sh` and `config.yaml` to your directory, edit as needed, then execute the script.
B. For dev/testing only: Copy and edit `config.yaml`, then run the snakefile directly, e.g.:
```
module load perl/5.18.0 python3/3.6.3 miniconda/3
source activate qiime2-2017.11
conf=${PWD}/config.yml snakemake -s /path/to/pipeline/Snakefile
```

## Configuration details

- metadata_manifest: full path to manifest file
- out_dir: full path to desired output directory (note that production runs are stored at `/DCEG/Projects/Microbiome/Analysis/`)
- exec_dir: full path to pipeline (e.g. Snakefile)
- fastq_abs_path: full path to fastqs
- temp_dir: full path to temp/scratch space
- qiime2_version: only two versions permitted (2017.11 or 2019.1)
- reference_db: list classifiers (1+) to be used for taxonomic classification; be sure to match trained classifiers with correct qiime version
- cluster_mode: options are `'qsub ...'`, `'local'`, `'dryrun'`, `'unlock'`
  - Example for cgems: `'qsub -q long.q -V -j y -S /bin/bash -o /DCEG/CGF/Bioinformatics/Production/Bari/QIIME_test/2019/logs/ -pe by_node {threads}'`
  - When running on an HPC, it is important to:
    - Set the shell (`-S /bin/bash` above)
    - Set the environment (`-V` above to export environemnt variables to job environments)
    - Allocate the appropriate number of parallel resources via `{threads}`, which links the number of threads requested by the job scheduler to the number of threads specified in the snakemake rule (-pe by_node `{threads}` above)

## Workflow summary

1. Manifest management:
  - Manifest provided in config.yaml is checked for compliance with QIIME2 specifications
  - Per-flow cell manifests are created
2. Symlink fastqs to be viewable by DCEG PIs
3. Import and demultiplex fastqs
4. Denoise
5. Merge feature and sequence tables across flow cells; drop samples with zero reads
6. Build multiple sequence alignment, then build rooted and unrooted phylogenetic trees
7. Perform alpha- and beta-diversity analysis, rarefaction, and taxonomic classification

## Example output directory structure

- Within parent directory `<out_dir>/` defined in config.yaml
```
.
├── denoising
│   ├── feature_tables
│   │   ├── 180112_M01354_0104_000000000-BFN3F_paired_end_demux.qza
│   │   ├── 180112_M03599_0134_000000000-BFD9Y_paired_end_demux.qza
│   │   ├── 180328_M01354_0106_000000000-BFMHC_paired_end_demux.qza
│   │   ├── merged_filtered_paired_end_demux.qza
│   │   ├── merged_filtered_paired_end_demux.qzv
│   │   └── merged_paired_end_demux.qza
│   └── sequence_tables
│       ├── 180112_M01354_0104_000000000-BFN3F_paired_end_demux.qza
│       ├── 180112_M03599_0134_000000000-BFD9Y_paired_end_demux.qza
│       ├── 180328_M01354_0106_000000000-BFMHC_paired_end_demux.qza
│       ├── merged_paired_end_demux.qza
│       └── merged_paired_end_demux.qzv
├── diversity_core_metrics
│   ├── alpha_diversity_metadata.qzv
│   ├── bray-curtis_dist.qza
│   ├── bray-curtis_emperor.qzv
│   ├── bray-curtis_pcoa.qza
│   ├── evenness.qza
│   ├── faith.qza
│   ├── jaccard_dist.qza
│   ├── jaccard_emperor.qzv
│   ├── jaccard_pcoa.qza
│   ├── observed.qza
│   ├── rarefaction.qzv
│   ├── rareifed_table.qza
│   ├── shannon.qza
│   ├── unweighted_dist.qza
│   ├── unweighted_emperor.qzv
│   ├── unweighted_pcoa.qza
│   ├── weighted_dist.qza
│   ├── weighted_emperor.qzv
│   └── weighted_pcoa.qza
├── fastqs
│   ├── SC249358_R1.fastq.gz -> /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249358/SC249358_GAAGAAGCGGTA_L001_R1_001.fastq.gz
│   ├── SC249358_R2.fastq.gz -> /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249358/SC249358_GAAGAAGCGGTA_L001_R2_001.fastq.gz
│   └── ...
├── import_and_demultiplex
│   ├── 180112_M01354_0104_000000000-BFN3F_paired_end_demux.qza
│   ├── 180112_M01354_0104_000000000-BFN3F_paired_end_demux.qzv
│   ├── 180112_M03599_0134_000000000-BFD9Y_paired_end_demux.qza
│   ├── 180112_M03599_0134_000000000-BFD9Y_paired_end_demux.qzv
│   ├── 180328_M01354_0106_000000000-BFMHC_paired_end_demux.qza
│   └── 180328_M01354_0106_000000000-BFMHC_paired_end_demux.qzv
├── logs
│   ├── Q2_201911131438.out
│   ├── snakejob.alpha_beta_diversity.21.sh.o1741971
│   └── ...
├── manifests
│   ├── 180112_M01354_0104_000000000-BFN3F_Q2_manifest.txt
│   ├── 180112_M03599_0134_000000000-BFD9Y_Q2_manifest.txt
│   ├── 180328_M01354_0106_000000000-BFMHC_Q2_manifest.txt
│   └── manifest_qiime2.tsv
├── phylogenetics
│   ├── masked_msa.qza
│   ├── msa.qza
│   ├── rooted_tree.qza
│   └── unrooted_tree.qza
└── taxonomic_classification
    ├── barplots_classify-sklearn_gg-13-8-99-nb-classifier.qzv
    ├── barplots_classify-sklearn_silva-119-99-nb-classifier.qzv
    ├── classify-sklearn_gg-13-8-99-nb-classifier.qza
    ├── classify-sklearn_gg-13-8-99-nb-classifier.qzv
    ├── classify-sklearn_silva-119-99-nb-classifier.qza
    └── classify-sklearn_silva-119-99-nb-classifier.qzv
```

------------------------------------------------------------------------------------

## Notes 

- Testing examples:
`/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Project_NP0501_MB1and2`
`/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Project_NP0440_MB4_Complete`

- Samples are run at a flowcell level, due to DADA2 run requirements. The algorithm that DADA2 uses includes an error model that assumes one sequencing run. The pitfall of merging them together prior to running DADA2 is that a lower-quality run (but still passing threshold) may have samples thrown out because they are significantly lower than a high performing run.
- After creating the QIIME2 manifest file, www.keemi.qiime2.org can be used from Google Chrome to verify the manifest is in the correct format.
- Samples are run at a flowcell level, due to DADA2 run requirements. The algorithm that DADA2 uses includes an error model that assumes one sequencing run. The pitfall of merging them together prior to running DADA2 is that a lower-quality run (but still passing threshold) may have samples thrown out because they are significantly lower than a high performing run.
