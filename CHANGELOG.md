# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Exposed the "min fold parent over abundance" parameter for DADA2 denoising within QIIME.  The default value is 1, so set to 1 if you need pipeline output analyzed in the same way as before this change.  Increasing this value will decrease the stringency of chimera removal.
- Q2_wrapper.sh will now emit the "commit-ish" description of the pipeline version being run (e.g. v2.0 for tagged releases, or v2.0-5-g26a4da8 for unreleased versions). 


## Types of changes noted here:
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
