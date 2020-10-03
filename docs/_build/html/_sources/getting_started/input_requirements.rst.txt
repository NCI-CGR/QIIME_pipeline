Input requirements
==================

* ``config.yaml``
* ``run_pipeline.sh``
* Manifest file
  
  * For external (non-CGR-produced data) runs, the following columns are required: ``#SampleID Run-ID  Project-ID  fq1 fq2``
  * For internal runs, the following columns are required: ``#SampleID Run-ID  Project-ID``
  * See the template manifest files in ``config/`` in this repo for examples

**To run the pipeline**

* For CGR production runs:

  * Create a project directory that includes the NP ID
  * Within that directory, create a directory for the initial run: ``YYYYMMDD_initial_run/``
  * Move the input requirements listed above to ``YYYYMMDD_initial_run/``
  * Execute ``run_pipeline.sh``

