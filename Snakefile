import os

# reference the config file
conf = os.environ.get("conf")
configfile: conf
sample_list = ['1','2','3','4']
#sample_list = ['1']

# import variables from the config file
proj_dir = config['project_dir']
metadata_manifest = config['metadata_manifest']

rule all:
    input:
        #q2_man=proj_dir + 'Input/manifest_qiime2.tsv'
        #expand('{proj_dir}Input/manifest_file_split_parts_fastq_import/manifest_file_split_parts_fastq_import_{samples}.txt',proj_dir=proj_dir,samples=sample_list),
        expand('{proj_dir}Input/Fasta/fasta_dir_split_part_{samples}/',proj_dir=proj_dir,samples=sample_list)

rule qiime2_manifest:
    input:
        proj_dir=directory({proj_dir}),
        meta_man_fullpath=proj_dir+metadata_manifest
    output:
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv'
    shell:
        'dos2unix {input.meta_man_fullpath};\
        perl Q2Manifest.pl {input.proj_dir} {input.meta_man_fullpath} {output.q2_man}'

rule split_part_manifest:
    input:
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv'
    output:
        split_man_files=proj_dir + 'Input/manifest_file_split_parts_fastq_import/manifest_file_split_parts_fastq_import_{sample_list}.txt'
    shell:
        'perl SplitManifest.pl {input.q2_man} {output.split_man_files}'

rule create_symlinks:
    input:
        split_man=directory(expand('{proj_dir}Input/manifest_file_split_parts_fastq_import/',proj_dir=proj_dir))
    output:
        fasta_dir_split_part=directory(expand('{proj_dir}Input/Fasta/fasta_dir_split_part_{samples}/',proj_dir=proj_dir,samples=sample_list))
    shell:
        'perl CreateSymlinks.pl {input.split_man} {output.fasta_dir_split_part}'
