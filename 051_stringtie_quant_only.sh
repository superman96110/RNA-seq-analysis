#!/bin/bash
set -euo pipefail

merge_dir="/mnt/vde/210/GTEX_goat/RNA/merge/stringtie_merge"
merged_gtf="${merge_dir}/stringtie_merged.gtf"

quant_root="${merge_dir}/quant_merged"
mkdir -p "$quant_root/logs"

threads_per_job=6
max_parallel=6

bam_dirs=(
  "/mnt/vde/210/GTEX_goat/RNA/Boer/hisat2_output"
  "/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hisat2_output"
  "/mnt/vde/210/GTEX_goat/RNA/HN/hisat2_output"
  "/mnt/vde/210/GTEX_goat/RNA/HN/tissue/hisat2_output"
  "/mnt/vde/210/GTEX_goat/RNA/XD/hisat2_output"
  "/mnt/vde/210/GTEX_goat/RNA/XD/XD-tissue/hisat2_output"
)

if [[ ! -f "$merged_gtf" ]]; then
  echo "ERROR: merged GTF not found: $merged_gtf"
  exit 1
fi

# 提前检查 stringtie 是否可用（避免 nohup 环境差异）
if ! command -v stringtie >/dev/null 2>&1; then
  echo "ERROR: stringtie not found in PATH."
  exit 1
fi

echo "Merged GTF : $merged_gtf"
echo "Quant out  : $quant_root"
echo

sample_list="${quant_root}/sample_list.txt"
: > "$sample_list"

collect_bams_in_dir() {
  local d="$1"
  shopt -s nullglob

  local fastp=("$d"/*_fastpfilter.bam)
  local chosen=()

  if (( ${#fastp[@]} > 0 )); then
    chosen=("${fastp[@]}")
  else
    chosen=("$d"/*.bam)
  fi

  local kept=()
  local b
  for b in "${chosen[@]}"; do
    [[ "$b" == *.bam.tmp.*.bam ]] && continue
    [[ "$b" == *.tmp.*.bam ]] && continue
    kept+=("$b")
  done

  printf "%s\n" "${kept[@]}"
}

current_jobs=0
total=0

for d in "${bam_dirs[@]}"; do
  if [[ ! -d "$d" ]]; then
    echo "WARN: directory not found, skip: $d"
    continue
  fi

  mapfile -t bams < <(collect_bams_in_dir "$d" | sort)

  if (( ${#bams[@]} == 0 )); then
    echo "WARN: no BAM selected in: $d"
    continue
  fi

  echo "Dir: $d"
  if compgen -G "$d/*_fastpfilter.bam" > /dev/null; then
    echo "  -> Found *_fastpfilter.bam, using ONLY fastpfilter BAMs (${#bams[@]})."
  else
    echo "  -> No *_fastpfilter.bam, using normal BAMs (${#bams[@]})."
  fi
  echo

  for bam in "${bams[@]}"; do
    total=$((total+1))

    sample="$(basename "$bam" .bam)"
    sample_dir="${quant_root}/${sample}"
    mkdir -p "$sample_dir"

    out_gtf="${sample_dir}/${sample}.gtf"
    log="${quant_root}/logs/${sample}.stringtie.log"

    echo -e "${sample}\t${sample_dir}" >> "$sample_list"

    echo "[$total] StringTie quant: $sample"

    stringtie "$bam" \
      -G "$merged_gtf" \
      -e -B \
      -p "$threads_per_job" \
      -o "$out_gtf" \
      > "$log" 2>&1 &

    current_jobs=$((current_jobs+1))
    if (( current_jobs >= max_parallel )); then
      echo "Batch full -> waiting..."
      wait
      current_jobs=0
    fi
  done
done

wait

echo
echo "All StringTie quant completed!"
echo "sample_list.txt: $sample_list"
echo "Quant results :  $quant_root"

