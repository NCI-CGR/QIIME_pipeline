import os
import re
import os.path
from os import path

# reference the config file
conf = os.environ.get("conf")
configfile: conf

def collect_runids(meta_man_fullpath):
    #Example runid/flowcell id: 180112_M01354_0104_000000000-BFN3F

	runid_list = [x.split('\t')[5] for x in open(meta_man_fullpath).readlines()]
	runid_list.pop(0)
	runid_list=set(runid_list)
	return runid_list

def symlinks(proj_dir,runid_list):
    #Example src (source location):
    #{fastq_abs_path}180112_M01354_0104_000000000-BFN3F/CASAVA/L1/Project_NP0084-MB4/Sample_SC249358/SC249358_GAAGAAGCGGTA_L001_R1_001.fastq.gz

    #Example dst (destination location):
    #{proj_dir}Input/fasta/fasta_dir_split_part_180112_M01354_0104_000000000-BFN3F/SC249358_GAAGAAGCGGTA_L001_R1_001.fastq.gz

    src_list=[]
    dst_list=[]

    for runs in runid_list:
        fastq_path_list = [x.split(',')[1] for x in open(proj_dir+"Input/split_parts_manifests/split_parts_manifest_"+runs+".txt").readlines()]
        fastq_path_list.pop(0) #Remove header

        for src in fastq_path_list:
            runid=re.sub(r"(^\/DCEG).*Data\/","",src)
            runid=re.sub(r"(\/CASAVA).*","",runid)

            if not os.path.exists(proj_dir + "Input/fasta/fasta_dir_split_part_" + runid):
                os.makedirs(proj_dir + "Input/fasta/fasta_dir_split_part_" + runid)

            dst=proj_dir + "Input/fasta/fasta_dir_split_part_" + runid + "/"+re.sub(r"(^\/DCEG).*(_SC).*\/","",src)
            src_list.append(src)
            dst_list.append(dst)

        with open(proj_dir + "Input/fasta/dst_list.txt", 'w') as f:
            for dst in dst_list:
                f.write("%s\n" % dst)

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

rule all:
    input:
        #q2_man=proj_dir + 'Input/manifest_qiime2.tsv',
        #expand('{proj_dir}Input/split_parts_manifests/split_parts_manifest_{runid}.txt',proj_dir=proj_dir,runid=runid_list),
        symlink_file_list=proj_dir + 'Input/fasta/dst_list.txt'

rule qiime2_manifest:
    input:
        proj_dir=directory({proj_dir}),
        meta_man_fullpath=proj_dir+metadata_manifest
    output:
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv',
    shell:
        'source /etc/profile.d/modules.sh; module load perl/5.18.0;'
        'perl Q2Manifest.pl {input.proj_dir} {input.meta_man_fullpath} {output.q2_man}'

rule split_part_manifest:
    input:
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv',
    output:
        split_man_files=proj_dir + 'Input/split_parts_manifests/split_parts_manifest_{runid_list}.txt'
    params:
        fastq_abs_path=fastq_abs_path
    shell:
        'source /etc/profile.d/modules.sh; module load perl/5.18.0;'
        'perl SplitManifest.pl {params.fastq_abs_path} {input.q2_man} {output.split_man_files}'

rule create_symlinks:
    input:
        expand('{proj_dir}Input/split_parts_manifests/split_parts_manifest_{runid}.txt',proj_dir=proj_dir,runid=runid_list),
    output:
        symlink_file_list=proj_dir + 'Input/fasta/dst_list.txt'
    run:
        symlinks(proj_dir,runid_list)
