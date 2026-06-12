####
#imports
####

import argparse
import logging
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

####
#LOGS
####

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s | %(levelname)s] %(message)s',
    datefmt='%H:%M:%S')
logger=logging.getLogger(__name__)

####
#defs
####

def load_gwas(file_path):
    logger.info(f"Loading GWAS results from {file_path}...")
    df = pd.read_csv(file_path, sep=r'\s+')
    df = df[df['TEST'] == 'ADD']
    logger.info(f"Successfully loaded {len(df)} SNPs after filtering")
    return df

def load_annotations(file_path):
    logger.info(f"Loading annotations from {file_path} started...")
    df = pd.read_csv(file_path, sep=r'\t', comment = '#')
    logger.info(f"Successfully loaded {len(df)} annotation records.")
    return df

def merge_data(gwas_df, annot_df, p_threshold=1e-5):
    sig_gwas = gwas_df[gwas_df['P'] < p_threshold]
    merged = pd.merge(sig_gwas, annot_df, on='CHR')
    merged = merged[(merged['BP'] >= merged['START']) & (merged['BP'] <= merged['END'])]
    logger.info(f"Successfully aligned {len(merged)} SNPs")
    return merged 

def save_results(df, output_path):
    logger.info(f"File saving inititated")
    df.to_csv(output_path, sep = '\t', index = False)
    logger.info(f"File successfully saved to {output_path}")

def plot_top_genes(df, output_path, gene_col = "GENE_ID"):
    top_genes = df[gene_col].value_counts().head(10)
    sns.barplot(x=top_genes.values, y=top_genes.index)
    plt.title("Top 10 Genes by Variant Count")
    plt.xlabel("Number of SNPs")
    plt.ylabel("Gene ID")
    plt.savefig(output_path)
    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Pipeline for GWAS and Annotation merge")
    parser.add_argument('--gwas', required=True, help="Path to the GWAS results file")
    parser.add_argument('--annot', required=True, help="Path to the annotation file (GFF/GTF/TSV)")
    parser.add_argument('--p-thresh', type=float, default=1e-5, help="P-value threshold for filtering significant SNPs")
    parser.add_argument('--output', required=True, help="Path to save the filtered and merged TSV table")
    parser.add_argument('--plot', required=True, help="Path to save the top genes barplot (PNG)")
    args=parser.parse_args()

    gwas_df = load_gwas(args.gwas)
    annot_df = load_annotations(args.annot)
    merged_df = merge_data(gwas_df, annot_df, args.p_thresh)
    if merged_df.empty:
        logger.warning("No SNPs passed the threshold. Pipeline stopped.")
        return
    save_results(merged_df, args.output)
    plot_top_genes(merged_df, args.plot)
    
    
if __name__ == '__main__':
    main()