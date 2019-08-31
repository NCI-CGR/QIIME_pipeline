import os

# reference the config file
conf = os.environ.get("conf")
configfile: conf

# import variables from the config file
proj_dir = config['project_dir']
metadata_manifest = config['metadata_manifest']

rule qiime2_manifest:
    input:
        proj_dir=directory({proj_dir}),
        meta_man_fullpath=proj_dir+metadata_manifest
    params:
        meta_man=metadata_manifest
    output:
        proj_dir + 'manifest_qiime2.tsv'
    shell:
        'perl Q2Manifest.pl {input.proj_dir} {params.meta_man}'
