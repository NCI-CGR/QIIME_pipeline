import os
import re

# reference the config file
conf = os.environ.get("conf")
configfile: conf

def collect_runids(meta_man_fullpath):
	runid_list = [x.split('\t')[5] for x in open(meta_man_fullpath).readlines()]
	runid_list.pop(0)
	runid_list=set(runid_list)
	return runid_list

def symlinks_list(proj_dir,runid_list):
    src_list=[]
    dst_list=[]

    for runs in runid_list:
        fastq_path_list = [x.split(',')[1] for x in open(proj_dir+"Input/split_parts_manifests/split_parts_manifest_"+runs+".txt").readlines()]
        fastq_path_list.pop(0)

        for src in fastq_path_list:
            runid=re.sub(r"(^\/DCEG).*Data\/","",src)
            runid=re.sub(r"(\/CASAVA).*","",runid)
            dst=proj_dir + "Input/Fasta/fasta_dir_split_part_" + runid + "/"+re.sub(r"(^\/DCEG).*(_SC).*\/","",src)

            src_list.append(src)
            dst_list.append(dst)
            #Example dst:
            #{proj_dir}Input/fasta/fasta_dir_split_part_180112_M01354_0104_000000000-BFN3F/SC249359-PC04924-B-01_TATCAGGTGTGC_L001_R1_001.fastq.gz
    return src_list,dst_list

def symlinks_create(src_list,dst_list):
    i=0
    for src in src_list:
        dst=dst_list[i]
        i += 1
        os.symlink(src,dst)

# import variables from the config file
proj_dir = config['project_dir']
metadata_manifest = config['metadata_manifest']
fastq_abs_path=config['fastq_abs_path']

runid_list = collect_runids(proj_dir+metadata_manifest)
src_list,dst_list=symlinks_list(proj_dir,runid_list)

rule all:
    input:
        #q2_man=proj_dir + 'Input/manifest_qiime2.tsv',
        #expand('{proj_dir}Input/split_parts_manifests/split_parts_manifest_{runid}.txt',proj_dir=proj_dir,runid=runid_list)
        #expand('{proj_dir}Input/Fasta/fasta_dir_split_part_{samples}/',proj_dir=proj_dir,samples=runid_list)
        symlinkfiles=dst_list
    #run:
        #symlinks_create(src_list,dst_list)
rule qiime2_manifest:
    input:
        proj_dir=directory({proj_dir}),
        meta_man_fullpath=proj_dir+metadata_manifest
    output:
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv',
    shell:
        'dos2unix {input.meta_man_fullpath};\
        perl Q2Manifest.pl {input.proj_dir} {input.meta_man_fullpath} {output.q2_man}'

rule split_part_manifest:
    input:
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv',
    output:
        split_man_files=proj_dir + 'Input/split_parts_manifests/split_parts_manifest_{runid_list}.txt'
    params:
        fastq_abs_path=fastq_abs_path
    shell:
        'perl SplitManifest.pl {params.fastq_abs_path} {input.q2_man} {output.split_man_files}'

rule create_symlinks:
    output:
        symlinkfiles=dst_list
    run:
        symlinks_create(src_list,dst_list)
