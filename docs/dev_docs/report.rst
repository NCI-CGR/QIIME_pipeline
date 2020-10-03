For report development
======================

Jupyter notebooks are stored as JSON with metadata, which can result in very messy diffs/merge requests in version control.  Please do the following to create a clean python script version of the notebook to be used in diffs.

* After making and testing changes, Kernel > Restart & Clear Output
* Run in terminal: ``jupyter nbconvert --to script CGR_16S_Microbiome_QC_Report.ipynb``
* Add and commit both ``CGR_16S_Microbiome_QC_Report.ipynb`` AND ``CGR_16S_Microbiome_QC_Report.py``

