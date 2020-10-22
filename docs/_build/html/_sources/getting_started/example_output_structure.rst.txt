Example output directory structure
==================================

Approximate example tree of parent directory `<out_dir>/` defined in config.yaml
::

  .
  ├── bacteria_only
  │   ├── feature_tables
  │   └── sequence_tables
  ├── config.yml
  ├── denoising
  │   ├── feature_tables
  │   ├── sequence_tables
  │   └── stats
  ├── diversity_core_metrics
  │   ├── gg-13-8-99-515-806-nb-classifier
  │   └── silva-132-99-515-806-nb-classifier
  ├── fastqs
  │   ├── NTC-PB96595-H-12_R1.fastq.gz -> /DCEG_Archive/CGR/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/170629_M03599_0095_000000000-B5HGD/CASAVA/L1/Project_NP0453-MB2/Sample_NTC-PB96595-H-12/NTC-PB96595-H-12_GCTCGAAGATCG_L001_R1_001.fastq.gz
  │   ├── NTC-PB96595-H-12_R1_paired.fastq.gz
  │   ├── NTC-PB96595-H-12_R2.fastq.gz -> /DCEG_Archive/CGR/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/170629_M03599_0095_000000000-B5HGD/CASAVA/L1/Project_NP0453-MB2/Sample_NTC-PB96595-H-12/NTC-PB96595-H-12_GCTCGAAGATCG_L001_R2_001.fastq.gz
  │   ├── NTC-PB96595-H-12_R2_paired.fastq.gz
  │   ├── NTC-PB96595-H-12_singletons.fastq.gz
  ├── import_and_demultiplex
  │   ├── 170629_M03599_0095_000000000-B5HGD.qza
  │   ├── 170629_M03599_0095_000000000-B5HGD.qzv
  │   ├── 170719_M01354_0073_000000000-B62F4.qza
  ├── logs
  │   ├── Q2_202010210116.out
  │   ├── snakejob.alpha_beta_diversity.1197.sh.o1730899
  │   ├── snakejob.alpha_beta_diversity.1197.sh.po1730899
  ├── manifests
  │   ├── 170629_M03599_0095_000000000-B5HGD_Q2_manifest.txt
  │   ├── 170719_M01354_0073_000000000-B62F4_Q2_manifest.txt
  │   └── manifest_qiime2.tsv
  ├── NP0453_MB3_NP0453_MB2_and_3_manifest.txt
  ├── phylogenetics
  │   ├── masked_msa.qza
  │   ├── msa.qza
  │   ├── rooted_tree.qza
  │   └── unrooted_tree.qza
  ├── Q2_wrapper.sh.o1723896
  ├── read_feature_and_sample_filtering
  │   ├── feature_tables
  │   └── sequence_tables
  ├── run_pipeline.sh
  ├── run_times
  ├── taxonomic_classification
  │   ├── gg-13-8-99-515-806-nb-classifier
  │   └── silva-132-99-515-806-nb-classifier
  ├── taxonomic_classification_bacteria_only
  │   ├── gg-13-8-99-515-806-nb-classifier
  │   └── silva-132-99-515-806-nb-classifier
  └── NP0453_MB2_and_3_20200613_initial_run_QC_report.html
