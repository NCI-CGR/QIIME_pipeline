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
        q2_man=proj_dir + 'Input/manifest_qiime2.tsv'
    shell:
        'dos2unix {input.meta_man_fullpath};\
        perl Q2Manifest.pl {input.proj_dir} {input.meta_man_fullpath} {params.meta_man} {output.q2_man}'
