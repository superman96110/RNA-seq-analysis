#这个脚本是用来批量并行运行 fastp，对双端测序数据（paired-end FASTQ）进行质控和过滤的。它会自动识别样本名、控制并行任务数、并为每个样本生成过滤后的 reads 和质控报告

#!/bin/bash

# 设置同时运行的最大并行任务数
MAX_JOBS=8
count=0

# 自动检测样本名前缀（基于 *_1.fq.gz）
shopt -s nullglob
samples=( *_1.fq.gz )
samples=( "${samples[@]/_1.fq.gz/}" )

# 显示找到的样本数量
echo "Found ${#samples[@]} samples to process"

# 遍历所有样本
for sample in "${samples[@]}"; do
    ((count++))
    
    # 显示当前处理进度
    echo -e "\nProcessing ${sample} ($count/${#samples[@]})..."
    
    # 运行 fastp，并放到后台执行
    fastp -W 4 \
        -i "${sample}_1.fq.gz" \
        -I "${sample}_2.fq.gz" \
        -o "${sample}_fastpfilter_1.fq.gz" \
        -O "${sample}_fastpfilter_2.fq.gz" \
        -h "${sample}_fastp.html" \
        -j "${sample}_fastp.json" \
        --cut_tail \
        --cut_mean_quality 20 &
    
    # 控制并行任务数量，每 MAX_JOBS 个任务就等待一次
    if (( count % MAX_JOBS == 0 )); then
        echo "Waiting for current batch to complete..."
        wait  # 等待当前这一批任务完成
    fi
done

# 等待最后一批后台任务完成
wait

echo -e "\nAll ${#samples[@]} samples processed successfully!"
