69 server

conda activate bioenv

Using the fastp(v0.24.0), stringtie(v3.0.0), hisat2(v2.2.1), samtools(v1.21) software to analysis the RNA-seq raw data(fastq)


fq (fastp)→ fastpfilter.fq.gz (hisat2)→ bam (stringtie) → gtf (stringtie) → merged.gtf 
