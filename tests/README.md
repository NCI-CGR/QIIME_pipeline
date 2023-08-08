# QIIME2 16S Pipeline Test Procedures

This document outlines the procedures for testing the current QIIME2 16S pipeline.

## 1. Input Data

The necessary configuration and manifest files are as follows:

- Configuration file: `./QIIME_pipeline/config/config_test.yaml`
- Manifest file: `./QIIME_pipeline/tests/input/external_test.txt`

## 2. Pipeline Run

To run the pipeline, use the following commands:

```bash
module load python3/3.10.2
module load bbmap
source activate qiime2_2019
conf=config/config_test.yaml snakemake -pr -s workflow/Snakefile -c8
```

## 3. Expected Output

Upon successful execution of the pipeline, the expected output will be generated and located at:

`/DCEG/Projects/Microbiome/Analysis/Project_33449_NP0610-MB1/Github/QIIME_pipeline/tests/expected_output`
