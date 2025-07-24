# 16S Short Read  Delivery Files

## Overview

This delivery folder contains results from a 16S rRNA short read sequencing pipeline using the latest QIIME2 and DADA2 workflow. The folder is organized to include all relevant outputs, QC summaries, and configuration files to support downstream microbiome analyses.

The standard delivery path for each project is:

```
/DCEG/Projects/DataDelivery/Microbiome_Data_Delivery/CGR_Illumina_16S/{ProjectID}
```

---

## 1. Major Result Files

### A. Denoising and Feature Table (DADA2 Output)

**Location:** `run_*/denoising/`

- `merged.qza`, `merged.qzv` – Final feature table (QIIME2 artifact and visualization)
- `feature-table.biom`, `feature-table.from_biom.txt` – Converted BIOM tables
- `stats.qzv`, `stats.tsv` – DADA2 read filtering statistics

### B. Taxonomic Classification (SILVA 138 Classifier)

**Location:** `run_*/taxonomic_classification*/`

- `taxa.qza`, `taxa.qzv` – QIIME2 taxonomy assignment artifact and visualization
- `barplots.qzv` – Taxonomic composition bar plot
- `taxonomy.tsv` – Tabulated taxonomy for downstream use

### C. Diversity Analyses (Core Metrics)

**Location:** `run_*/diversity_core_metrics/`

- `rarefaction.qzv` – Alpha rarefaction plots
- `shannon.qza`, `evenness.qza`, `observed.qza`, `faith.qza` – Alpha diversity data
- `bray-curtis_dist.qza`, `jaccard_dist.qza`, `unweighted_dist.qza`, `weighted_dist.qza` – Beta diversity distance matrices
- `bray-curtis_emperor.qzv`, `jaccard_emperor.qzv`, `unweighted_emperor.qzv`, `weighted_emperor.qzv` – PCoA visualizations

---

## 2. Supporting and Supplementary Files

### A. Metadata and Manifest

- `manifest*.txt` – The manifest files using by QIIME2 pipeline.
- `metadata.tsv` – Sample metadata used in analysis

### B. QC Reports

**Location:** `report/`

- `CGR_16S_Microbiome_QC_Report.html` – Summary HTML report for read counts, quality, and filtering
- `sample-frequency-detail.csv` – Summary of feature frequency per sample

### C. Filtering and Intermediate Outputs

**Location:** `run_*/read_feature_and_sample_filtering/`

- Filtered feature tables and visualizations (e.g. low read count samples, low abundance features)
- `*.qza`, `*.qzv` files

---

## 3. Example Folder Structure

```bash
ProjectFolder/
├── report/
│   └── CGR_16S_Microbiome_QC_Report.html
├── run_091724/
│   ├── denoising/
│   ├── taxonomic_classification/
│   ├── diversity_core_metrics/
│   └── read_feature_and_sample_filtering/
├── metadata.tsv
└── manifest.txt
```

---

## 4. Delivery Checklist

| Deliverable                              | Included |
| ---------------------------------------- | -------- |
| Denoised feature table (`.qza`, `.biom`) | ✅        |
| Taxonomic assignments and barplots       | ✅        |
| Alpha/Beta diversity results             | ✅        |
| Rarefaction and ordination plots         | ✅        |
| QC summary report                        | ✅        |
| Sample metadata and manifests            | ✅        |
| Filtering intermediate results           | ✅        |
