Example output directory structure
==================================

Within parent directory ``<out_dir>/`` defined in ``config.yaml``
TODO: Needs updating!
::
    .
    ├── config_mock-20.yml
    ├── denoising
    │   ├── feature_tables
    │   │   ├── merged_filtered.qza
    │   │   ├── merged_filtered.qzv
    │   │   ├── merged.qza
    │   │   └── mock_runID_2020.qza
    │   ├── sequence_tables
    │   │   ├── merged.qza
    │   │   ├── merged.qzv
    │   │   └── mock_runID_2020.qza
    │   └── stats
    │       ├── mock_runID_2020.qza
    │       └── mock_runID_2020.qzv
    ├── diversity_core_metrics
    ├── fastqs
    │   ├── mock-20_R1.fastq.gz -> /path/to/originals/mock-20/mock-forward-read.fastq.gz
    │   └── mock-20_R2.fastq.gz -> /path/to/originals/mock-20/mock-reverse-read.fastq.gz
    ├── import_and_demultiplex
    │   ├── mock_runID_2020.qza
    │   └── mock_runID_2020.qzv
    ├── logs
    │   ├── Q2_202002061005.out
    │   └── ...
    ├── manifests
    │   ├── manifest_qiime2.tsv
    │   └── mock_runID_2020_Q2_manifest.txt
    ├── manifest.txt
    ├── phylogenetics
    │   ├── masked_msa.qza
    │   ├── msa.qza
    │   ├── rooted_tree.qza
    │   └── unrooted_tree.qza
    ├── Q2_wrapper.sh.o3040063
    ├── run_pipeline.sh
    ├── run_times
    └── taxonomic_classification
        ├── barplots_classify-sklearn_gg-13-8-99-nb-classifier.qzv
        ├── classify-sklearn_gg-13-8-99-nb-classifier.qza
        ├── classify-sklearn_gg-13-8-99-nb-classifier.qzv
        └── classify-sklearn_silva-132-99-nb-classifier.qza

