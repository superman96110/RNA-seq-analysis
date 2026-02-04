#!/usr/bin/env python3
#-*- coding:utf-8 -*-

"""
从表达矩阵中(tpmm.txt)中:
1) 解析列名:品种-编号-组织(例如BOE-10-Lung)
2) 统计每个品种拥有的组织集合
3) 求所有品种共有的组织（交集）
4) 提取共有组织对应的所有样本列，输出新矩阵
"""

import argparse
import sys
import pandas as pd


def parse_args():
    p = argparse.ArgumentParser(
        description="Find tissues common to all breeds and extract those columns."
    )
    p.add_argument("-i", "--input", default="tpmm.txt", help="输入表达矩阵文件（tab分隔）")
    p.add_argument("-o", "--output", default="tpmm_common_tissues.txt", help="输出提取后的文件名")
    p.add_argument("-r", "--report", default="common_tissues_report.txt", help="输出报告文件名")
    p.add_argument("--gene-col", default="Gene_Name", help="基因名列名（默认 Gene_Name）")
    return p.parse_args()


def main():
    args = parse_args()

    # 读入
    try:
        df = pd.read_csv(args.input, sep="\t", dtype=str)
    except Exception as e:
        print(f"[ERROR] 读取文件失败: {args.input}\n{e}", file=sys.stderr)
        sys.exit(1)

    if args.gene_col not in df.columns:
        print(f"[ERROR] 找不到基因列: {args.gene_col}", file=sys.stderr)
        print(f"当前列名: {list(df.columns)[:10]} ...", file=sys.stderr)
        sys.exit(1)

    # 样本列
    sample_cols = [c for c in df.columns if c != args.gene_col]
    if not sample_cols:
        print("[ERROR] 没有检测到任何样本列。", file=sys.stderr)
        sys.exit(1)

    # 解析列名：品种-编号-组织（至少应有2个“-”，即3段）
    info = []  # (col, breed, tissue)
    bad_cols = []
    for c in sample_cols:
        parts = c.split("-")
        if len(parts) < 3:
            bad_cols.append(c)
            continue
        breed = parts[0]
        tissue = parts[-1]
        info.append((c, breed, tissue))

    if bad_cols:
        print("[ERROR] 下列列名不符合 '品种-编号-组织' 格式（至少包含2个'-'）：", file=sys.stderr)
        for c in bad_cols[:20]:
            print("  ", c, file=sys.stderr)
        if len(bad_cols) > 20:
            print(f"  ... 还有 {len(bad_cols)-20} 个", file=sys.stderr)
        sys.exit(1)

    breeds = sorted(set(b for _, b, _ in info))
    if len(breeds) < 2:
        print("[WARN] 检测到的品种少于2个，交集意义不大。检测到：", breeds, file=sys.stderr)

    # 每个品种的组织集合
    breed_tissues = {}
    for breed in breeds:
        breed_tissues[breed] = set(t for _, b, t in info if b == breed)

    # 求所有品种共有组织（交集）
    common_tissues = set.intersection(*breed_tissues.values()) if breed_tissues else set()

    # 提取共有组织对应的列
    keep_cols = [args.gene_col] + [c for c, _, t in info if t in common_tissues]
    df_out = df[keep_cols].copy()

    # 输出：尽量保持数值列为数值（除了基因列）
    # 如果你的 tpmm.txt 全是数值（Gene_Name除外），这里会把数值列转回 float
    for c in df_out.columns:
        if c == args.gene_col:
            continue
        df_out[c] = pd.to_numeric(df_out[c], errors="ignore")

    df_out.to_csv(args.output, sep="\t", index=False)

    # 写报告
    with open(args.report, "w", encoding="utf-8") as f:
        f.write(f"Input: {args.input}\n")
        f.write(f"Breeds detected ({len(breeds)}): {', '.join(breeds)}\n\n")

        f.write("Tissues per breed:\n")
        for breed in breeds:
            tissues_sorted = sorted(breed_tissues[breed])
            f.write(f"- {breed} ({len(tissues_sorted)}): {', '.join(tissues_sorted)}\n")

        f.write("\nCommon tissues (intersection):\n")
        f.write(", ".join(sorted(common_tissues)) + "\n")
        f.write(f"\nOutput matrix: {args.output}\n")
        f.write(f"Columns kept (including gene col): {len(keep_cols)}\n")

    # 控制台提示
    print("检测到品种：", breeds)
    print("共有组织：", sorted(common_tissues))
    print("已输出：", args.output)
    print("已输出报告：", args.report)


if __name__ == "__main__":
    main()
