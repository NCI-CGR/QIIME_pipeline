# CGR QIIME2 Microbiome Pipeline

This is the Cancer Genomics Research Laboratory's (CGR) microbiome analysis pipeline. This pipeline utilizes [QIIME2](https://qiime2.org/) to classify sequence data, calculate relative abundance, and perform alpha- and beta-diversity analysis.

## How to run

### Input requirements

- Manifest file
  - For external (non-CGR-produced data) runs, the following columns are required:
  ```
  #SampleID Run-ID  Project-ID  fq1 fq2
  ```
  - For internal runs, the following columns are required:
  ```
  #SampleID Run-ID  Project-ID
  ```
  - See the template manifest files in this repo for examples
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
- out_dir: full path to desired output directory (note that CGR production runs are stored at `/DCEG/Projects/Microbiome/Analysis/`)
- exec_dir: full path to pipeline (e.g. Snakefile)
- fastq_abs_path: full path to fastqs
- temp_dir: full path to temp/scratch space
- qiime2_version: only two versions permitted (2017.11 or 2019.1)
- reference_db: list classifiers (1+) to be used for taxonomic classification; be sure to match trained classifiers with correct qiime version
- cluster_mode: options are `'qsub/sbatch/etc ...'`, `'local'`, `'dryrun'`, `'unlock'`
  - Example for cgems: `'qsub -q long.q -V -j y -S /bin/bash -o /path/to/project/directory/logs/ -pe by_node {threads}'`
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
├── config_mock-20.yml
├── denoising
│   ├── feature_tables
│   │   ├── merged_filtered.qza
│   │   ├── merged_filtered.qzv
│   │   ├── merged.qza
│   │   └── mock_runID_2020.qza
│   ├── sequence_tables
│   │   ├── merged.qza
│   │   ├── merged.qzv
│   │   └── mock_runID_2020.qza
│   └── stats
│       ├── mock_runID_2020.qza
│       └── mock_runID_2020.qzv
├── diversity_core_metrics
├── fastqs
│   ├── mock-20_R1.fastq.gz -> /path/to/originals/mock-20/mock-forward-read.fastq.gz
│   └── mock-20_R2.fastq.gz -> /path/to/originals/mock-20/mock-reverse-read.fastq.gz
├── import_and_demultiplex
│   ├── mock_runID_2020.qza
│   └── mock_runID_2020.qzv
├── logs
│   ├── Q2_202002061005.out
│   └── ...
├── manifests
│   ├── manifest_qiime2.tsv
│   └── mock_runID_2020_Q2_manifest.txt
├── manifest.txt
├── phylogenetics
│   ├── masked_msa.qza
│   ├── msa.qza
│   ├── rooted_tree.qza
│   └── unrooted_tree.qza
├── Q2_wrapper.sh.o3040063
├── run_pipeline.sh
├── run_times
└── taxonomic_classification
    ├── barplots_classify-sklearn_gg-13-8-99-nb-classifier.qzv
    ├── classify-sklearn_gg-13-8-99-nb-classifier.qza
    ├── classify-sklearn_gg-13-8-99-nb-classifier.qzv
    └── classify-sklearn_silva-132-99-nb-classifier.qza
```

## QC report

### Input requirements

The manifest requirements for the report are the same as for the pipeline itself; however, including the following in your manifest will result in a more informative QC report:
- To be detected as blanks, water blanks and no-template control sample IDs must contain the string "water" or "ntc" in the "#SampleID" column; this is not case sensitive.
- "Source PCR Plate" column: header is case insensitive, can have spaces or not.  For the report, only the first characters preceding an underscore in this column will be preserved; this strips CGR's well ID from the string. 
- "Sample Type" column: header is case insensitive, can have spaces or not.  Populate with any string values that define useful categories, e.g. water, NTC_control, blank, study sample, qc, etc. 
- "External ID" column: header is case insensitive, can have spaces or not.  This column is used at CGR to map IDs of received samples to the LIMS-generated IDs we use internally.  For technical replicates, the sample ID will be unique (as required by QIIME), but the external ID can be the same to link the samples for comparison in the report.
- Note that the report assumes that the sequencer ID is the second underscore-delimited field in the run ID; this may not be meaningful if your run ID does not conform.


### Running the report

For CGR production runs, after the pipeline completes, generate a QC report using the Jupyter notebook in the `report/` directory.  
- Open the notebook (see below for details) and change the `proj_dir` variable in section 1.1
- Run the complete notebook
- Save the report as html with the code hidden (see below for details)


### Running jupyter notebooks at CGR

To run jupyter notebooks on the CGR HPC, login to the cluster, navigate to the notebook, then run the following.  You can set the port to anything above 8000.

```
module load python3
jupyter notebook --no-browser --port=8080

```

Then, on your local machine, run the following to open up an ssh tunnel:

```
ssh -N -L 8080:localhost:8080 <username@cluster.domain>
```

Finally, open your browser to the URL given by the `jupyter notebook` command above (`https://localhost:8080/?token=<token>`).


### To save the report

- Clone the following repo: `https://github.com/ihuston/jupyter-hide-code-html`
- Run in terminal: `jupyter nbconvert --to html --template jupyter-hide-code-html/clean_output.tpl path/to/CGR_16S_Microbiome_QC_Report.ipynb`
- Name the above file `NP###_pipeline_run_folder_QC_report.html` and place it in the directory with the pipeline output


### For development

Jupyter notebooks are stored as JSON with metadata, which can result in very messy diffs/merge requests in version control.  Please do the following to create a clean python script version of the notebook to be used in diffs.
- After making and testing changes, Kernel > Restart & Clear Output
- Run in terminal: `jupyter nbconvert --to script CGR_16S_Microbiome_QC_Report.ipynb`
- Add and commit both CGR_16S_Microbiome_QC_Report.ipynb AND CGR_16S_Microbiome_QC_Report.py

------------------------------------------------------------------------------------

## Notes 

- Samples are run at a flowcell level, due to DADA2 run requirements. The algorithm that DADA2 uses includes an error model that assumes one sequencing run. The pitfall of merging them together prior to running DADA2 is that a lower-quality run (but still passing threshold) may have samples thrown out because they are significantly lower than a high performing run.
- After creating the QIIME2 manifest file, www.keemi.qiime2.org can be used from Google Chrome to verify the manifest is in the correct format.
