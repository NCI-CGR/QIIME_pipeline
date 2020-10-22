Configuration details
=====================

* ``metadata_manifest:`` full path to manifest file
* ``out_dir:`` full path to desired output directory (note that CGR production runs are stored at ``/DCEG/Projects/Microbiome/Analysis/``)
* ``exec_dir:`` full path to pipeline (e.g. Snakefile)
* ``fastq_abs_path:`` full path to fastqs
* ``temp_dir:`` full path to temp/scratch space
* ``qiime2_version:`` only two versions permitted (2017.11 or 2019.1)
* ``reference_db:`` list classifiers (1+) to be used for taxonomic classification; be sure to match trained classifiers with correct qiime version
* ``cluster_mode:`` options are ``'qsub/sbatch/etc ...'``, ``'local'``, ``'dryrun'``, ``'unlock'``

  * Example for cgems: 
  :: 

    'qsub -q long.q -V -j y -S /bin/bash -o /path/to/project/directory/logs/ -pe by_node {threads}'

  * When running on an HPC, it is important to:
    
    * Set the shell (``-S /bin/bash`` above)
    * Set the environment (``-V`` above to export environemnt variables to job environments)
    * Allocate the appropriate number of parallel resources via ``{threads}``, which links the number of threads requested by the job scheduler to the number of threads specified in the snakemake rule (``-pe by_node {threads}`` above)
