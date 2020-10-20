#!/usr/bin/env python
# coding: utf-8

# In[ ]:


# to save report:
    # clone the following repo: https://github.com/ihuston/jupyter-hide-code-html
    # run in terminal: jupyter nbconvert --to html --template jupyter-hide-code-html/clean_output.tpl path/to/CGR_16S_Microbiome_QC_Report.ipynb
    # name the above file NP###_pipeline_run_folder_QC_report.html and place it in the directory with the pipeline output
    
# for version control:
    # Kernel > Restart & Clear Output
    # run in terminal: jupyter nbconvert --to script CGR_16S_Microbiome_QC_Report.ipynb
    # add/commit CGR_16S_Microbiome_QC_Report.ipynb AND CGR_16S_Microbiome_QC_Report.py to git


# # CGR 16S Microbiome QC Report

# <!-- <div id="toc_container"> -->
# <h2>Table of Contents</h2>
# <ul class="toc_list">
#   <a href="#1&nbsp;&nbsp;General-analysis-information">1&nbsp;&nbsp;General analysis information</a><br>
#   <ul>
#     <a href="#1.1&nbsp;&nbsp;Project-directory">1.1&nbsp;&nbsp;Project directory</a><br>
#     <a href="#1.2&nbsp;&nbsp;Project-directory-contents">1.2&nbsp;&nbsp;Project directory contents</a><br>
#     <a href="#1.3&nbsp;&nbsp;Parameters">1.3&nbsp;&nbsp;Parameters</a><br>
#     <a href="#1.4&nbsp;&nbsp;Dependency-versions">1.4&nbsp;&nbsp;Dependency versions</a><br>
#   </ul>
#   <a href="#2&nbsp;&nbsp;Samples-included-in-the-project">2&nbsp;&nbsp;Samples included in the project<br>
#   <a href="#3&nbsp;&nbsp;QC-checks">3&nbsp;&nbsp;QC checks</a><br>
#   <ul>
#     <a href="#3.1&nbsp;&nbsp;Read-trimming">3.1&nbsp;&nbsp;Read trimming</a><br>
#     <a href="#3.2&nbsp;&nbsp;Proportion-of-non-bacterial-reads">3.2&nbsp;&nbsp;Proportion of non-bacterial reads<br>
#     <ul>
#       <a href="#3.2.1&nbsp;&nbsp;Proportion-of-non-bacterial-reads-per-sample-type">3.2.1&nbsp;&nbsp;Proportion of non-bacterial reads per sample type<br>
#     </ul>
#     <a href="#3.3&nbsp;&nbsp;Sequencing-depth-distribution-per-flow-cell">3.3&nbsp;&nbsp;Sequencing distribution per flow cell</a><br>
#     <a href="#3.4&nbsp;&nbsp;Read-counts-after-filtering-in-blanks-vs.-study-samples">3.4&nbsp;&nbsp;Read counts after filtering in blanks vs. study samples</a><br>
#     <a href="#3.5&nbsp;&nbsp;Sequential-sample--and-feature-based-filters">3.5&nbsp;&nbsp;Sequential sample- and feature-based filters</a><br>
#     <a href="#3.6&nbsp;&nbsp;Biological-replicates">3.6&nbsp;&nbsp;Biological replicates</a><br>
#     <a href="#3.7&nbsp;&nbsp;QC-samples">3.7&nbsp;&nbsp;QC samples</a><br>
#   </ul>
#   <a href="#4&nbsp;&nbsp;Rarefaction-threshold">4&nbsp;&nbsp;Rarefaction threshold</a><br>
#   <a href="#5&nbsp;&nbsp;Alpha-diversity">5&nbsp;&nbsp;Alpha diversity</a><br>
#   <a href="#6&nbsp;&nbsp;Beta-diversity">6&nbsp;&nbsp;Beta diversity</a><br>
#   <ul>
#     <a href="#6.1&nbsp;&nbsp;Bray-Curtis">6.1&nbsp;&nbsp;Bray-Curtis</a><br>
#     <a href="#6.2&nbsp;&nbsp;Jaccard">6.2&nbsp;&nbsp;Jaccard</a><br>
#     <a href="#6.3&nbsp;&nbsp;Weighted-UniFrac">6.3&nbsp;&nbsp;Weighted UniFrac</a><br>
#     <a href="#6.4&nbsp;&nbsp;Unweighted-UniFrac">6.4&nbsp;&nbsp;Unweighted UniFrac</a><br>
#   </ul>
# </ul>

# In[ ]:


# allow user definition of column headers for certain things, eg sample type?


# <h2 id="1&nbsp;&nbsp;General-analysis-information">1&nbsp;&nbsp;General analysis information</h2>

# <h3 id="1.1&nbsp;&nbsp;Project-directory">1.1&nbsp;&nbsp;Project directory</h3>

# All production microbiome projects are located in `/DCEG/Projects/Microbiome/Analysis/`.  There is a parent folder named with the project ID; that folder contains the [bioinformatic pipeline](https://github.com/NCI-CGR/QIIME_pipeline) runs for that project and a `readme` summarizing the changes between each run.  
# 
# - The initial run (always named `<datestamp>_initial_run`) is used for some QC checks and to evaluate parameter settings.  
# - The second run implements additional read trimming and excludes water blanks, no-template controls, and QC samples (e.g. robogut or artificial colony samples).  (NOTE: pick one of intentional dups?)
# - Additional runs are performed for study-specific reasons which are summarized in the `readme`.
# <br><br>
# 
# __The project and pipeline run described in this report is located here:__

# In[ ]:


proj_dir='/DCEG/Projects/Microbiome/Analysis/Project_NP0539-MB1/20201016_dev_test'
ref_db='silva-132-99-515-806-nb-classifier'


# In[ ]:


get_ipython().run_line_magic('cd', '{proj_dir}')


# The contents of the `readme`, at the time of report generation:

# In[ ]:


get_ipython().system('cat ../README')


# <h3 id="1.2&nbsp;&nbsp;Project-directory-contents">1.2&nbsp;&nbsp;Project directory contents</h3>

# In[ ]:


get_ipython().system('ls')


# <h3 id="1.3&nbsp;&nbsp;Parameters">1.3&nbsp;&nbsp;Parameters</h3>

# In[ ]:


get_ipython().system('cat *.yml')


# <h3 id="1.4&nbsp;&nbsp;Dependency-versions">1.4&nbsp;&nbsp;Dependency versions</h3>

# In[ ]:


get_ipython().system('cat $(ls -t Q2_wrapper.sh.o* | head -n1)')


# <h2 id="2&nbsp;&nbsp;Samples-included-in-the-project">2&nbsp;&nbsp;Samples included in the project</h2>

# The tables below show the count of samples grouped by metadata provided in the manifest.

# In[ ]:


from IPython.display import display
import os.path
get_ipython().run_line_magic('matplotlib', 'inline')
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import seaborn as sns
import glob
from skbio.stats.ordination import pcoa
from skbio import DistanceMatrix

sns.set(style="whitegrid")


# In[ ]:


manifest = pd.read_csv(glob.glob('*.txt')[0],sep='\t',index_col=0)
manifest.columns = map(str.lower, manifest.columns)
manifest = manifest.dropna(how='all', axis='columns')
manifest.columns = manifest.columns.str.replace(' ', '')  # remove once cleaning is implemented in the pipeline


# In[ ]:


if len(manifest['run-id'].astype(str).str.split('_',n=2,expand=True).columns) > 1:
    manifest['Sequencer'] = (manifest['run-id'].astype(str).str.split('_',n=2,expand=True))[1]
else:
    print("Can not infer sequencer ID from run ID.")
    
if 'sourcepcrplate' in manifest.columns:
    manifest['PCR_plate'] = (manifest['sourcepcrplate'].str.split('_',n=1,expand=True))[0]
else:
    print("Source PCR Plate column not detected in manifest.")
# should probably save this file, or even better, include in original manifest prior to analysis....


# In[ ]:


m = manifest.drop(columns=['externalid','sourcepcrplate','project-id','extractionbatchid','fq1','fq2'],errors='ignore')
# when do we want to drop extraction ID?  in this case, it's all unique values for QC samples and NaNs for study samples
# possibly look for (# unique values == # non-nan values) instead of alßways dropping

for i in m.columns:
    display(m[i].value_counts().rename_axis(i).to_frame('Number of samples'))


# <h2 id="3&nbsp;&nbsp;QC-checks">3&nbsp;&nbsp;QC checks</h2>

# <h3 id="3.1&nbsp;&nbsp;Read-trimming">3.1&nbsp;&nbsp;Read trimming</h3>

# The trimming parameters for the initial pipeline run (`<datestamp>_initial_run`) are set to 0 (no trimming).  For subsequent runs, trimming parameters are set based on the read quality plots (not shown here; please browse `import_and_demultiplex/<runID>.qzv` using [QIIME's viewer](https://view.qiime2.org/) for quality plots).  For this run, trimming parameters (also found in the config) are as follows:

# In[ ]:


get_ipython().system('grep -A4 "dada2_denoise" *.yml')


# <h3 id="3.2&nbsp;&nbsp;Proportion-of-non-bacterial-reads">3.2&nbsp;&nbsp;Proportion of non-bacterial reads</h3>

# After error correction, chimera removal, removal of phiX sequences, and the four-step filtering defined above, the remaining reads are used for taxonomic classification.  We are performing classification with a naive Bayes classifier trained on the SILVA 99% OTUs database that includes only the V4 region (defined by the 515F/806R primer pair).  This data is located at `taxonomic_classification/barplots_classify-sklearn_silva-132-99-515-806-nb-classifier.qzv`.  Please use [QIIME's viewer](https://view.qiime2.org/) for a more detailed interactive plot.
# 
# The plots below show the "level 1" taxonomic classification.  The first set of plots show relative abundances; the second show absolute.  Plots are split into sets of ~500 samples per plot.
# 
# Note that reads are being classified using a database of predominantly bacterial sequences, so human reads, for example, will generally be in the "Unclassified" category rather than "Eukaryota."  Non-bacterial reads can indicate host (human) or other contamination. 

# In[ ]:


get_ipython().system('unzip -q -d taxonomic_classification/rpt_silva taxonomic_classification/barplots_classify-sklearn_{ref_db}.qzv')


# In[ ]:


f = glob.glob('taxonomic_classification/rpt_silva/*/data/level-1.csv')
df_l1 = pd.read_csv(f[0])
df_l1 = df_l1.rename(columns = {'index':'Sample'})
df_l1 = df_l1.set_index('Sample')
df_l1 = df_l1.select_dtypes(['number']).dropna(axis=1, how='all')
df_l1_rel = df_l1.div(df_l1.sum(axis=1), axis=0) * 100


# In[ ]:


def split_df(df, max_rows = 500): 
    split_dfs = list()
    rows = df.shape[0]
    n = rows % max_rows
    last_rows = True
    for i in range(0, rows, max_rows):
        # if the last remainder of the rows is less than half the max value, 
        # just combine it with the second-to-last plot
        # otherwise it looks weird
        if i in range(rows-max_rows*2,rows-max_rows) and n <= (max_rows // 2):
            split_dfs.append(df.iloc[i:i+max_rows+n])
            last_rows = False
        elif last_rows:
            split_dfs.append(df.iloc[i:i+max_rows])
    return split_dfs
    # need to split very large datasets so rendering doesn't get weird


# In[ ]:


df_list = split_df(df_l1)
df_rel_list = split_df(df_l1_rel)


# In[ ]:


for i in df_rel_list:
    plt.figure(dpi=200)
    pal = sns.color_palette("Accent")
    ax = i.sort_values('D_0__Bacteria').plot.bar(stacked=True, color=pal, figsize=(60,7), width=1, edgecolor='white', ax=plt.gca())
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.5),ncol=4,fontsize=52)
    ax.set_ylabel('Relative frequency (%)',fontsize=52)
    ax.set_title('Taxonomic classification, level 1',fontsize=52)
    ax.set_yticklabels(ax.get_yticks(), size=40)
    plt.show()


# In[ ]:


for i in df_list:
    plt.figure(dpi=200)
    pal = sns.color_palette("Accent")
    ax = i.sort_values('D_0__Bacteria').plot.bar(stacked=True, color=pal, figsize=(60,7), width=1, edgecolor='white', ax=plt.gca())
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.5),ncol=4,fontsize=52)
    ax.set_ylabel('Absolute frequency',fontsize=52)
    ax.set_title('Taxonomic classification, level 1',fontsize=52)
    ax.set_yticklabels(ax.get_yticks(), size=40)
    plt.show()


# <h4 id="3.2.1&nbsp;&nbsp;Proportion-of-non-bacterial-reads-per-sample-type">3.2.1&nbsp;&nbsp;Proportion of non-bacterial reads per sample type</h4>

# This section highlights non-bacterial reads in various sub-populations included in the study (e.g. study samples, robogut or artificial control samples, and blanks).  This can be helpful with troubleshooting if some samples unexpectedly have a high proportion of non-bacterial reads.

# In[ ]:


def plot_level_1_subpops(samples,pop):
    plt.rcParams["xtick.labelsize"] = 12
    n = -0.5
    r = 90
    ha = "center"
    f = 12
    if len(samples) < 30:
        plt.rcParams["xtick.labelsize"] = 40
        n = -0.8
        r = 40
        ha = "right"
        f = 40
    df = df_l1_rel[df_l1_rel.index.isin(samples)]
    for i in split_df(df):
        plt.figure(dpi=200)
        pal = sns.color_palette("Accent")
        ax = i.sort_values('D_0__Bacteria').plot.bar(stacked=True, color=pal, figsize=(60,7), width=1, edgecolor='white', ax=plt.gca())
        ax.legend(loc='upper center', bbox_to_anchor=(0.5, n),ncol=4,fontsize=52)
        ax.set_ylabel('Relative frequency (%)',fontsize=52)
        ax.set_xlabel('Sample',fontsize=f)
        ax.set_title('Taxonomic classification, level 1, ' + pop + ' samples only',fontsize=52)
        ax.set_yticklabels(ax.get_yticks(), size = 40)
        ax.set_xticklabels(ax.get_xticklabels(), rotation=r, ha=ha)
        plt.show()


# In[ ]:


if 'sampletype' in manifest.columns:
    for i in manifest['sampletype'].unique():
        l = list(manifest[manifest['sampletype'].str.match(i)].index)
        plot_level_1_subpops(l,i)
else:
    print("No Sample Type column detected in manifest.")


# ## Non-bacterial read removal

# Best practices indicate we should filter these reads regardless of the degree to which we observe them.  The plots below show the "level 1" classification after non-bacterial read removal.
# 
# This data is located at `taxonomic_classification_bacteria_only/barplots_classify-sklearn_silva-132-99-515-806-nb-classifier.qzv`.  Please use [QIIME's viewer](https://view.qiime2.org/) for a more detailed interactive plot.

# In[ ]:


get_ipython().system('unzip -q -d taxonomic_classification_bacteria_only/rpt_silva taxonomic_classification_bacteria_only/barplots_classify-sklearn_{ref_db}.qzv')


# In[ ]:


f = glob.glob('taxonomic_classification_bacteria_only/rpt_silva/*/data/level-1.csv')
df_l1b = pd.read_csv(f[0])
df_l1b = df_l1b.rename(columns = {'index':'Sample'})
df_l1b = df_l1b.set_index('Sample')
df_l1b = df_l1b.select_dtypes(['number']).dropna(axis=1, how='all')
df_l1b_rel = df_l1b.div(df_l1b.sum(axis=1), axis=0) * 100


# In[ ]:


for i in split_df(df_l1b_rel):
    plt.figure(dpi=200)
    plt.rcParams["xtick.labelsize"] = 12
    pal = sns.color_palette("Accent")
    ax = i.sort_values('D_0__Bacteria').plot.bar(stacked=True, color=pal, figsize=(60,7), width=1, edgecolor='white', ax=plt.gca())
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.5),ncol=4,fontsize=52)
    ax.set_ylabel('Relative frequency (%)',fontsize=52)
    ax.set_xlabel('Sample',fontsize=12)
    ax.set_title('Taxonomic classification, level 1',fontsize=52)
    ax.set_yticklabels(ax.get_yticks(), size=40)
    plt.show()


# In[ ]:


for i in split_df(df_l1b):
    plt.figure(dpi=200)
    pal = sns.color_palette("Accent")
    plt.rcParams["xtick.labelsize"] = 12
    ax = i.sort_values('D_0__Bacteria').plot.bar(stacked=True, color=pal, figsize=(60,7), width=1, edgecolor='white', ax=plt.gca())
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.5),ncol=4,fontsize=52)
    ax.set_ylabel('Absolute frequency',fontsize=52)
    ax.set_xlabel('Sample',fontsize=12)
    ax.set_title('Taxonomic classification, level 1',fontsize=52)
    ax.set_yticklabels(ax.get_yticks(), size=40)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=90, ha="center", size=12)
    plt.show()


# <h3 id="3.3&nbsp;&nbsp;Sequencing-depth-distribution-per-flow-cell">3.3&nbsp;&nbsp;Sequencing depth distribution per flow cell</h3>

# Per-sample read depths are recorded in `import_and_demultiplex/<runID>.qzv`.  Those values are plotted below, excluding NTC and water blanks.  Distributions per flow cell should be similar if the flow cells contained the same number of non-blank samples.  If a flow cell contains fewer samples, each sample will have a greater number of reads, so that the total number of reads produced per flow cell remains approximately the same.

# In[ ]:


get_ipython().run_cell_magic('bash', '', 'cd import_and_demultiplex\nfor i in *qzv; do unzip -q $i -d "rpt_${i%.*}"; done\nfor i in rpt_*/*/data/per-sample-fastq-counts.csv; do j=${i%%/*}; k=${j#"rpt_"}; awk -v var="$k" \'BEGIN{FS=",";OFS="\\t"}$1!~/Sample name/{print $1,$2,var}\' $i >> t; done\ncat <(echo -e "Sample_name\\tSequence_count\\tRun_ID") t > rpt_vertical_per-sample-fastq-counts.csv\nrm t\ncd ..')


# In[ ]:


df_depth = pd.read_csv('import_and_demultiplex/rpt_vertical_per-sample-fastq-counts.csv',sep='\t')
search_values = ['Water','NTC']
df_depth_no_blanks = df_depth[~df_depth.Sample_name.str.contains('|'.join(search_values ),case=False)]
plt.figure(dpi=100)
sns.set(style="whitegrid")
ax = sns.boxplot(x="Run_ID",y="Sequence_count",data=df_depth_no_blanks)
ax.set_xticklabels(ax.get_xticklabels(),rotation=40,ha="right")#,fontsize=8)
ax.axes.set_title("Sequencing depth distribution per flow cell",fontsize=12)
# ax.tick_params(labelsize=8)
plt.show()


# <h3 id="3.4&nbsp;&nbsp;Read-counts-after-filtering-in-blanks-vs.-study-samples">3.4&nbsp;&nbsp;Read counts after filtering in blanks vs. study samples</h3>

# Per-sample read depths at each filtering step are recorded in `denoising/stats/<runID>.qzv`.  The plots below show the mean for each category; error bars indicate the 95% confidence interval.  
# 
# NTC blanks are expected to have near-zero read depths, and represent false positives introduced by sequencing reagents.  
# 
# Water blanks are expected to have read depths that are at least one to two orders of magnitude lower than the average study sample depth.  They represent the relatively low level of taxa that may be detected in the water used in the lab.

# In[ ]:


get_ipython().run_cell_magic('bash', '', 'cd denoising/stats/\nfor i in *qzv; do unzip -q $i -d "rpt_${i%.*}"; done\nfor i in rpt_*/*/data/metadata.tsv; do dos2unix -q $i; j=${i%%/*}; k=${j#"rpt_"}; awk -v var="$k" \'BEGIN{FS=OFS="\\t"}NR>2{print $0,var}\' $i >> t; done\ncat <(echo -e "sample-id\\tinput\\tfiltered\\tdenoised\\tmerged\\tnon-chimeric\\tflow_cell") t > rpt_denoising_stats.tsv\nrm t\ncd ../..')


# In[ ]:


df_stats = pd.read_csv('denoising/stats/rpt_denoising_stats.tsv',sep='\t')
df_stats = df_stats.set_index('sample-id')


# In[ ]:


def plot_read_counts(samples,pop):
    plt.figure(dpi=100)
    sns.set(style="whitegrid")
    ax = sns.barplot(data=df_stats[df_stats.index.isin(samples)]).set_title('Number of reads in ' + pop + ' samples')
    plt.show()


# In[ ]:


if 'sampletype' in manifest.columns:
    for i in manifest['sampletype'].unique():
        l = list(manifest[manifest['sampletype'].str.match(i)].index)
        plot_read_counts(l,i)
else:
    print("No Sample Type column detected in manifest.")


# The table below shows the 30 samples with the lowest non-chimeric read counts.  This information may be helpful in identifying problematic samples and determining a minimum read threshold for sample inclusion.  Note that low-depth study samples will be excluded from diversity analysis based on the sampling depth threshold selected (discussed in the following section).

# In[ ]:


if 'externalid' in manifest.columns:
    display(df_stats.join(manifest[['externalid']])[['externalid','input','filtered','denoised','merged','non-chimeric']].sort_values(['non-chimeric']).head(30))
else:
    display(df_stats[['input','filtered','denoised','merged','non-chimeric']].sort_values(['non-chimeric']).head(30))


# <h3 id="3.5&nbsp;&nbsp;Sequential-sample--and-feature-based-filters">3.5&nbsp;&nbsp;Sequential sample- and feature-based filters</h3>

# We remove samples and features based on the parameters defined in the config.  For this run, filtering parameters are as follows:

# In[ ]:


get_ipython().system('grep "min_num_" *.yml')


# Four sequential filtering steps are applied as follows:
# 1. Remove any samples with reads below the defined threshold
# 2. Remove any features with reads below the defined threshold
# 3. Remove any features that occur in fewer samples than the defined threshold
# 4. Remove any samples that contain fewer features than the defined threshold
# 
# Filtering is propagated through to sequence tables as well.
# 
# For this run, filtering resulted in the following counts:

# In[ ]:


get_ipython().system('unzip -q -d read_feature_and_sample_filtering/feature_tables/rpt_1 read_feature_and_sample_filtering/feature_tables/1_remove_samples_with_low_read_count.qzv')
get_ipython().system('unzip -q -d read_feature_and_sample_filtering/feature_tables/rpt_2 read_feature_and_sample_filtering/feature_tables/2_remove_features_with_low_read_count.qzv')
get_ipython().system('unzip -q -d read_feature_and_sample_filtering/feature_tables/rpt_3 read_feature_and_sample_filtering/feature_tables/3_remove_features_with_low_sample_count.qzv')
get_ipython().system('unzip -q -d read_feature_and_sample_filtering/feature_tables/rpt_4 read_feature_and_sample_filtering/feature_tables/4_remove_samples_with_low_feature_count.qzv')


# In[ ]:


get_ipython().system('echo "Feature counts:"')
get_ipython().system('echo "no_filtering" $(grep -cv "^#" denoising/feature_tables/feature-table.from_biom.txt)')
get_ipython().system('echo "remove_samples_with_low_read_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_1/*/data/feature-frequency-detail.csv | cut -d\' \' -f1)')
get_ipython().system('echo "remove_features_with_low_read_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_2/*/data/feature-frequency-detail.csv | cut -d\' \' -f1)')
get_ipython().system('echo "remove_features_with_low_sample_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_3/*/data/feature-frequency-detail.csv | cut -d\' \' -f1)')
get_ipython().system('echo "remove_samples_with_low_feature_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_4/*/data/feature-frequency-detail.csv | cut -d\' \' -f1)')


# In[ ]:


get_ipython().system('echo "Sample counts:"')
get_ipython().system('echo "no_filtering" $(grep -m1 "^#OTU" denoising/feature_tables/feature-table.from_biom.txt | tr "\\t" "\\n" | grep -cv "^#")')
get_ipython().system('echo "remove_samples_with_low_read_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_1/*/data/sample-frequency-detail.csv | cut -d\' \' -f1)')
get_ipython().system('echo "remove_features_with_low_read_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_2/*/data/sample-frequency-detail.csv | cut -d\' \' -f1)')
get_ipython().system('echo "remove_features_with_low_sample_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_3/*/data/sample-frequency-detail.csv | cut -d\' \' -f1)')
get_ipython().system('echo "remove_samples_with_low_feature_count" $(wc -l read_feature_and_sample_filtering/feature_tables/rpt_4/*/data/sample-frequency-detail.csv | cut -d\' \' -f1)')


# <h3 id="3.6&nbsp;&nbsp;Biological-replicates">3.6&nbsp;&nbsp;Biological replicates</h3>

# Paired duplicates, for the purposes of this pipeline, are defined by an identical "ExternalID."  The taxonomic classification (using the SILVA 99% OTUs database) at levels 2 through 7 are compared across each pair and evaluated using cosine similarity.  The closer the cosine similarity value is to 1, the more similar the vectors are.  Note that this comparison uses the taxonomic classification prior to removal of non-bacterial reads.

# In[ ]:


manifest_no_blanks = manifest[~manifest.index.str.contains('|'.join(['Water','NTC']),case=False)]
if 'externalid' in manifest_no_blanks.columns:
    dup1_sample = list(manifest_no_blanks[manifest_no_blanks.duplicated(subset='externalid', keep='first')].sort_values('externalid').index)
    dup2_sample = list(manifest_no_blanks[manifest_no_blanks.duplicated(subset='externalid', keep='last')].sort_values('externalid').index)
    l = dup1_sample + dup2_sample
else:
    print("No External ID column detected in manifest.")


# In[ ]:


def compare_replicates(f,l):
    df = pd.read_csv(f[0])
    df = df.rename(columns = {'index':'Sample'})
    df = df.set_index('Sample')
    df_dups = df[df.index.isin(l)]
    df_dups = df_dups.select_dtypes(['number']).dropna(axis=1, how='all')
    return df_dups


# In[ ]:


from scipy.spatial.distance import cosine


# In[ ]:


ids_list = []
if 'externalid' in manifest_no_blanks.columns:
    for a, b in zip(dup1_sample, dup2_sample):
        ids = [manifest.loc[a,'externalid'], a, b]
        ids_list.append(ids)
    df_cosine = pd.DataFrame(ids_list, columns=['externalid','replicate_1','replicate_2'])

    levels = [2,3,4,5,6,7]
    for n in levels:
        cos_list = []
        f = glob.glob('taxonomic_classification/rpt_silva/*/data/level-' + str(n) + '.csv')
        df_dups = compare_replicates(f, l)
        for a, b in zip(dup1_sample, dup2_sample):
            cos_list.append(1 - cosine(df_dups.loc[a,],df_dups.loc[b,]))
        df_cosine['level_' + str(n)] = cos_list
    display(df_cosine)


# In[ ]:


if 'externalid' in manifest_no_blanks.columns:
    if (df_cosine.drop(columns=['externalid','replicate_1','replicate_2']) < 0.99 ).any().any():
        print("Some biological replicates have cosine similarity below 0.99.")
    else:
        print("At all levels of taxonomic classification, the biological replicate samples have cosine similarity of at least 0.99.")


# <h3 id="3.7&nbsp;&nbsp;QC-samples">3.7&nbsp;&nbsp;QC samples</h3>

# If robogut and/or artificial colony samples are included in the analysis, then the distributions of relative abundances in each sample at classification levels 2 through 6 are shown here.  This illustrates the variability between samples within each QC population with regard to taxonomic classification.  Note that this section uses the taxonomic classification prior to removal of non-bacterial reads.

# In[ ]:


ac_samples = []
rg_samples = []
if 'sampletype' in manifest.columns:
    ac_samples = list(manifest[manifest['sampletype'].str.lower().isin(['artificialcolony','artificial colony'])].index)
    rg_samples = list(manifest[manifest['sampletype'].str.lower().isin(['robogut'])].index)
else:
    print("No Sample Type column detected in manifest.")


# In[ ]:


def plot_rel_abundances_in_QCs(samples,qc_pop):
    levels = [2,3,4,5,6]
    for n in levels:
        f = glob.glob('taxonomic_classification/rpt_silva/*/data/level-' + str(n) + '.csv')
        df = pd.read_csv(f[0],index_col=0)
        df = df[df.index.isin(samples)]
        df = df.select_dtypes(['number']).dropna(axis=1, how='all').loc[:,~(df==0.0).all(axis=0)]
        df_rel = df.div(df.sum(axis=1), axis=0) * 100
        plt.figure(dpi=150) 
        ax = df_rel.boxplot()
        ax.set_xticklabels(ax.get_xticklabels(),rotation=90,fontsize=8)
        ax.set_title('Distribution of relative abundances in ' + qc_pop + ', level ' + str(n))
        plt.show()


# In[ ]:


if ac_samples:
    plot_rel_abundances_in_QCs(ac_samples,'artificial colony')
else:
    print("No artificial colony samples were included in this pipeline run.")


# In[ ]:


if rg_samples:
    plot_rel_abundances_in_QCs(rg_samples,'robogut')
else:
    print("No robogut samples were included in this pipeline run.")


# <h2 id="4&nbsp;&nbsp;Rarefaction-threshold">4&nbsp;&nbsp;Rarefaction threshold</h2>

# QIIME randomly subsamples the reads per sample, without replacement, up to the sampling depth parameter.  Samples with reads below the sampling depth are excluded from analysis.  A higher sampling depth will include more reads overall, but will also exclude more samples.
# 
# Our default sampling depth is 10,000, which is the setting for the initial pipeline run (`<datestamp>_initial_run`).  The information provided in this section may be used to fine tune the sampling depth for subsequent runs.

# In[ ]:


get_ipython().system('unzip -q -d bacteria_only/feature_tables/rpt_merged_{ref_db}_qzv bacteria_only/feature_tables/merged_{ref_db}.qzv')


# In[ ]:


df_features_per_samples = pd.read_csv(glob.glob('bacteria_only/feature_tables/rpt_merged_' + ref_db + '_qzv/*/data/sample-frequency-detail.csv')[0],sep=",",header=None,index_col=0)
if 'externalid' in manifest.columns:
    df_features_per_samples = df_features_per_samples.join(manifest[['externalid']]).set_index('externalid')
sample_ttl = len(df_features_per_samples.index)
feature_ttl = df_features_per_samples[1].sum()
blank_ttl = len(df_features_per_samples[df_features_per_samples.index.str.contains('Water|NTC',case=False)])
values = [5000,10000,15000,20000,25000,30000,35000,40000]
samples = []
features = []
blanks = []
ids = []
for n in values:
    df_temp = df_features_per_samples[df_features_per_samples[1] > n]
    l = df_features_per_samples[df_features_per_samples[1] <= n].index.to_list()
    l.sort()
    ids.append(l)
    samples_left = len(df_temp.index)
    blanks_left = len(df_temp[df_temp.index.str.contains('Water|NTC',case=False)])
    samples.append(samples_left/sample_ttl * 100)
    features.append((samples_left * n)/feature_ttl * 100)
    if blank_ttl != 0:
        blanks.append(blanks_left/blank_ttl * 100)
    else:
        blanks.append("NA")
df_rarify = pd.DataFrame(list(zip(values, samples, features, ids, blanks)),columns=['Sampling_depth','Percent_retained_samples','Percent_retained_seqs','Samples_excluded','Percent_retained_blanks'])
df_rarify = df_rarify.set_index('Sampling_depth')
pd.set_option('display.max_colwidth', 0)
df_rarify[['Samples_excluded','Percent_retained_samples','Percent_retained_blanks']]


# In[ ]:


df_rarify_tidy = df_rarify.reset_index().drop(columns=['Samples_excluded','Percent_retained_blanks']).melt(id_vars='Sampling_depth')
df_rarify_tidy.columns = ['Sampling_depth','Var','Percent_retained']
df_rarify_tidy['Var'] = df_rarify_tidy['Var'].str.replace('Percent_retained_s','S')
plt.figure(dpi=120)
plt.rcParams["xtick.labelsize"] = 12
ax = sns.lineplot(x="Sampling_depth", y="Percent_retained", hue="Var",data=df_rarify_tidy)
handles, labels = ax.get_legend_handles_labels()
ax.legend(handles=handles[1:], labels=labels[1:], loc='center left', bbox_to_anchor=(1, 0.5))
plt.show()


# For this pipeline run, the rarefaction depth was set in the config file as follows:

# In[ ]:


get_ipython().system('grep "sampling_depth" *.yml')


# <h2 id="5&nbsp;&nbsp;Alpha-diversity">5&nbsp;&nbsp;Alpha diversity</h2>

# Alpha diversity measures species richness, or variance within a sample.  
# 
# The rarefaction curves below show the number of species as a function of the number of samples.  The various plots are stratified by the metadata available in the manifest.  The curves are expected to grow rapidly as common species are identified, then plateau as only the rarest species remain to be sampled.  The rarefaction threshold discussed above should fall within the plateau of the rarefaction curves.
# 
# This report provides the following alpha diversity metrics:
# - __Observed OTUs:__ represents the number of observed species for each class
# - __Shannon diversity index:__ Calculates richness and diversity using a natural logarithm; accounts for both abundance and evenness of the taxa present; more sensitive to species richness than evenness
# - __Faith's phylogenetic diversity:__ Measure of biodiversity that incorporates phylogenetic difference between species via sum of length of branches
# 
# Note that while the phylogenetic tree is constructed including non-bacterial reads, alpha diversity analysis is performed after non-bacterial read exclusion.

# In[ ]:


get_ipython().system('unzip -q -d diversity_core_metrics/{ref_db}/rpt_rarefaction diversity_core_metrics/{ref_db}/rarefaction.qzv')


# In[ ]:


def format_alpha_data(metric, csv):
    df = pd.read_csv(csv,index_col=0)
    df.columns = map(str.lower, df.columns)
    depth_cols = [col for col in df.columns if 'depth-' in col]
    non_depth_cols = [col for col in df.columns if 'depth-' not in col]
    depths = list(set([i.split('_', 1)[0] for i in depth_cols]))
    iters = list(set([i.split('_', 1)[1] for i in depth_cols]))
    df_melt1 = pd.DataFrame()
    df_melt2 = pd.DataFrame()
    for d in depths:
        df_temp = df.filter(regex=d+'_')
        df_temp.columns = iters
        df_temp = pd.concat([df_temp,df[non_depth_cols]],axis=1)
        df_temp['depth'] = int(d.split('-')[1])
        df_melt1 = pd.concat([df_melt1,df_temp],axis=0)
    non_depth_cols.append('depth')
    for i in iters:
        df_temp = df_melt1.filter(regex='^' + i + '$')
        df_temp.columns = [metric]
        df_temp = pd.concat([df_temp,df_melt1[non_depth_cols]],axis=1)
        df_temp['iteration'] = int(i.split('-')[1])
        df_melt2 = pd.concat([df_melt2,df_temp],axis=0)
    return df_melt2


# In[ ]:


mpl.rcParams['figure.max_open_warning'] = 40
files = glob.glob('diversity_core_metrics/' + ref_db + '/rpt_rarefaction/*/data/*.csv')
for f in files:
    b = os.path.basename(f).split('.')[0]
    df = format_alpha_data(b, f)
    df.columns = df.columns.str.replace(' ', '')  # temporary - remove once cleaning is implemented in the pipeline
    if len(manifest['run-id'].astype(str).str.split('_',n=2,expand=True).columns) > 1:
        df['Sequencer'] = (df['run-id'].astype(str).str.split('_',n=2,expand=True))[1]
        df['run-id'] = (df['run-id'].astype(str).str.split('-',expand=True)[1])
    if 'sourcepcrplate' in df.columns:
        df['PCR_plate'] = (df['sourcepcrplate'].str.split('_',n=1,expand=True))[0]
    # should probably save this file, or even better, include in original manifest prior to analysis....
    cols = df.columns.drop([b,'depth','iteration','sourcepcrplate','externalid','extractionbatchid','fq1','fq2'],errors='ignore')
    for c in cols:
        plt.figure(dpi=130)
        ax = sns.lineplot(x="depth", y=b, hue=c, err_style="band", data=df)
        handles, labels = ax.get_legend_handles_labels()
        ax.legend(handles=handles[1:], labels=labels[1:], loc='center left', bbox_to_anchor=(1, 0.5))
        ax.set_title('Rarefaction curves by ' + c)
plt.show()


# <h2 id="6&nbsp;&nbsp;Beta-diversity">6&nbsp;&nbsp;Beta diversity</h2>

# The data displayed here is mainly for use in evaluating potential confounders (e.g. flow cell, sequencer, etc.).  For convenience, we have included the PCoA plots for all metadata provided; however, we strongly encourage the use of [EMPeror](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4076506/), available through [QIIME's viewer](https://view.qiime2.org/), for further project analysis.
# 
# Beta diversity measures variance across samples/environments.  
# 
# The three-axis plots below show PCoA results for the first three components of several beta diversity metrics.  Percent variance explained is displayed on each axis.  This report provides the following beta diversity metrics:
# - __Bray-Curtis dissimilarity:__ Fraction of overabundant counts; creates a matrix of the differences in microbial abundances between two samples (0 indicates that the samples share the same species at the same abundances, 1 indicates that both samples have completely different species and abundances)
# - __Jaccard similarity index:__ Fraction of unique features, regardless of abundance
# - __Unweighted UniFrac:__ Measures the phylogenetic distance between sets of taxa in a phylogenetic tree as the fraction of unique branch length
# - __Weighted UniFrac:__ Same as above, but takes into account the relative abundance of each of the taxa
# 
# Beta diversity analysis is performed after non-bacterial read exclusion.

# In[ ]:


get_ipython().system('unzip -q -d diversity_core_metrics/{ref_db}/rpt_bray-curtis_dist diversity_core_metrics/{ref_db}/bray-curtis_dist.qza')
get_ipython().system('unzip -q -d diversity_core_metrics/{ref_db}/rpt_weighted_dist diversity_core_metrics/{ref_db}/weighted_dist.qza')
get_ipython().system('unzip -q -d diversity_core_metrics/{ref_db}/rpt_unweighted_dist diversity_core_metrics/{ref_db}/unweighted_dist.qza')
get_ipython().system('unzip -q -d diversity_core_metrics/{ref_db}/rpt_jaccard_dist diversity_core_metrics/{ref_db}/jaccard_dist.qza')


# In[ ]:


if len(manifest['run-id'].astype(str).str.split('_',n=2,expand=True).columns) > 1:
    m['Sequencer'] = (manifest['run-id'].astype(str).str.split('_',n=2,expand=True))[1]
    m['run-id'] = (manifest['run-id'].astype(str).str.split('-',expand=True)[1])
else:
    print("Can not infer sequencer ID from run ID.")
if 'sourcepcrplate' in manifest.columns:
    m['PCR_plate'] = (manifest['sourcepcrplate'].str.split('_',n=1,expand=True))[0]
m.fillna('na', inplace=True)
# should probably save this file, or even better, include in original manifest prior to analysis....


# In[ ]:


import warnings
warnings.filterwarnings("ignore", message="The result contains negative eigenvalues. Please compare their magnitude with the magnitude of some of the largest positive eigenvalues")
# NOTE: without this filter, pcoa plotting may generate runtime warning messages like the following:
    # /Users/ballewbj/anaconda3/lib/python3.7/site-packages/skbio/stats/ordination/_principal_coordinate_analysis.py:152: 
    # RuntimeWarning: The result contains negative eigenvalues. Please compare their magnitude with the magnitude of some 
    # of the largest positive eigenvalues. If the negative ones are smaller, it's probably safe to ignore them, but if 
    # they are large in magnitude, the results won't be useful. See the Notes section for more details. The smallest 
    # eigenvalue is -0.41588455816214936 and the largest is 9.807175722836307.
    # RuntimeWarning
# This warning is explained in detail here: https://github.com/biocore/scikit-bio/issues/1410


# In[ ]:


def plot_pcoas(metric):
    mpl.rcParams['figure.dpi'] = 100
    mpl.rcParams['figure.figsize'] = 9, 6
    df = pd.read_csv(glob.glob('diversity_core_metrics/' + ref_db + '/rpt_' + metric + '_dist/*/data/distance-matrix.tsv')[0],sep='\t',index_col=0)
    sample_ids = df.index.values
    dist = df.to_numpy()
    dm = DistanceMatrix(dist, sample_ids)
    pc = pcoa(dm)
    var1 = str(round(pc.proportion_explained[0]*100, 2))
    var2 = str(round(pc.proportion_explained[1]*100, 2))
    var3 = str(round(pc.proportion_explained[2]*100, 2))
    for i in m.columns:
        ax = pc.plot(m, i, cmap='Accent', axis_labels=('PC1, '+var1+'%', 'PC2, '+var2+'%', 'PC3, '+var3+'%'), title= metric + " PCoA colored by " + i)


# <h3 id="6.1&nbsp;&nbsp;Bray-Curtis">6.1&nbsp;&nbsp;Bray-Curtis</h3>

# In[ ]:


plot_pcoas('bray-curtis')


# <h3 id="6.2&nbsp;&nbsp;Jaccard">6.2&nbsp;&nbsp;Jaccard</h3>

# In[ ]:


plot_pcoas('jaccard')


# <h3 id="6.3&nbsp;&nbsp;Weighted-UniFrac">6.3&nbsp;&nbsp;Weighted UniFrac</h3>

# In[ ]:


plot_pcoas('weighted')


# <h3 id="6.4&nbsp;&nbsp;Unweighted-UniFrac">6.4&nbsp;&nbsp;Unweighted UniFrac</h3>

# In[ ]:


plot_pcoas('unweighted')


# In[ ]:


get_ipython().run_line_magic('rm', '-r */rpt_* */*/rpt_*')


# In[ ]:




