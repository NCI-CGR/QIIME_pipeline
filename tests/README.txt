Here are test procedcures for current QIIME2 16S pipeline:

1. Input data:

Configure file: ./QIIME_pipeline/config/config_test.yaml.

Manifest file: ./QIIME_pipeline/tests/input/external_test.txt


2. Pipeline run:

module load python3/3.10.2
module load bbmap
source activate qiime2_2019
conf=config/config_test.yaml snakemake -pr -s workflow/Snakefile -c8

3. Expected output:

/DCEG/Projects/Microbiome/Analysis/Project_33449_NP0610-MB1/Github/QIIME_pipeline/tests/expected_output