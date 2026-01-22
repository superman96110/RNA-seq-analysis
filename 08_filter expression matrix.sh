awk 'NR==1 {print; next}
     !(/^UNANNOTATED/ || /^gene-/ || /^rna-/) {
         if ($2=="na") $2=0;
         print
     }'  gene_TPM_all_samples.tsv > gene_TPM_all_samples_clean.tsv
