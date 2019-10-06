#! /usr/bin/env python3
import os
import re


# reference the config file
conf = os.environ.get("conf")
configfile: conf

# import variables from the config file
proj_dir = config['project_dir'] + 'QIIME2/'  # separate output dir from manifest dir
metadata_manifest = config['metadata_manifest']
fastq_abs_path = config['fastq_abs_path']
qiime_version = config['qiime_version']
queue = config['QUEUE']
resources_dir = config['RESOURCES_DIR']
demux_param = config['demux_param']
input_type = config['input_type']
phred_score = config['phred_score']
denoise_method = config['denoise_method']
trim_left_f = config['trim_left_forward']
trim_left_r = config['trim_left_reverse']
trunc_len_f = config['truncate_length_forward']
trunc_len_r = config['truncate_length_reverse']


meta_man_fullpath = proj_dir + metadata_manifest
sym_link_path = proj_dir + 'fastqs/'


# REQUIREMENTS TO START PIPELINE:
# - directory containing: manifest (e.g. NP0084-MB4_08_29_19_metadata_test.txt) at top level


# example manifest (specified in config):
# #SampleID       External-ID     Sample-Type     Source-Material Source-PCR-Plate        Run-ID  Project-ID      Reciept Sample_Cat      SubjectID       Sample_Aliquot  Ext_Company     Ext_Kit Ext_Robot
#        Homo_Method     Homo-Holder     Homo-Holder2    AFA Setting1    AFA Setting2    Extraction Batch        Residual or Original    Row     Column
# SC249358        DZ35322 0006_01 ArtificialColony        CGR     PC04924_A_01    180112_M01354_0104_000000000-BFN3F      NP0084-MB4      sFEMB-001-R-002 ExtControl      DZ35322 0       CGR     DSP Virus
#        QIASymphony     V Adaptor       Tubes   NA      NA      NA      2       Original        A       1
# SC249359-PC04924-B-01   Stool_20        Stool   CGR     PC04924_B_01    180112_M01354_0104_000000000-BFN3F      NP0084-MB4      sFEMB-001-R-002 Study   IE_Stool        20      CGR     DSP Virus       QIASymphony     V Adaptor       Tubes   NA      NA      NA      2       Original        B       1
# SC249360-PC04924-C-01   DZ35298 0093_01 Robogut CGR     PC04924_C_01    180112_M01354_0104_000000000-BFN3F      NP0084-MB4      sFEMB-001-R-002 ExtControl      DZ35298 0       CGR     DSP Virus       QIASymphony     V Adaptor       Tubes   NA      NA      NA      2       Original        C       1
# SC249359-PC04925-A-01   Stool_20        Stool   CGR     PC04925_A_01    180112_M03599_0134_000000000-BFD9Y      NP0084-MB4      sFEMB-001-R-002 Study   IE_Stool        20      CGR     DSP Virus       QIASymphony     V Adaptor       Tubes   NA      NA      NA      2       Original        B       1

# example run ID:
# '180112_M01354_0104_000000000-BFN3F'

# example split parts manifest:
# '/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Testing/Project_NP0084-MB4/Input/split_parts_manifests/split_parts_manifest_180112_M01354_0104_000000000-BFN3F.txt

    # sample-id,absolute-filepath,direction
    # SC249358,/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249358/SC249358_GAAGAAGCGGTA_L001_R1_001.fastq.gz,forward
    # SC249358,/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249358/SC249358_GAAGAAGCGGTA_L001_R2_001.fastq.gz,reverse
    # SC249359-PC04924-B-01,/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249359-PC04924-B-01/SC249359-PC04924-B-01_TATCAGGTGTGC_L001_R1_001.fastq.gz,forward
    # SC249359-PC04924-B-01,/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249359-PC04924-B-01/SC249359-PC04924-B-01_TATCAGGTGTGC_L001_R2_001.fastq.gz,reverse

# example fastq file found based on run ID:
# '/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249358/SC249358_GAAGAAGCGGTA_L001_R1_001.fastq.gz'

# example sym link path:
# '/DCEG/Projects/Microbiome/CGR_MB/MicroBiome/Testing/Project_NP0084-MB4/Input/fasta/fasta_dir_split_part_180112_M01354_0104_000000000-BFN3F/SC249358_GAAGAAGCGGTA_L001_R1_001.fastq.gz'

# /DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/190617_M01354_0118_000000000-CHFG3/CASAVA/L1/Project_NP0084-MB6/Sample_SC502441/SC502441_GACTCGAATCGT_L001_R1_001.fastq.gz


# from manifest, pull sampleID, projID, runID, then assemble those to get the original fqs:

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
    '''Return original fastq with path based on filename
    Note there are some assumptions here (files always end with
    R1_001.fastq.gz; only one R1 fq per directory).  Same for
    following function.

    SS: This is true - historic projects that had duplicates creating at seq or extraction level had new folders created so only 2 FASTQ / folder
    '''
    (runID, projID) = sampleDict[wildcards.sample]
    p = fastq_abs_path + runID + '/CASAVA/L1/Project_' + projID + '/Sample_' + wildcards.sample + '/'
    file = [f for f in os.listdir(p) if f.endswith('R1_001.fastq.gz')]
    # TODO: error if file contains more than one element.  below too.
    return p + file[0]


def get_orig_r2_fq(wildcards):
    '''Return original fastq with path based on filename
    '''
    (runID, projID) = sampleDict[wildcards.sample]
    p = fastq_abs_path + runID + '/CASAVA/L1/Project_' + projID + '/Sample_' + wildcards.sample + '/'
    file = [f for f in os.listdir(p) if f.endswith('R2_001.fastq.gz')]
    return p + file[0]


rule all:
    input:
        expand(sym_link_path + '{sample}_R1.fastq.gz', sample=sampleDict.keys()),
        expand(sym_link_path + '{sample}_R2.fastq.gz', sample=sampleDict.keys()),
        proj_dir + 'manifests/manifest_qiime2.tsv',
        expand(proj_dir + 'manifests/{runID}_Q2_manifest.txt',runID=RUN_IDS),
        expand(proj_dir + 'out/qza_results/demux/{runID}_' + demux_param + '.qza',runID=RUN_IDS),
        expand(proj_dir + 'out/qzv_results/demux/{runID}_' + demux_param + '.qzv',runID=RUN_IDS),
        expand(proj_dir + 'out/qza_results/table/{runID}_' + demux_param + '.qza',runID=RUN_IDS),
        expand(proj_dir + 'out/qza_results/repseq/{runID}_' + demux_param + '.qza',runID=RUN_IDS),
        proj_dir + 'out/qza_results/table/final_' + demux_param + '.qza',
        proj_dir + 'out/qza_results/repseq/final_' + demux_param + '.qza',



# think about adding check for minimum reads count per sample per flow cell (need more than 1 sample per flow cell passing min threshold for tab/rep seq creation) - either see if we can include via LIMS in the manifest, or use samtools(?)

rule check_manifest:
    '''QIIME2 has specific metadata requirements for headers and columns
    Since user is creating manifest (likely) in Excel, need to parse files to ensure that it meets requirements
    TODO: add execute path for perl script
    '''
    input:
        meta_man_fullpath
    output:
        proj_dir + 'manifests/manifest_qiime2.tsv'
    params:
        proj_dir
    shell:
        'perl Q2Manifest.pl {params} {input} {output}'

rule create_per_sample_Q2_manifest:
    '''QIIME2 has it's own manifest file format, created per-sample here
    why was this called "split part"?  What has been split? - SS: project is being "split" into flowcells
    is there a reason to keep samples separated by run ID? - DADA2 requires you to group samples by flow cell (runID)
    '''
    input:
        fq1 = get_orig_r1_fq,
        fq2 = get_orig_r2_fq
    output:
        proj_dir + 'manifests/{sample}_Q2_manifest.txt'
    shell:
        'echo "{wildcards.sample},{input.fq1},forward" > {output};'
        'echo "{wildcards.sample},{input.fq2},reverse" >> {output}'

rule combine_Q2_manifest_by_runID:
    '''Q2 per-sample manifests combined into a single file
    '''
    input:
        expand(proj_dir + 'manifests/{sample}_Q2_manifest.txt', sample=sampleDict.keys())
    output:
        proj_dir + 'manifests/{runID}_Q2_manifest.txt'
    shell:
        'cat {input} | awk \'BEGIN{{FS=OFS="/"}}NR==1{{print "sample-id,absolute-filepath,direction"}}$9=="{wildcards.runID}"{{print $0}}\' > {output}'
        # 'cat <(echo "sample-id,absolute-filepath,direction") <(cat {input} | awk \'{{FS=OFS="/"}}$9=={wildcards.runID}{{print $0}}\') > {output}'

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
        proj_dir + 'manifests/{runID}_Q2_manifest.txt'
    output:
        proj_dir + 'out/qza_results/demux/{runID}_' + demux_param + '.qza'
    params:
        q2 = qiime_version,
        demux_param = demux_param,
        i_type = input_type,
        phred = phred_score
    conda:
        'envs/qiime2-2017.11.yaml'
    shell:
        'qiime tools import \
            --type {params.i_type} \
            --input-path {input}\
            --output-path {output}\
            --source-format PairedEndFastqManifestPhred{params.phred}'

rule demux_summary_qzv:
    '''

    '''
    input:
        proj_dir + 'out/qza_results/demux/{runID}_' + demux_param + '.qza'
    output:
        proj_dir + 'out/qzv_results/demux/{runID}_' + demux_param + '.qzv'
    params:
        q2 = qiime_version,
        demux_param = demux_param
    # conda:
    #     'envs/qiime2-2017.11.yaml'
    shell:
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
        proj_dir + 'out/qza_results/demux/{runID}_' + demux_param + '.qza'
    output:
        tab = proj_dir + 'out/qza_results/table/{runID}_' + demux_param + '.qza',
        seq = proj_dir + 'out/qza_results/repseq/{runID}_' + demux_param + '.qza'
    params:
        q2 = qiime_version,
        demux_param = demux_param,
        trim_l_f = trim_left_f,
        trim_l_r = trim_left_r,
        trun_len_f = trunc_len_f,
        trun_len_r = trunc_len_r
    shell:
        'qiime dada2 denoise-paired\
            --i-demultiplexed-seqs {input} \
          	--o-table {output.tab} \
          	--o-representative-sequences ${output.seq} \
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
#     #    expand(proj_dir + 'out/qza_results/demux/{runID}_' + demux_param + '.qza',runID=RUN_IDS)
#     #output:
#     #    proj_dir + 'out/qza_results/table/final_' + demux_param + '.qza',
#     #params:
#     #    q2 = qiime_version,
#     #    demux_param = demux_param
#     #shell:
#     #    'source activate qiime2-2017.11;'
#     #    'qiime feature-table merge \
#     #        --i-tables {input} \
#     #        --o-merged-table {output}'
#
#     input:
#         proj_dir + 'out/qza_results/table/{runID}_' + demux_param + '.qza',
#     output:
#         proj_dir + 'out/qza_results/table/final_' + demux_param + '.qza',
#     params:
#         q2 = qiime_version,
#         demux_param = demux_param,
#         tab_dir = directory( proj_dir + 'out/qza_results/table/')
#     shell:
#         'table_merge.sh {params.tab_dir} {output}'
#
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
#     #    expand(proj_dir + 'out/qza_results/demux/{runID}_' + demux_param + '.qza',runID=RUN_IDS)
#     #output:
#     #    proj_dir + 'out/qza_results/repseq/final_' + demux_param + '.qza'
#     #params:
#     #    q2 = qiime_version,
#     #    demux_param = demux_param
#     #shell:
#     #    'source activate qiime2-2017.11;'
#     #    'qiime feature-table merge-seqs \
#     #        --i-data {input} \
#     #        --o-merged-data {output}'
#
#     input:
#         proj_dir + 'out/qza_results/repseq/{runID}_' + demux_param + '.qza'
#     output:
#         proj_dir + 'out/qza_results/repseq/final_' + demux_param + '.qza'
#     params:
#         q2 = qiime_version,
#         demux_param = demux_param,
#         rep_dir = directory( proj_dir + 'out/qza_results/repseqs/')
#     shell:
#         'rep_merge.sh {params.rep_dir} {output}'
