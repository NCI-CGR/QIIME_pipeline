#! /usr/bin/env python3

"""CGR QIIME2 pipeline for microbiome analysis.

AUTHORS:
    S. Sevilla Chill
    B. Ballew

This pipeline uses the QIIME2 suite to classify sequence data,
calculate relative abundance, and (eventually) perform alpha- and beta-
diversity analysis.

Input requirements:
    - Manifest file
        - First X columns are required as shown here:
            #SampleID       External-ID     Sample-Type     Source-Material
            Source-PCR-Plate        Run-ID  Project-ID      Reciept Sample_Cat
            SubjectID       Sample_Aliquot  Ext_Company     Ext_Kit Ext_Robot
            Homo_Method     Homo-Holder     Homo-Holder2    AFA Setting1
            AFA Setting2    Extraction Batch        Residual or Original
            Row     Column
    - config.yaml
    - (for production runs) run_pipeline.sh


Options to run the pipeline (choose one):

    A. Production run: Copy the run_pipeline.sh script to your
    directory and edit as needed, then execute that script.

    B. For dev/testing only: Run the snakefile directly, e.g.:
        module load perl/5.18.0 python3/3.6.3 miniconda/3
        source activate qiime2-2017.11
        conf=${PWD}/config.yml snakemake -s /path/to/pipeline/Snakefile
"""

import os
import re

# reference the config file
conf = os.environ.get("conf")
configfile: conf

# import variables from the config file
# TODO: write some error checking for the config file
meta_man_fullpath = config['metadata_manifest']
out_dir = config['out_dir'].rstrip('/') + '/'
out_dir = out_dir + 'QIIME2/'
exec_dir = config['exec_dir'].rstrip('/') + '/'
fastq_abs_path = config['fastq_abs_path'].rstrip('/') + '/'
qiime_version = config['qiime_version']  # not yet implemented - offer support for multiple Q2 versions, but will need to enforce use of only the versions we've tested
demux_param = config['demux_param']
input_type = config['input_type']
phred_score = config['phred_score']
denoise_method = config['denoise_method']  # not yet implemented - space-holder for adding additional denoise software options
if denoise_method in ['dada2', 'DADA2']:
    trim_left_f = config['dada2_denoise']['trim_left_forward']
    trim_left_r = config['dada2_denoise']['trim_left_reverse']
    trunc_len_f = config['dada2_denoise']['truncate_length_forward']
    trunc_len_r = config['dada2_denoise']['truncate_length_reverse']

sym_link_path = out_dir + 'fastqs/'

"""Parse manifest to set up sample IDs and other info

The manifest for CGR-generated data is largely automated via
LIMS.  External data will require a similarly-set up manifest
for this pipeline.

Samples must be associated with their run ID (aka flowcell) because
DADA2 requires analyses to occur on a per-flowcell basis.

Both run ID and project ID are required to generate the absolute
path to the fastq files (see get_orig_r*_fastq functions).

Note that run ID and project ID are currently being pulled from
the manifest based on column order.  If column order is subject to
change, we may want to pull based on column header.
"""
sampleDict = {}
RUN_IDS = []
with open(meta_man_fullpath) as f:
    next(f)
    for line in f:
        l = line.split('\t')
        if l[0] in sampleDict.keys():
            sys.exit('ERROR: duplicate sample IDs detected in' + meta_man_fullpath)
        sampleDict[l[0]] = (l[5], l[6])  # runID, projID
        RUN_IDS.append(l[5])
RUN_IDS = list(set(RUN_IDS))


def get_orig_r1_fq(wildcards):
    '''Return original R1 fastq with path based on filename

    Note there are some assumptions here (files always end with
    R1_001.fastq.gz; only one R1 fq per directory).  Same for
    following function.  This assumption should hold true even
    for historic projects, which had seq or extraction duplicates
    run in new folders.

    Note that assembling the absolute path to a fastq is a bit
    complex; however, this pattern is automatically generated
    and not expected to change in the forseeable future.
    '''
    (runID, projID) = sampleDict[wildcards.sample]
    p = fastq_abs_path + runID + '/CASAVA/L1/Project_' + projID + '/Sample_' + wildcards.sample + '/'
    file = [f for f in os.listdir(p) if f.endswith('R1_001.fastq.gz')]
    if len(file) != 1:
        sys.exit('ERROR: More than one R1 fastq detected in ' + p)
    return p + file[0]


def get_orig_r2_fq(wildcards):
    '''Return original R2 fastq with path based on filename
    See above function for more detail.
    '''
    (runID, projID) = sampleDict[wildcards.sample]
    p = fastq_abs_path + runID + '/CASAVA/L1/Project_' + projID + '/Sample_' + wildcards.sample + '/'
    file = [f for f in os.listdir(p) if f.endswith('R2_001.fastq.gz')]
    if len(file) != 1:
        sys.exit('ERROR: More than one R2 fastq detected in ' + p)
    return p + file[0]


rule all:
    input:
        expand(sym_link_path + '{sample}_R1.fastq.gz', sample=sampleDict.keys()),
        expand(sym_link_path + '{sample}_R2.fastq.gz', sample=sampleDict.keys()),
        out_dir + 'manifests/manifest_qiime2.tsv',
        # expand(out_dir + 'manifests/{runID}_Q2_manifest.txt',runID=RUN_IDS),
        # expand(out_dir + 'qza_results/demux/{runID}_' + demux_param + '.qza',runID=RUN_IDS),
        expand(out_dir + 'qzv_results/demux/{runID}_' + demux_param + '.qzv',runID=RUN_IDS),
        expand(out_dir + 'qza_results/table/{runID}_' + demux_param + '.qza',runID=RUN_IDS),
        expand(out_dir + 'qza_results/repseq/{runID}_' + demux_param + '.qza',runID=RUN_IDS)#,
        # proj_dir + 'qza_results/table/final_' + demux_param + '.qza',
        # proj_dir + 'qza_results/repseq/final_' + demux_param + '.qza',

# if report only = no
    # include: Snakefile_q2

# include: Snakefile_report

# TODO: think about adding check for minimum reads count per sample per flow cell (need more than 1 sample per flow cell passing min threshold for tab/rep seq creation) - either see if we can include via LIMS in the manifest, or use samtools(?)

rule check_manifest:
    '''Check manifest for detailed character/format Q2 reqs

    QIIME2 has very explicit requirements for the manifest file.
    This step helps to enforce those requirements by either correcting
    simple deviations or exiting with informative errors prior to
    attempts to start QIIME2-based analysis steps.

    NOTE: this manifest is currently not used anywhere.  ?
    '''
    input:
        meta_man_fullpath
    output:
        out_dir + 'manifests/manifest_qiime2.tsv'
    params:
        o = out_dir,
        e = exec_dir
    shell:
        # 'source /etc/profile.d/modules.sh; module load perl/5.18.0;'
        'perl {params.e}Q2Manifest.pl {params.o} {input} {output}'

rule create_per_sample_Q2_manifest:
    '''Create a QIIME2-specific manifest file per-sample

    Q2 needs a manifest in the following format:
        sample-id,absolute-filepath,direction

    Note that these per-sample files will be combined on a per-run ID
    basis in the following step, in keeping with the DADA2 requirement
    to group samples by flow cell (run ID).
    '''
    input:
        fq1 = get_orig_r1_fq,
        fq2 = get_orig_r2_fq
    output:
        temp(out_dir + 'manifests/{sample}_Q2_manifest.txt')
    shell:
        'echo "{wildcards.sample},{input.fq1},forward" > {output};'
        'echo "{wildcards.sample},{input.fq2},reverse" >> {output}'

rule combine_Q2_manifest_by_runID:
    '''Combine Q2-specific manifests by run ID

    NOTE: This step will only be scalable to a certain extent.
    Given enough samples, you will hit the cli character limit when
    using cat {input}.  If projects exceed a reasonable size, refactor
    here.
    '''
    input:
        expand(out_dir + 'manifests/{sample}_Q2_manifest.txt', sample=sampleDict.keys())
    output:
        out_dir + 'manifests/{runID}_Q2_manifest.txt'
    shell:
        'cat {input} | awk \'BEGIN{{FS=OFS="/"}}NR==1{{print "sample-id,absolute-filepath,direction"}}$9=="{wildcards.runID}"{{print $0}}\' > {output}'

rule create_symlinks:
    '''Symlink the original fastqs in an area that PIs can access

    TODO: Note that I've changed the directory structure from an earlier
    version.  Update documentation.
    '''
    input:
        fq1 = get_orig_r1_fq,
        fq2 = get_orig_r2_fq
    output:
        sym1 = sym_link_path + '{sample}_R1.fastq.gz',
        sym2 = sym_link_path + '{sample}_R2.fastq.gz'
    shell:
        'ln -s {input.fq1} {output.sym1};'
        'ln -s {input.fq2} {output.sym2}'

rule demux_summary_qza:
    '''
    Why did the bash script name things via runID instead of sample? SS: DADA2 requirement
    RunID pulls up multiple pairs of fastqs.  Are they meant to be combined? SS: Yes
    If they are, can we just combine at the fastq level?
    Does Q2 somehow combine everything in a given manifest, and that's the problem?
    Simple enough to create multiple manifests.

    If data is multiplexed, this step would de-~.  But, our data is already demultiplexed.
    provdes summaries and plots per flow cell (as QZA - not human-readable).

    SS: QZA files are artifacts that contain the QIIME2 parameters that were used within the pipeline being run. They
    would theoretically allow you to repeat parts of the pipeline if you didn't have a workflow or documentation

    Next step converts to QZV - human readable.
    '''
    input:
        out_dir + 'manifests/{runID}_Q2_manifest.txt'
    output:
        out_dir + 'qza_results/demux/{runID}_' + demux_param + '.qza'
    params:
        q2 = qiime_version,
        demux_param = demux_param,
        i_type = input_type,
        phred = phred_score
    # conda:
    #     'envs/qiime2-2017.11.yaml'
    shell:
        # 'source activate qiime2-2017.11;'
        'qiime tools import \
            --type {params.i_type} \
            --input-path {input}\
            --output-path {output}\
            --source-format PairedEndFastqManifestPhred{params.phred}'

rule demux_summary_qzv:
    '''

    '''
    input:
        out_dir + 'qza_results/demux/{runID}_' + demux_param + '.qza'
    output:
        out_dir + 'qzv_results/demux/{runID}_' + demux_param + '.qzv'
    params:
        q2 = qiime_version,
        demux_param = demux_param
    # conda:
    #     'envs/qiime2-2017.11.yaml'
    shell:
        # 'source activate qiime2-2017.11;'
        'qiime demux summarize \
            --i-data {input}\
            --o-visualization {output}'

rule table_repseqs_qza:
    '''
    Generates feature tables and feature sequences. Each feature in the table is represented by one sequence (joined paired-end).
    QIIME 2017.10 does not require that both the table and sequences are generated in one step, however, QIIME 2019 does require
    they are generated together.

    SS: do we want to have the trimming be config features? We are giving it already demultiplexed data, so we don't need to trim
    but if PI's are using on external data, we may want to add that feature.
    '''
    input:
        out_dir + 'qza_results/demux/{runID}_' + demux_param + '.qza'
    output:
        tab = out_dir + 'qza_results/table/{runID}_' + demux_param + '.qza',
        seq = out_dir + 'qza_results/repseq/{runID}_' + demux_param + '.qza'
    params:
        q2 = qiime_version,
        demux_param = demux_param,
        trim_l_f = trim_left_f,
        trim_l_r = trim_left_r,
        trun_len_f = trunc_len_f,
        trun_len_r = trunc_len_r
    shell:
        # 'source activate qiime2-2017.11;'
        'qiime dada2 denoise-paired\
            --i-demultiplexed-seqs {input} \
            --o-table {output.tab} \
            --o-representative-sequences {output.seq} \
            --p-trim-left-f {params.trim_l_f} \
            --p-trim-left-r {params.trim_l_r} \
            --p-trunc-len-f {params.trun_len_f} \
            --p-trunc-len-r {params.trun_len_r}'

# rule table_merge_qza
#     '''
#     SS: Future qiime2 versions allow for mutliple tables/repseqs to be given at
#     one time, however, this version does not allow this and one must be given at
#     a time. Once upgrading occurs, we can eliminate the sh script entirely and example
#     below can be used
#     '''
#     ##Example updated code
#     ###https://docs.qiime2.org/2017.12/plugins/available/feature-table/merge/
#     #input:
#     #    expand(proj_dir + 'qza_results/demux/{runID}_' + demux_param + '.qza',runID=RUN_IDS)
#     #output:
#     #    proj_dir + 'qza_results/table/final_' + demux_param + '.qza',
#     #params:
#     #    q2 = qiime_version,
#     #    demux_param = demux_param
#     #shell:
#     #    'source activate qiime2-2017.11;'
#     #    'qiime feature-table merge \
#     #        --i-tables {input} \
#     #        --o-merged-table {output}'

#     input:
#         proj_dir + 'qza_results/table/{runID}_' + demux_param + '.qza',
#     output:
#         proj_dir + 'qza_results/table/final_' + demux_param + '.qza',
#     params:
#         q2 = qiime_version,
#         demux_param = demux_param,
#         tab_dir = directory( proj_dir + 'qza_results/table/')
#     shell:
#         'table_merge.sh {params.tab_dir} {output}'

#     # pairwise merging only - can you merge with an empty qza? what about merging with self?
#     input:
#         proj_dir + 'qza_results/table/{runID}_' + demux_param + '.qza'
#     output:
#         proj_dir + 'qza_results/table/final_' + demux_param + '.qza'
#     params:
#         q2 = qiime_version
#     shell:
#         'touch {output}; qiime feature-table merge --i-table1 {input} --i-table2 {output} --o-merged-table {output}'



# rule repseq_merge_qza
#     '''
#     SS: Future qiime2 versions allow for mutliple tables/repseqs to be given at
#     one time, however, this version does not allow this and one must be given at
#     a time. Once upgrading occurs, we can eliminate the sh script entirely and example
#     below can be used
#     '''
#     ##Example updated code
#     ###https://docs.qiime2.org/2017.12/plugins/available/feature-table/merge/
#     #input:
#     #    expand(proj_dir + 'qza_results/demux/{runID}_' + demux_param + '.qza',runID=RUN_IDS)
#     #output:
#     #    proj_dir + 'qza_results/repseq/final_' + demux_param + '.qza'
#     #params:
#     #    q2 = qiime_version,
#     #    demux_param = demux_param
#     #shell:
#     #    'source activate qiime2-2017.11;'
#     #    'qiime feature-table merge-seqs \
#     #        --i-data {input} \
#     #        --o-merged-data {output}'

#     input:
#         proj_dir + 'qza_results/repseq/{runID}_' + demux_param + '.qza'
#     output:
#         proj_dir + 'qza_results/repseq/final_' + demux_param + '.qza'
#     params:
#         q2 = qiime_version,
#         demux_param = demux_param,
#         rep_dir = directory( proj_dir + 'qza_results/repseqs/')
#     shell:
#         'rep_merge.sh {params.rep_dir} {output}'
