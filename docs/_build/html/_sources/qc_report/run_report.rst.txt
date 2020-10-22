Running the report
==================

For CGR production runs, after the pipeline completes, generate a QC report using the Jupyter notebook in the ``report/`` directory. 

* Open the notebook (see below for details) and change the ``proj_dir`` variable in section 1.1
* Run the complete notebook
* Save the report as html with the code hidden (see below for details)

Running jupyter notebooks at CGR
--------------------------------

To run jupyter notebooks on the CGR HPC, login to the cluster, navigate to the notebook, then run the following.  You can set the port to anything above 8000.
::

  module load python3
  jupyter notebook --no-browser --port=8080



Then, on your local machine, run the following to open up an ssh tunnel:
::

  ssh -N -L 8080:localhost:8080 <username@cluster.domain>


Finally, open your browser to the URL given by the ``jupyter notebook`` command above (``https://localhost:8080/?token=<token>``).
