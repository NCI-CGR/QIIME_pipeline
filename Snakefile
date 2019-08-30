import os

# reference the config file
configfile: "config.yml"

# import variables from the config file
proj_dir = config['project_dir']
metadata_manifest = config['metadata_manifest']

rule qiime2_manifest:
    input:
        proj_dir=proj_dir,
        meta_man=proj_dir+metadata_manifest
    output:
        proj_dir + 'manifest_qiime2.tsv'
    shell:
        'perl Q2Manifest.pl {input.proj_dir} {metadata_manifest}'
