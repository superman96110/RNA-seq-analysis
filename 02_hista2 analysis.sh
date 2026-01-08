#!/bin/bash

# Load required modules
module load /workspace/public/aarch64/software/modules/tool/samtools-1.19.2
module load /workspace/public/aarch64/software/modules/tool/hisat2-2.1.0

# Configuration parameters
index_path="/workspace/home/goat/supeng/GTEX_goat/RNA/ref/ARS1.2_tran"  # Replace with the actual index path
output_dir="/workspace/home/goat/supeng/GTEX_goat/RNA/Boer/hisat2_output/"  # Output directory
threads_per_job=10  # Number of threads per hisat2 job
samtools_threads=2  # Number of threads for samtools sorting
max_parallel=8  # Maximum number of parallel jobs

# Create output directory
mkdir -p "$output_dir"

# Initialize job counter
current_jobs=0

# Process only files ending with _fastpfilter_1.fq.gz
for r1_file in *_fastpfilter_1.fq.gz; do
    # Extract base name by removing '_fastpfilter_1.fq.gz' suffix
    base_name="${r1_file%_fastpfilter_1.fq.gz}"
    
    # Construct corresponding R2 filename
    r2_file="${base_name}_fastpfilter_2.fq.gz"
    
    # Check if the R2 file exists
    if [[ ! -f "$r2_file" ]]; then
        echo "Error: Paired file $r2_file not found, skipping $r1_file"
        continue
    fi
    
    # Set output file names
    summary_file="${output_dir}/${base_name}_summary.txt"
    bam_output="${output_dir}/${base_name}.bam"
    
    # Run alignment and sorting command (in the background)
    echo "Processing: $base_name"
    hisat2 -p $threads_per_job --dta -x "$index_path" \
        --summary-file "$summary_file" \
        -1 "$r1_file" -2 "$r2_file" \
        | samtools sort -@ $samtools_threads -o "$bam_output" - &
    
    # Control the number of parallel jobs
    ((current_jobs++))
    if [[ $current_jobs -ge $max_parallel ]]; then
        wait  # Wait for all background jobs to finish
        current_jobs=0  # Reset the counter
    fi
done

# Wait for remaining jobs to finish
wait

echo "All processing completed!"
echo "Output files are saved in: $output_dir"
