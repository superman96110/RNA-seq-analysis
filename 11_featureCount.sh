#准备bam文件（所有bam文件的绝对路径并去重）,准备注释的gtf文件
#(bioenv) [root@localhost counts]# head all_bam_unique.txt
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-10-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-13-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-1-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-2-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-3-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-6-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-8-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/BOE-tissue/hista2_output/BOE-9-G.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/hisat2_output/bam/BOE-10-F.bam
#/mnt/vde/210/GTEX_goat/RNA/Boer/hisat2_output/bam/BOE-10-G.bam

#安装featureCount
conda activate bioenv
conda install -c bioconda subread



#vim run_fc.sh
#!/bin/bash

cat all_bam_unique.txt | xargs featureCounts -T 8 -p -s 0 \
  -t exon -g gene_id \
  -a genomic.gtf \
  -o all_gene_counts.txt
