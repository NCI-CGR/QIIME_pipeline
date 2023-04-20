
import csv
import subprocess
import re

#input_file = 'NP0440-MB5-manifest.txt'
input_file = 'NP0440-MB5-manifest.txt'
output_file = 'new_manifest.txt'
fastq_folder = '/DCEG/CGF/Sequencing/Illumina/MiSeq/PostRun_Analysis/Data/'


def generate_fastq_locations(sample_id, run_id, source_pcr_plate):
    # Replace "_" with "-" in Source PCR Plate
    source_pcr_plate = source_pcr_plate.replace('_', '-')
    
    # Check if Sample ID ends with _1 or _2
    ends_with_1_or_2 = re.search(r'_[12]$', sample_id)
    
    if ends_with_1_or_2:
        # Remove trailing _1 or _2 from Sample ID
        sample_id = re.sub(r'_[12]$', '', sample_id)
    
    folder_path = f"{fastq_folder}/{run_id}/"
    
    if ends_with_1_or_2:
        find_command = f"find {folder_path} -name '{sample_id}-{source_pcr_plate}*R1_001.fastq.gz'"
    else:
        find_command = f"find {folder_path} -name '{sample_id}*R1_001.fastq.gz'"

    print("Line 33: ",find_command)
    
    result = subprocess.run(find_command, stdout=subprocess.PIPE, shell=True, text=True)
    fq1 = result.stdout.strip()

    if ends_with_1_or_2:
        find_command = f"find {folder_path} -name '{sample_id}-{source_pcr_plate}*R2_001.fastq.gz'"
    else:
        find_command = f"find {folder_path} -name '{sample_id}*R2_001.fastq.gz'"

    result = subprocess.run(find_command, stdout=subprocess.PIPE, shell=True, text=True)
    fq2 = result.stdout.strip()

    return fq1, fq2



with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
    reader = csv.DictReader(infile, delimiter='\t')
    
    # Set fieldnames to include only the required columns
    fieldnames = ['Sample ID', 'Source PCR Plate', 'Run-ID', 'MetaData', 'Project-ID', 'fq1', 'fq2']
    writer = csv.DictWriter(outfile, fieldnames=fieldnames, delimiter='\t')
    
    # Write header to output file
    writer.writeheader()
    
    # Process each line and add fq1 and fq2 columns
    for row in reader:
        sample_id = row['Sample ID']
        run_id = row['Run-ID']
        fq1, fq2 = generate_fastq_locations(sample_id, run_id, row['Source PCR Plate'])
        row['fq1'] = fq1
        row['fq2'] = fq2
        writer.writerow({key: row[key] for key in fieldnames})

print(f'New manifest file generated: {output_file}')
