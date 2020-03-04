#!/usr/bin/env python3

"""CGR QIIME2 pipeline for microbiome analysis.

AUTHORS:
    S. Sevilla Chill
    W. Zhou
    B. Ballew
    Y. Wan

This pipeline uses the QIIME2 suite to classify sequence data,
calculate relative abundance, and (eventually) perform alpha- and beta-
diversity analysis.

INPUT:
    - Manifest file
        - First X columns are required as shown here:  # TODO: update.
            #SampleID       External-ID     Sample-Type     Source-Material
            Source-PCR-Plate        Run-ID  Project-ID      Reciept Sample_Cat
            SubjectID       Sample_Aliquot  Ext_Company     Ext_Kit Ext_Robot
            Homo_Method     Homo-Holder     Homo-Holder2    AFA Setting1
            AFA Setting2    Extraction Batch        Residual or Original
            Row     Column
    - config.yaml
    - (for production runs) run_pipeline.sh

TO RUN (choose one):

    A. Production run: Copy the run_pipeline.sh script to your
    directory and edit as needed, then execute that script.

    B. For dev/testing: Run the snakefile directly, e.g.:
        module load perl/5.18.0 miniconda/3 python3/3.6.3  # miniconda3 has python 3.5.4 but not snakemake
        source activate qiime2-2017.11  # or 2019.1
        conf=${PWD}/config.yml snakemake -s /path/to/pipeline/Snakefile
"""

import os
import re
import subprocess
import sys

# reference the config file
conf = os.environ.get("conf")
configfile: conf

# import variables from the config file
# TODO: write some error checking for the config file
cgr_data = True if config['data_source'] == 'internal' else False
fastq_abs_path = config['fastq_abs_path'].rstrip('/') + '/' if cgr_data else ''
meta_man_fullpath = config['metadata_manifest']
out_dir = config['out_dir'].rstrip('/') + '/'
exec_dir = config['exec_dir'].rstrip('/') + '/'
qiime2_version = config['qiime2_version']
Q2_2017 = True if qiime2_version == '2017.11' else False
demux_param = config['demux_param']
input_type = config['input_type']
phred_score = config['phred_score']
filt_min = config['filt_param']
sampling_depth = config['sampling_depth']
max_depth = config['max_depth']
classify_method = config['classify_method']
REF_DB = config['reference_db']
denoise_method = config['denoise_method']
if denoise_method in ['dada2', 'DADA2']:
    trim_left_f = config['dada2_denoise']['trim_left_forward']
    trim_left_r = config['dada2_denoise']['trim_left_reverse']
    trunc_len_f = config['dada2_denoise']['truncate_length_forward']
    trunc_len_r = config['dada2_denoise']['truncate_length_reverse']
    min_fold = config['dada2_denoise']['min_fold_parent_over_abundance']


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

Use pandas?
"""
sampleDict = {}
RUN_IDS = []
runID = ''
with open(meta_man_fullpath) as f:
    header = f.readline().rstrip().split('\t') 
    try:
        runID = header.index('Run-ID')
        projID = header.index('Project-ID')
        if cgr_data is False:
            fq1 = header.index('fq1')
            fq2 = header.index('fq2')
    except ValueError:
        if cgr_data:
            sys.exit('ERROR: Manifest file ' + meta_man_fullpath + ' must contain headers Run-ID and Project-ID')
        else:
            sys.exit('ERROR: Manifest file ' + meta_man_fullpath + ' must contain headers Run-ID, Project-ID, fq1, and fq2')
    for line in f:
        l = line.rstrip().split('\t')
        if l[0] in sampleDict.keys():
            sys.exit('ERROR: Duplicate sample IDs detected in ' + meta_man_fullpath)
        if cgr_data is True:
            sampleDict[l[0]] = (l[runID], l[projID])  # SampleID, Run-ID, Project-ID
        else:
            sampleDict[l[0]] = (l[runID], l[projID], l[fq1], l[fq2])
        RUN_IDS.append(l[runID])
RUN_IDS = list(set(RUN_IDS))


def get_orig_r1_fq(wildcards):
    """Return original R1 fastq with path based on filename

    Note there are some assumptions here (files always end with
    R1_001.fastq.gz; only one R1 fq per directory).  Same for
    following function.  This assumption should hold true even
    for historic projects, which had seq or extraction duplicates
    run in new folders.

    Note that assembling the absolute path to a fastq is a bit
    complex; however, this pattern is automatically generated
    and not expected to change in the forseeable future.
    """
    (runID, projID) = sampleDict[wildcards.sample]
    p = fastq_abs_path + runID + '/CASAVA/L1/Project_' + projID + '/Sample_' + wildcards.sample + '/'
    file = [f for f in os.listdir(p) if f.endswith('R1_001.fastq.gz')]
    if len(file) != 1:
        sys.exit('ERROR: More than one R1 fastq detected in ' + p)
    return p + file[0]


def get_orig_r2_fq(wildcards):
    """Return original R2 fastq with path based on filename
    See above function for more detail.
    """
    (runID, projID) = sampleDict[wildcards.sample]
    p = fastq_abs_path + runID + '/CASAVA/L1/Project_' + projID + '/Sample_' + wildcards.sample + '/'
    file = [f for f in os.listdir(p) if f.endswith('R2_001.fastq.gz')]
    if len(file) != 1:
        sys.exit('ERROR: More than one R2 fastq detected in ' + p)
    return p + file[0]


def get_external_r1_fq(wildcards):
    """
    """
    (runID, projID, fq1, fq2) = sampleDict[wildcards.sample]
    return fq1


def get_external_r2_fq(wildcards):
    """
    """
    (runID, projID, fq1, fq2) = sampleDict[wildcards.sample]
    return fq2


def get_internal_runID(wildcards):
    """
    """
    (runID, projID) = sampleDict[wildcards.sample]
    return runID


def get_external_runID(wildcards):
    """
    """
    (runID, projID, fq1, fq2) = sampleDict[wildcards.sample]
    return runID

refDict = {}
for i in REF_DB:
    refFile = os.path.basename(i)
    refNoExt = os.path.splitext(refFile)[0]
    refDict[refNoExt] = (i)


def get_ref_full_path(wildcards):
    """
    """
    (refFullPath) = refDict[wildcards.ref]
    return refFullPath


if denoise_method in ['dada2', 'DADA2'] and not Q2_2017:
    rule all:
        input:
            expand(out_dir + 'fastqs/' + '{sample}_R1.fastq.gz', sample=sampleDict.keys()),
            expand(out_dir + 'fastqs/' + '{sample}_R2.fastq.gz', sample=sampleDict.keys()),
            expand(out_dir + 'import_and_demultiplex/{runID}.qzv',runID=RUN_IDS),
            out_dir + 'denoising/feature_tables/merged_filtered.qzv',
            out_dir + 'denoising/sequence_tables/merged.qzv',
            out_dir + 'diversity_core_metrics/rareifed_table.qza',
            out_dir + 'diversity_core_metrics/alpha_diversity_metadata.qzv',
            out_dir + 'diversity_core_metrics/rarefaction.qzv',
            expand(out_dir + 'taxonomic_classification/' + classify_method + '_{ref}.qzv', ref=refDict.keys()),
            expand(out_dir + 'taxonomic_classification/barplots_' + classify_method + '_{ref}.qzv', ref=refDict.keys()),
            expand(out_dir + 'denoising/stats/{runID}.qzv', runID=RUN_IDS)  # has to be a more elegant way to do this.
else:
    rule all:
        input:
            expand(out_dir + 'fastqs/' + '{sample}_R1.fastq.gz', sample=sampleDict.keys()),
            expand(out_dir + 'fastqs/' + '{sample}_R2.fastq.gz', sample=sampleDict.keys()),
            expand(out_dir + 'import_and_demultiplex/{runID}.qzv',runID=RUN_IDS),
            out_dir + 'denoising/feature_tables/merged_filtered.qzv',
            out_dir + 'denoising/sequence_tables/merged.qzv',
            out_dir + 'diversity_core_metrics/rareifed_table.qza',
            out_dir + 'diversity_core_metrics/alpha_diversity_metadata.qzv',
            out_dir + 'diversity_core_metrics/rarefaction.qzv',
            expand(out_dir + 'taxonomic_classification/' + classify_method + '_{ref}.qzv', ref=refDict.keys()),
            expand(out_dir + 'taxonomic_classification/barplots_' + classify_method + '_{ref}.qzv', ref=refDict.keys())

# if report only = no
    # include: Snakefile_q2

# include: Snakefile_report

# TODO: think about adding check for minimum reads count per sample per flow cell (need more than 1 sample per flow cell passing min threshold for tab/rep seq creation) - either see if we can include via LIMS in the manifest, or use samtools(?)

rule check_manifest:
    """Check manifest for detailed character/format Q2 reqs

    QIIME2 has very explicit requirements for the manifest file.
    This step helps to enforce those requirements by either correcting
    simple deviations or exiting with informative errors prior to
    attempts to start QIIME2-based analysis steps.

    #TODO: assert column order/name requirements here?
    """
    input:
        meta_man_fullpath
    output:
        out_dir + 'manifests/manifest_qiime2.tsv'
    params:
        o = out_dir,
        e = exec_dir
    benchmark:
        out_dir + 'run_times/check_manifest/check_manifest.tsv'
    shell:
        # 'source /etc/profile.d/modules.sh; module load perl/5.18.0;'
        'dos2unix -n {input} {output};'
        'perl {params.e}Q2Manifest.pl {output}'

rule create_per_sample_Q2_manifest:
    """Create a QIIME2-specific manifest file per-sample

    Q2 needs a manifest in the following format:
        sample-id,absolute-filepath,direction

    Note that these per-sample files will be combined on a per-run ID
    basis in the following step, in keeping with the DADA2 requirement
    to group samples by flow cell (run ID).

    This step does not require the manifest_qiime2.tsv, but it's
    here so that this rule does not get run until the manifest
    check completes successfully.
    """
    input:
        fq1 = get_orig_r1_fq if cgr_data else get_external_r1_fq,
        fq2 = get_orig_r2_fq if cgr_data else get_external_r2_fq,
        man = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        temp(out_dir + 'manifests/{sample}_Q2_manifest.txt')
    params:
        runID = get_internal_runID if cgr_data else get_external_runID
    benchmark:
        out_dir + 'run_times/create_per_sample_Q2_manifest/{sample}.tsv'
    shell:
        'echo "{wildcards.sample},{input.fq1},forward,{params.runID}" > {output};' 
        'echo "{wildcards.sample},{input.fq2},reverse,{params.runID}" >> {output}'


rule combine_Q2_manifest_by_runID:
    """Combine Q2-specific manifests by run ID

    NOTE: This step will only be scalable to a certain extent.
    Given enough samples, you will hit the cli character limit when
    using cat {input}.  If projects exceed a reasonable size, refactor
    here.
    """
    input:
        expand(out_dir + 'manifests/{sample}_Q2_manifest.txt', sample=sampleDict.keys())
    output:
        out_dir + 'manifests/{runID}_Q2_manifest.txt'
    benchmark:
        out_dir + 'run_times/combine_Q2_manifest_by_runID/{runID}.tsv'
    shell:
        'cat {input} | awk \'BEGIN{{FS=OFS=","; print "sample-id,absolute-filepath,direction"}}$4=="{wildcards.runID}"{{print $1,$2,$3}}\' > {output}'

rule create_symlinks:
    """Symlink the original fastqs in an area that PIs can access

    Not strictly necessary for external data.
    """
    input:
        fq1 = get_orig_r1_fq if cgr_data else get_external_r1_fq,
        fq2 = get_orig_r2_fq if cgr_data else get_external_r2_fq
    output:
        sym1 = out_dir + 'fastqs/' + '{sample}_R1.fastq.gz',
        sym2 = out_dir + 'fastqs/' + '{sample}_R2.fastq.gz'
    benchmark:
        out_dir + 'run_times/create_symlinks/{sample}.tsv'
    shell:
        'ln -s {input.fq1} {output.sym1};'
        'ln -s {input.fq2} {output.sym2}'

rule import_fastq_and_demultiplex:
    """Import into qiime2 format and demultiplex
    Note that DADA2 requires samples to be grouped by run ID (flow cell).

    If data is multiplexed, this step would demultiplex.  Internally-
    generated CGR data is already demultiplexed, but runs through this
    step regardless.

    Summary files are created for each flowcell (run ID) in QZA format.
    QZA files are QIIME2 "artifacts" that contain the QIIME2 parameters
    used to run the current step of the pipeline, to track provenance.
    """
    input:
        out_dir + 'manifests/{runID}_Q2_manifest.txt'
    output:
        out_dir + 'import_and_demultiplex/{runID}.qza'
    params:
        in_type = input_type,
        phred = phred_score,
        cmd_flag = 'source-format' if Q2_2017 else 'input-format'
    benchmark:
        out_dir + 'run_times/import_fastq_and_demultiplex/{runID}.tsv'
    shell:
        'qiime tools import \
            --type {params.in_type} \
            --input-path {input} \
            --output-path {output} \
            --{params.cmd_flag} PairedEndFastqManifestPhred{params.phred}'

rule import_and_demultiplex_visualization:
    """ Conversion of QZA to QZV for QC summary
    Summarize counts per sample for all samples, and generate interactive
    positional quality plots based on `n` randomly selected sequences.

    Note: QZA files are converted to QZV files for visualization
    Viewable at www.view.qiime2.org
    """
    input:
        out_dir + 'import_and_demultiplex/{runID}.qza'
    output:
        out_dir + 'import_and_demultiplex/{runID}.qzv'
    benchmark:
        out_dir + 'run_times/import_and_demultiplex_visualization/{runID}.tsv'
    shell:
        'qiime demux summarize \
            --i-data {input} \
            --o-visualization {output}'

if denoise_method in ['dada2', 'DADA2']:
    if Q2_2017:
        rule dada2_denoise:
            """ Generates feature tables and feature sequences
            This method denoises paired-end sequences, dereplicates them, and filters chimeras.
            Each feature in the table is represented by one sequence (joined paired-end).

            NOTE: QIIME 2017.11 does not require that both the table and sequences are generated
            in one step, however, QIIME 2019 does require they are generated together.

            NOTE: Although CGR does not require trimming at this step, as it is done upstream of
            this pipeline, external use may require trimming.
            """
            input:
                qza = out_dir + 'import_and_demultiplex/{runID}.qza'
            output:
                tab = out_dir + 'denoising/feature_tables/{runID}.qza',
                seq = out_dir + 'denoising/sequence_tables/{runID}.qza'
            params:
                trim_l_f = trim_left_f,
                trim_l_r = trim_left_r,
                trun_len_f = trunc_len_f,
                trun_len_r = trunc_len_r,
                min_fold = min_fold
            benchmark:
                out_dir + 'run_times/dada2_denoise/{runID}.tsv'
            threads: 8
            run:
                shell('qiime dada2 denoise-paired \
                    --verbose \
                    --p-n-threads {threads} \
                    --i-demultiplexed-seqs {input.qza} \
                    --o-table {output.tab} \
                    --o-representative-sequences {output.seq} \
                    --p-trim-left-f {params.trim_l_f} \
                    --p-trim-left-r {params.trim_l_r} \
                    --p-trunc-len-f {params.trun_len_f} \
                    --p-trunc-len-r {params.trun_len_r} \
                    --p-min-fold-parent-over-abundance {params.min_fold}')

    elif not Q2_2017:
        rule dada2_denoise:
            """ Generates feature tables and feature sequences
            This method denoises paired-end sequences, dereplicates them, and filters chimeras.
            Each feature in the table is represented by one sequence (joined paired-end).

            See notes above.
            """
            input:
                qza = out_dir + 'import_and_demultiplex/{runID}.qza'
            output:
                tab = out_dir + 'denoising/feature_tables/{runID}.qza',
                seq = out_dir + 'denoising/sequence_tables/{runID}.qza',
                stats = out_dir + 'denoising/stats/{runID}.qza'
            params:
                trim_l_f = trim_left_f,
                trim_l_r = trim_left_r,
                trun_len_f = trunc_len_f,
                trun_len_r = trunc_len_r,
                min_fold = min_fold
            benchmark:
                out_dir + 'run_times/dada2_denoise/{runID}.tsv'
            threads: 8
            run:
                shell('qiime dada2 denoise-paired \
                    --verbose \
                    --p-n-threads {threads} \
                    --i-demultiplexed-seqs {input.qza} \
                    --o-table {output.tab} \
                    --o-representative-sequences {output.seq} \
                    --o-denoising-stats {output.stats} \
                    --p-trim-left-f {params.trim_l_f} \
                    --p-trim-left-r {params.trim_l_r} \
                    --p-trunc-len-f {params.trun_len_f} \
                    --p-trunc-len-r {params.trun_len_r} \
                    --p-min-fold-parent-over-abundance {params.min_fold}')

        rule dada2_stats_visualization:
            """Generating visualization for DADA2 stats by flowcell.

            SS: This can actually be used for both both 2017 and 2019 (currently only under 2019)

            https://docs.qiime2.org/2017.10/plugins/available/metadata/tabulate/
            """
            input:
                out_dir + 'denoising/stats/{runID}.qza'
            output:
                out_dir + 'denoising/stats/{runID}.qzv'
            benchmark:
                out_dir + 'run_times/dada2_stats_visualization/{runID}.tsv'
            shell:
                'qiime metadata tabulate \
                    --m-input-file {input} \
                    --o-visualization {output}'



# to add in metadata, start here: plus re- run perl check!  Must have the qza results for samples
rule merge_feature_tables:
    """Merge per-flowcell feature tables into one qza file

    NOTE: Future qiime2 versions allow for multiple tables to be given at
    one time, however, this version does not allow this and one must be given
    at a time. This is because pair-wise merging is not allowed with this
    version, as table_merge cannot run with duplicate sample names. Once
    upgrading to version 2019, we can eliminate the shell script entirely and
    example below can be used.

    WZ tested Q2 2019.1 merging with a single flow cell.  Downstream files
    appear consistent, however the "merged" table is a slightly different size
    compared to the original table.  The most conservative approach seems to
    be only merge when there are >1 flow cells (run IDs).

    NOTE: limited scalability due to cli character limit.
    """
    input:
        tables = expand(out_dir + 'denoising/feature_tables/{runID}.qza', runID=RUN_IDS),
        q2_man = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        out_dir + 'denoising/feature_tables/merged.qza'
    params:
        tab_dir = out_dir + 'denoising/feature_tables/',
        tp = 'feature',
        e = exec_dir
    benchmark:
        out_dir + 'run_times/merge_feature_tables/merge_feature_tables.tsv'
    run:
        if len(RUN_IDS) == 1:
            shell('cp {input.tables} {output}')
        elif Q2_2017:
            shell('bash {params.e}q2_2017_table_merge.sh {params.tp} {output} {input.tables}')
        else:
            l = '--i-tables ' + ' --i-tables '.join(input.tables)
            shell('qiime feature-table merge ' + l + ' --o-merged-table {output}')

rule merge_sequence_tables:
    """Merge per-flowcell sequence tables into one qza file

    See comments from rule "merge_feature_tables."

    NOTE: limited scalability due to cli character limit.
    """
    input:
        tables = expand(out_dir + 'denoising/sequence_tables/{runID}.qza', runID=RUN_IDS),
        q2_man = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        out_dir + 'denoising/sequence_tables/merged.qza'
    params:
        tab_dir = out_dir + 'denoising/sequence_tables/',
        tp = 'sequence',
        e = exec_dir
    benchmark:
        out_dir + 'run_times/merge_sequence_tables/merge_sequence_tables.tsv'
    run:
        if len(RUN_IDS) == 1:
            shell('cp {input.tables} {output}')
        elif Q2_2017:
            shell('bash {params.e}q2_2017_table_merge.sh {params.tp} {output} {input.tables}')
        else:
            l = '--i-data ' + ' --i-data '.join(input.tables)
            shell('qiime feature-table merge-seqs ' + l + ' --o-merged-data {output}')

rule remove_zero_read_samples:
    """ Remove samples that have zero reads
    This will include unexpected failed study samples, and expected sequencing/extraction blanks
    from the merged feature table.

    NOTE: This is necessary for downstream PhyloSeq manipulation.
    """
    input:
        out_dir + 'denoising/feature_tables/merged.qza'
    output:
        out_dir + 'denoising/feature_tables/merged_filtered.qza'
    params:
        f = filt_min
    benchmark:
        out_dir + 'run_times/remove_zero_read_samples/remove_zero_read_samples.tsv'
    shell:
        'qiime feature-table filter-samples \
            --i-table {input} \
            --p-min-features {params.f} \
            --o-filtered-table {output}'

rule feature_table_visualization:
    """Generate visual and tabular summaries of a feature table
    Generate information on how many sequences are associated with each sample
    and with each feature, histograms of those distributions, and some related
    summary statistics.
    """
    input:
        qza = out_dir + 'denoising/feature_tables/merged_filtered.qza',
        q2_man = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        out_dir + 'denoising/feature_tables/merged_filtered.qzv'
    benchmark:
        out_dir + 'run_times/feature_table_visualization/feature_table_visualization.tsv'
    shell:
        'qiime feature-table summarize \
            --i-table {input.qza} \
            --o-visualization {output} \
            --m-sample-metadata-file {input.q2_man}'

rule sequence_table_visualization:
    """Generate visual and tabular summaries for sequences
    Generate a mapping of feature IDs to sequences, and provide links to easily
    BLAST each sequence against the NCBI nt database.
    """
    input:
        out_dir + 'denoising/sequence_tables/merged.qza'
    output:
        out_dir + 'denoising/sequence_tables/merged.qzv'
    benchmark:
        out_dir + 'run_times/sequence_table_visualization/sequence_table_visualization.tsv'
    shell:
        'qiime feature-table tabulate-seqs \
            --i-data {input} \
            --o-visualization {output}'

if Q2_2017:
    rule build_multiple_seq_alignment:
        """Sequence alignment
        Perform de novo multiple sequence alignment using MAFFT.
        """
        input:
            out_dir + 'denoising/sequence_tables/merged.qza'
        output:
            out_dir + 'phylogenetics/msa.qza'
        benchmark:
            out_dir + 'run_times/build_multiple_seq_alignment/build_multiple_seq_alignment.tsv'
        shell:
            'qiime alignment mafft \
                --i-sequences {input} \
                --o-alignment {output}'

    rule mask_multiple_seq_alignment:
        """Filtering alignments
        Filter unconserved and highly gapped columns from an alignment.
        Default min_conservation was chosen to reproduce the mask presented in Lane (1991)
        """
        input:
            out_dir + 'phylogenetics/msa.qza'
        output:
            out_dir + 'phylogenetics/masked_msa.qza'
        benchmark:
            out_dir + 'run_times/mask_multiple_seq_alignment/mask_multiple_seq_alignment.tsv'
        shell:
            'qiime alignment mask \
                --i-alignment {input} \
                --o-masked-alignment {output}'

    rule unrooted_tree:
        """ Construct a phylogenetic tree with FastTree.
        Apply FastTree to generate a phylogenetic tree from the masked
        alignment.
        """
        input:
            out_dir + 'phylogenetics/masked_msa.qza'
        output:
            out_dir + 'phylogenetics/unrooted_tree.qza'
        benchmark:
            out_dir + 'run_times/unrooted_tree/unrooted_tree.tsv'
        shell:
            'qiime phylogeny fasttree \
                --i-alignment {input} \
                --o-tree {output}'

    rule rooted_tree:
        """Midpoint root an unrooted phylogenetic tree.
        Perform midpoint rooting to place the root of the tree at the midpoint
        of the longest tip-to-tip distance in the unrooted tree
        """
        input:
            out_dir + 'phylogenetics/unrooted_tree.qza'
        output:
            out_dir + 'phylogenetics/rooted_tree.qza'
        benchmark:
            out_dir + 'run_times/rooted_tree/rooted_tree.tsv'
        shell:
            'qiime phylogeny midpoint-root \
                --i-tree {input} \
                --o-rooted-tree {output}'

if not Q2_2017:
    rule phylogenetic_tree:
        """Sequence alignment, phylogentic tree assignment, rooting at midpoint
        Starts by creating a sequence alignment using MAFFT, remove any phylogenetically
        uninformative or ambiguously aligned reads, infer a phylogenetic tree
        and then root at its midpoint.
        """
        input:
            out_dir + 'denoising/sequence_tables/merged.qza'
        output:
            msa = out_dir + 'phylogenetics/msa.qza',
            masked_msa = out_dir + 'phylogenetics/masked_msa.qza',
            unrooted_tree = out_dir + 'phylogenetics/unrooted_tree.qza',
            rooted_tree = out_dir + 'phylogenetics/rooted_tree.qza'
        benchmark:
            out_dir + 'run_times/phylogenetic_tree/phylogenetic_tree.tsv'
        shell:
            'qiime phylogeny align-to-tree-mafft-fasttree \
                --i-sequences {input} \
                --o-alignment {output.msa} \
                --o-masked-alignment {output.masked_msa} \
                --o-tree {output.unrooted_tree} \
                --o-rooted-tree {output.rooted_tree}'

# possible site of entry if you want to change sampling depth threshold!
rule alpha_beta_diversity:
    """Performs alpha and beta diversity analysis.
    This includes:
    - Vector of Faith PD values by sample
    - Vector of Observed OTUs values by sample
    - Vector of Shannon diversity values by sample
    - Vector of Pielou's evenness values by sample
    - Matrices of unweighted and weighted UniFrac distances, Jaccard distances,
        and Bray-Curtis distances between pairs of samples.
    - PCoA matrix computed from unweighted and weighted UniFrac distances, Jaccard distances,
        and Bray-Curtis distances between samples.
    - Emperor plot of the PCoA matrix computed from unweighted and weighted UniFrac, Jaccard,
        and Bray-Curtis.

    NOTE: For this step you can use the --output-dir parameter instead of writing
    out all of the outputs BUT QIIME2 wants to create this directory itself and
    won't overwrite the directory if it already exits. This leads to an error since
    Snakemake will make the dir first, and Q2 errors

    https://docs.qiime2.org/2017.11/plugins/available/diversity/core-metrics-phylogenetic/

    Unifrac attempt with one sample causes this step to core dump:
    https://forum.qiime2.org/t/core-metrics-phylogenetic-crashed-free-invalid-next-size/8408/6
    # TODO: write a check and handle gracefully
    """
    input:
        rooted_tree = out_dir + 'phylogenetics/rooted_tree.qza',
        tab_filt = out_dir + 'denoising/feature_tables/merged_filtered.qza',
        q2_man = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        rare = out_dir + 'diversity_core_metrics/rareifed_table.qza',
        faith = out_dir + 'diversity_core_metrics/faith.qza',
        obs = out_dir + 'diversity_core_metrics/observed.qza',
        shan = out_dir + 'diversity_core_metrics/shannon.qza',
        even = out_dir + 'diversity_core_metrics/evenness.qza',
        unw_dist = out_dir + 'diversity_core_metrics/unweighted_dist.qza',
        unw_pcoa = out_dir + 'diversity_core_metrics/unweighted_pcoa.qza',
        unw_emp = out_dir + 'diversity_core_metrics/unweighted_emperor.qzv',
        w_dist = out_dir + 'diversity_core_metrics/weighted_dist.qza',
        w_pcoa = out_dir + 'diversity_core_metrics/weighted_pcoa.qza',
        w_emp = out_dir + 'diversity_core_metrics/weighted_emperor.qzv',
        jac_dist = out_dir + 'diversity_core_metrics/jaccard_dist.qza',
        jac_pcoa = out_dir + 'diversity_core_metrics/jaccard_pcoa.qza',
        jac_emp = out_dir + 'diversity_core_metrics/jaccard_emperor.qzv',
        bc_dist = out_dir + 'diversity_core_metrics/bray-curtis_dist.qza',
        bc_pcoa = out_dir + 'diversity_core_metrics/bray-curtis_pcoa.qza',
        bc_emp = out_dir + 'diversity_core_metrics/bray-curtis_emperor.qzv'
    params:
        samp_depth = sampling_depth
    benchmark:
        out_dir + 'run_times/alpha_beta_diversity/alpha_beta_diversity.tsv'
    shell:
        'qiime diversity core-metrics-phylogenetic \
            --i-phylogeny {input.rooted_tree} \
            --i-table {input.tab_filt} \
            --p-sampling-depth {params.samp_depth} \
            --m-metadata-file {input.q2_man} \
            --o-rarefied-table {output.rare} \
            --o-faith-pd-vector {output.faith} \
            --o-observed-otus-vector {output.obs} \
            --o-shannon-vector {output.shan} \
            --o-evenness-vector {output.even} \
            --o-unweighted-unifrac-distance-matrix {output.unw_dist} \
            --o-unweighted-unifrac-pcoa-results {output.unw_pcoa} \
            --o-unweighted-unifrac-emperor {output.unw_emp} \
            --o-weighted-unifrac-distance-matrix {output.w_dist} \
            --o-weighted-unifrac-pcoa-results {output.w_pcoa} \
            --o-weighted-unifrac-emperor {output.w_emp} \
            --o-jaccard-distance-matrix {output.jac_dist} \
            --o-jaccard-pcoa-results {output.jac_pcoa} \
            --o-jaccard-emperor {output.jac_emp} \
            --o-bray-curtis-distance-matrix {output.bc_dist} \
            --o-bray-curtis-pcoa-results {output.bc_pcoa} \
            --o-bray-curtis-emperor {output.bc_emp}'

rule alpha_diversity_visualization:
    """Metadata visualization wtih alpha diversity metrics
    This generates a tabular view of the metadata in a human viewable format merged with select alpha diversity
    metrics, created in alpha_beta_diversity.
    """
    input:
        obs = out_dir + 'diversity_core_metrics/observed.qza',
        shan = out_dir + 'diversity_core_metrics/shannon.qza',
        even = out_dir + 'diversity_core_metrics/evenness.qza',
        faith = out_dir + 'diversity_core_metrics/faith.qza'
    output:
        out_dir + 'diversity_core_metrics/alpha_diversity_metadata.qzv'
    benchmark:
        out_dir + 'run_times/alpha_diversity_visualization/alpha_diversity_visualization.tsv'
    shell:
        'qiime metadata tabulate \
            --m-input-file {input.obs} \
            --m-input-file {input.shan} \
            --m-input-file {input.even} \
            --m-input-file {input.faith} \
            --o-visualization {output}'

rule alpha_rarefaction:
    """ Generates interactive rarefaction curves.
     Computes rarefactions based on values between `min_depth` and `max_depth`.
     The number of intermediate depths to compute is controlled by the `steps` parameter,
     with n `iterations` being computed at each rarefaction depth. Samples can be grouped
     based on distinct values within a metadata column.

     SS: May want to include steps into our parameters - it is the same for both 2017 and 2019

     TODO: --p-steps INTEGER RANGE         [default: 10]
    """
    input:
        tab_filt = out_dir + 'denoising/feature_tables/merged_filtered.qza',
        rooted = out_dir + 'phylogenetics/rooted_tree.qza',
        q2_man = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        out_dir + 'diversity_core_metrics/rarefaction.qzv'
    params:
        m_depth = max_depth
    benchmark:
        out_dir + 'run_times/alpha_rarefaction/alpha_rarefaction.tsv'
    shell:
        'qiime diversity alpha-rarefaction \
            --i-table {input.tab_filt} \
            --i-phylogeny {input.rooted} \
            --p-max-depth {params.m_depth} \
            --m-metadata-file {input.q2_man} \
            --o-visualization {output}'

rule taxonomic_classification:
    """Classify reads by taxon using a fitted classifier

    Note that different classification methods have entirely different command
    line flags, so they will each need their own invocation.

    https://docs.qiime2.org/2019.4/plugins/available/feature-classifier/

    sklearn:

    consensus-blast: Performs BLAST+ local alignment between query and
    reference_reads, then assigns consensus taxonomy to each query sequence
    from among maxaccepts hits, min_consensus of which share that taxonomic
    assignment. Note that maxaccepts selects the first N hits with >
    perc_identity similarity to query, not the top N matches.

    consensus-vsearch: Performs VSEARCH global alignment between query and
    reference_reads, then assigns consensus taxonomy to each query sequence
    from among maxaccepts top hits, min_consensus of which share that taxonomic
    assignment. Unlike classify-consensus-blast, this method searches the entire
    reference database before choosing the top N hits, not the first N hits.
    """
    input:
        tab_filt = out_dir + 'denoising/sequence_tables/merged.qza',
        ref = get_ref_full_path
    output:
        out_dir + 'taxonomic_classification/' + classify_method + '_{ref}.qza'
    params:
        c_method = classify_method
    benchmark:
        out_dir + 'run_times/taxonomic_classification/{ref}.tsv'
    threads: 8
    run:
        if classify_method == 'classify-sklearn':
            shell('qiime feature-classifier {params.c_method} \
                --p-n-jobs {threads} \
                --i-classifier {input.ref} \
                --i-reads {input.tab_filt} \
                --o-classification {output}')

rule taxonomic_class_visualization:
    """Metadata visualization wtih taxonomic information

    This generates a tabular view of the metadata in a human viewable format merged
    with taxonomic information created in taxonomic_classification

    SS: may want to change name of rule so that "class" since class =/ taxonomic "class"
    """
    input:
        out_dir + 'taxonomic_classification/' + classify_method + '_{ref}.qza'
    output:
        out_dir + 'taxonomic_classification/' + classify_method + '_{ref}.qzv'
    benchmark:
        out_dir + 'run_times/taxonomic_class_visualization/{ref}.tsv'
    shell:
        'qiime metadata tabulate \
            --m-input-file {input} \
            --o-visualization {output}'

rule taxonomic_class_plots:
    """Interactive barplot visualization of taxonomies

    This allows for multi-level sorting, plot recoloring, category
    selection/highlighting, sample relabeling, and SVG figure export.

    SS: may want to change name of rule so that "class" since class =/ taxonomic "class"
    """
    input:
        tab_filt = out_dir + 'denoising/feature_tables/merged_filtered.qza',
        tax = out_dir + 'taxonomic_classification/' + classify_method + '_{ref}.qza',
        mani = out_dir + 'manifests/manifest_qiime2.tsv'
    output:
        out_dir + 'taxonomic_classification/barplots_' + classify_method + '_{ref}.qzv'
    benchmark:
        out_dir + 'run_times/taxonomic_class_plots/{ref}.tsv'
    shell:
        'qiime taxa barplot \
            --i-table {input.tab_filt} \
            --i-taxonomy {input.tax} \
            --m-metadata-file {input.mani} \
            --o-visualization {output}'
