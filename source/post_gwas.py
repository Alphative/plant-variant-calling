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
# LOGS
####

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s | %(levelname)s] %(message)s',
    datefmt='%H:%M:%S')
logger = logging.getLogger(__name__)

####
# defs
####

def load_gwas(file_path):
    logger.info(f"Loading GWAS results from {file_path}...")
    df = pd.read_csv(file_path, sep=r'\s+')
    df = df[df['TEST'] == 'ADD']
    logger.info(f"Successfully loaded {len(df)} SNPs after filtering")
    return df

def load_annotations(file_path):
    logger.info(f"Loading annotations from {file_path} started...")
    df = pd.read_csv(file_path, sep=r'\t', comment='#')
    logger.info(f"Successfully loaded {len(df)} annotation records.")
    return df

def downsample_gwas(df, p_threshold=1e-5, keep_frac=0.01):
    logger.info("Downsampling background SNPs for visualization...")
    
    significant = df[df['P'] < p_threshold]
    
    background = df[df['P'] >= p_threshold]
    if not background.empty:
        background = background.sample(frac=keep_frac, random_state=42)
        
    light_df = pd.concat([significant, background]).sort_values(['CHR', 'BP'])
    logger.info(f"Reduced dataframe size from {len(df)} to {len(light_df)} SNPs for plotting")
    return light_df

def plot_manhattan(df, output_path, p_threshold=1e-5):
    logger.info("Generating Manhattan plot...")
    plot_data = df.copy()
    plot_data['-log10P'] = -np.log10(plot_data['P'])
    plot_data = plot_data.sort_values(['CHR', 'BP'])
    
    fig, ax = plt.subplots(figsize=(12, 6))
    colors = ['#4E79A7', '#F28E2B']
    
    ticks = []
    labels = []
    last_pos = 0
    
    for i, chrom in enumerate(sorted(plot_data['CHR'].unique())):
        chrom_df = plot_data[plot_data['CHR'] == chrom]
        if chrom_df.empty:
            continue

        positions = chrom_df['BP'] + last_pos
        ax.scatter(positions, chrom_df['-log10P'], c=colors[i % 2], alpha=0.6, edgecolors='none', s=15)

        ticks.append(last_pos + (chrom_df['BP'].max() - chrom_df['BP'].min()) / 2)
        labels.append(str(chrom))
        
        last_pos = positions.max()
        
    ax.set_xticks(ticks)
    ax.set_xticklabels(labels)
    ax.set_title("GWAS Manhattan Plot (Downsampled Background)")
    ax.set_xlabel("Chromosome")
    ax.set_ylabel("-log10(P)")

    plt.axhline(y=-np.log10(p_threshold), color='r', linestyle='--', alpha=0.5)
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()

def plot_qq(df, output_path):
    logger.info("Generating Q-Q plot...")
    n = len(df)
    if n == 0:
        logger.warning("Empty dataframe, skipping Q-Q plot")
        return
        
    observed = -np.log10(np.sort(df['P']))
    expected = -np.log10(np.arange(1, n + 1) / (n + 1))[::-1]
    
    plt.figure(figsize=(6, 6))
    plt.scatter(expected, observed, c='#4E79A7', alpha=0.6, edgecolors='none', s=15)
    
    max_val = max(expected.max(), observed.max())
    plt.plot([0, max_val], [0, max_val], color='red', linestyle='--')
    
    plt.title("Q-Q Plot")
    plt.xlabel("Expected -log10(P)")
    plt.ylabel("Observed -log10(P)")
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()

def merge_data(gwas_df, annot_df, p_threshold=1e-5):
    sig_gwas = gwas_df[gwas_df['P'] < p_threshold]
    merged = pd.merge(sig_gwas, annot_df, on='CHR')
    merged = merged[(merged['BP'] >= merged['START']) & (merged['BP'] <= merged['END'])]
    logger.info(f"Successfully aligned {len(merged)} SNPs")
    return merged 

def save_results(df, output_path):
    logger.info("File saving initiated")
    df.to_csv(output_path, sep='\t', index=False)
    logger.info(f"File successfully saved to {output_path}")

def plot_top_genes(df, output_path, gene_col="GENE_ID"):
    top_genes = df[gene_col].value_counts().head(10)
    sns.barplot(x=top_genes.values, y=top_genes.index)
    plt.title("Top 10 Genes by Variant Count")
    plt.xlabel("Number of SNPs")
    plt.ylabel("Gene ID")
    plt.savefig(output_path)
    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Post-GWAS Analysis and Annotation Pipeline")
    parser.add_argument('--gwas', required=True, help="Path to the GWAS results file")
    parser.add_argument('--annot', required=True, help="Path to the annotation file (GFF/GTF/TSV)")
    parser.add_argument('--p-thresh', type=float, default=1e-5, help="P-value threshold for filtering significant SNPs")
    parser.add_argument('--output', required=True, help="Path to save the filtered and merged TSV table")
    parser.add_argument('--plot', required=True, help="Path to save the top genes barplot (PNG)")
    parser.add_argument('--manhattan', required=True, help="Path to save the Manhattan plot (PNG)")
    parser.add_argument('--qq', required=True, help="Path to save the Q-Q plot (PNG)")
    args = parser.parse_args()

    gwas_df = load_gwas(args.gwas)
    
    light_gwas = downsample_gwas(gwas_df, p_threshold=args.p_thresh, keep_frac=0.01)
    plot_manhattan(light_gwas, args.manhattan, args.p_thresh)
    plot_qq(light_gwas, args.qq)
    
    annot_df = load_annotations(args.annot)
    merged_df = merge_data(gwas_df, annot_df, args.p_thresh)
    
    if merged_df.empty:
        logger.warning("No SNPs passed the threshold. Pipeline stopped.")
        return
        
    save_results(merged_df, args.output)
    plot_top_genes(merged_df, args.plot)

if __name__ == '__main__':
    main()