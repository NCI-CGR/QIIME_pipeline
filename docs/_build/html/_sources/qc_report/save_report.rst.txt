To save the report
==================

* Clone the following repo:
::

  https://github.com/ihuston/jupyter-hide-code-html

* Run in terminal: 
::

  jupyter nbconvert --to html --template jupyter-hide-code-html/clean_output.tpl path/to/CGR_16S_Microbiome_QC_Report.ipynb

* Name the above file ``NP###_pipeline_run_folder_QC_report.html`` and place it in the directory with the pipeline output
