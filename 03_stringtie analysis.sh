#!/bin/bash

# StringTie Transcript Assembly Script
# This script performs parallel transcript assembly using StringTie

# Load required module
module load /workspace/public/aarch64/software/modules/tool/stringtie-2.2.1

# Configuration parameters
ref_gtf="/workspace/home/goat/supeng/GTEX_goat/RNA/ref/genomic.gff"   # Path to reference annotation GTF file
output_dir="stringtie_output"        # Output directory for GTF files
threads_per_job=10                     # Threads per StringTie job
max_parallel=8                        # Maximum parallel jobs to run

# Create output directory if it doesn't exist
mkdir -p ${output_dir}

# Initialize counters
count=0
current_jobs=0

# Process all BAM files from hisat2_output directory
for bam_file in /workspace/home/goat/supeng/GTEX_goat/RNA/Boer/hisat2_output/*.bam; do
    # Extract sample name by removing .bam extension
    sample_name=$(basename "${bam_file}" .bam)
    
    # Set output GTF file path
    output_gtf="${output_dir}/${sample_name}.gtf"
    
    # Display progress
    echo "[$(date +'%T')] Processing ${sample_name} (Job $((++count)))"
    
    # Run StringTie in background
    stringtie -p ${threads_per_job} -G "${ref_gtf}" \
              -l "${sample_name}" \
              -o "${output_gtf}" \
              "${bam_file}" &
    
    # Parallel job control
    if (( ++current_jobs % max_parallel == 0 )); then
        echo "[$(date +'%T')] Waiting for current batch to complete..."
        wait
    fi
done

# Wait for remaining jobs to finish
wait

echo -e "\nAll samples processed successfully!"
echo "Output GTF files are saved in: ${output_dir}/"
