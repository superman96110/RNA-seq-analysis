awk '
BEGIN{FS=OFS="\t"}
NR==1{
    printf $1
    for(i=2;i<=NF;i++){
        split($i,a,"-")
        tissue=a[length(a)]
        col[i]=tissue"\t"$i
    }
    n=asort(col,sorted)
    for(j=1;j<=n;j++){
        split(sorted[j],b,"\t")
        printf OFS b[2]
    }
    printf "\n"
    next
}
{print}
' tpmm.txt > tpmm_sorted_by_tissue.txt
