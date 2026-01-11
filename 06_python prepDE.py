awk 'BEGIN{OFS="\t"} {print $1, $2"/"$1".gtf"}' sample_list.txt > sample_list.gtf.txt
prepDE.py -i samplelist.txt
