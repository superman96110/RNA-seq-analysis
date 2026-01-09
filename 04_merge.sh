#在对应品种的gtf文件夹下
#将stringtie_out的文件夹下，将所有的gtf文件，输出绝对路径输出到txt文件中，最终合并到一个mergelist.txt
#pwd | sed 's#$#/#' | xargs -I {} ls *.gtf | sed "s#^#$(pwd)/#" > XD.txt

#!/bin/bash
#conda activate bioenv

ref_anno="/mnt/vde/210//GTEX_goat/RNA/ref/genomic.gff"
mergelist="/mnt/vde/210/GTEX_goat/RNA/merge/mergelist.txt"
outdir="/mnt/vde/210/GTEX_goat/RNA/merge/stringtie_merge"
mkdir -p "$outdir"

stringtie --merge -p 10 \
  -G "$ref_anno" \
  -o "${outdir}/stringtie_merged.gtf" \
  "$mergelist"
