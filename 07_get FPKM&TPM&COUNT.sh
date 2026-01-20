#cd /mnt/vde/210/GTEX_goat/RNA/merge/stringtie_merged/quant_merged
#dirs=$(cut -f1 sample_list.txt | paste -sd, -)

./stringtie_expression_matrix.pl \
  --expression_metric=TPM \
  --result_dirs="$dirs" \
  --transcript_matrix_file=transcript_tpms_all_samples.tsv \
  --gene_matrix_file=gene_tpms_all_samples.tsv


./stringtie_expression_matrix.pl \
  --expression_metric=FPKM \
  --result_dirs="$dirs" \
  --transcript_matrix_file=transcript_fpkms_all_samples.tsv \
  --gene_matrix_file=gene_fpkms_all_samples.tsv

./stringtie_expression_matrix.pl \
  --expression_metric=coverage \
  --result_dirs="$dirs" \
  --transcript_matrix_file=transcript_coverage_all_samples.tsv \
  --gene_matrix_file=gene_coverage_all_samples.tsv
