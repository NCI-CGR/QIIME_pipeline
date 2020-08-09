# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Exposed the "min fold parent over abundance" parameter for DADA2 denoising within QIIME.  The default value is 1, so set to 1 if you need pipeline output analyzed in the same way as before this change.  Increasing this value will decrease the stringency of chimera removal.
- Q2_wrapper.sh will now emit the "commit-ish" description of the pipeline version being run (e.g. v2.0 for tagged releases, or v2.0-5-g26a4da8 for unreleased versions). 
- Extract flat text files from denoising/feature_tables/merged.qza, denoising/sequence_tables/merged.qza, and taxonomic_classification/barplots_<...>.qzv (for 2019.1 only; not supported for 2017.11)
- Added user-configurable options for filtering of samples, features, reads
- Removed non-bacterial reads and bacterial reads without a phylum-level classification ("bacteria_only" directories)
- QIITA data with non-conformant fastq headers are now automatically fixed
- External (non-CGR) input data is now examined for unpaired reads and corrected

### Changed
- Input fastqs must be gzipped

### Fixed
- Alleviated scalabilty issue in creating QIIME2 manifests

## [2.1.0] - 2020-06-15
### Added
- Included `report/` directory with Juptyer notebook for generating QC reports.

### Changed
- Updated readme to detail how to develop, run, and export QC report.

## [2.0.1] - 2020-06-13
### Changed
- Altered the command run in `rule combine_Q2_manifest_by_runID` to circumvent potential CLI character limitations. 

## Types of changes noted here:
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
