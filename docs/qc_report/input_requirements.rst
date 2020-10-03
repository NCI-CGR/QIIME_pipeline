Input requirements
==================

The manifest requirements for the report are the same as for the pipeline itself; however, including the following in your manifest will result in a more informative QC report:

* To be detected as blanks, water blanks and no-template control sample IDs must contain the string "water" or "ntc" in the "#SampleID" column; this is not case sensitive.
* "Source PCR Plate" column: header is case insensitive, can have spaces or not.  For the report, only the first characters preceding an underscore in this column will be preserved; this strips CGR's well ID from the string. 
* "Sample Type" column: header is case insensitive, can have spaces or not.  Populate with any string values that define useful categories, e.g. water, NTC_control, blank, study sample, qc, etc. 
* "External ID" column: header is case insensitive, can have spaces or not.  This column is used at CGR to map IDs of received samples to the LIMS-generated IDs we use internally.  For technical replicates, the sample ID will be unique (as required by QIIME), but the external ID can be the same to link the samples for comparison in the report.
* Note that the report assumes that the sequencer ID is the second underscore-delimited field in the run ID; this may not be meaningful if your run ID does not conform.

