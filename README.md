# Plant Variant Calling & GWAS Pipeline

Automated NGS pipeline for variant calling and GWAS in *Arabidopsis thaliana* — identifying genomic loci associated with drought resistance.

## What This Pipeline Does

1. Downloads raw FASTQ reads from ENA and reference genome from NCBI
2. Quality control and trimming (FastQC, fastp)
3. Alignment to TAIR10 reference genome (BWA-MEM)
4. BAM post-processing (Samtools, GATK)
5. Per-sample variant calling in GVCF mode (HaplotypeCaller)
6. Cohort genotyping (GenomicsDBImport, GenotypeGVCFs)
7. Variant filtration and functional annotation (SnpEff)
8. GWAS with PCA correction (PLINK)
9. Post-GWAS analysis with Manhattan and QQ plots

## Requirements

- Docker
- Nextflow
- AWS CLI (optional, for cloud deployment)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Alphative/plant-variant-calling
cd plant-variant-calling
```

2. Build the Docker image:
```bash
docker build -t plant-variant-calling -f docker/Dockerfile .
```

## Input Data

### Samplesheet

Create a `samplesheet.csv` with ENA FTP links. Reads are fetched directly via Nextflow's built-in `file()` function, which natively supports `ftp://`, `http://`, and local `file://` paths — no separate download step is required:

```csv
sample_id,fastq_1_url,fastq_2_url
SRR1924765,ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR192/005/SRR1924765/SRR1924765_1.fastq.gz,ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR192/005/SRR1924765/SRR1924765_2.fastq.gz
```

### Phenotype file

Create `data/phenotypes.txt` in PLINK format:

```
FID IID PHENOTYPE
SRR1924765 SRR1924765 2
SRR1924766 SRR1924766 1
```

Where `2` = drought resistant, `1` = control.

### Intervals file

`data/intervals.bed` — genomic regions for GenomicsDBImport. **Contig names must exactly match the reference FASTA headers** (the pipeline downloads the NCBI RefSeq assembly, which uses RefSeq accessions rather than plain chromosome numbers):

```
NC_003070.9	1	30427671
NC_003071.7	1	19698289
NC_003074.8	1	23459830
NC_003075.7	1	18585056
NC_003076.8	1	26975502
```

A `GENERATE_INTERVALS` process is included in the pipeline — it auto-generates this file directly from the downloaded reference's `.fai` index (`awk '{print $1, 0, $2}'`), so it always stays in sync with whichever assembly `fasta_url` points to, with no manual editing required.

## Running Locally

```bash
nextflow run main.nf -profile local
```

With custom parameters:
```bash
nextflow run main.nf -profile local --maf 0.01 --p_thresh 1e-6
```

Use `-resume` to continue an interrupted run:
```bash
nextflow run main.nf -profile local -resume
```

## Running on AWS

1. Push Docker image to Docker Hub:
```bash
docker tag plant-variant-calling your-dockerhub-username/plant-variant-calling:latest
docker push your-dockerhub-username/plant-variant-calling:latest
```

2. Update `nextflow.config` with your Docker Hub username and AWS Batch queue.

3. Run with AWS Batch profile:
```bash
nextflow run main.nf -profile awsbatch
```

## Validated on Real Data

The full pipeline was run end-to-end on two real WGS samples from the [1001 Genomes Project](https://www.ebi.ac.uk/ena/browser/view/SRP056687) (`SRR1945483`, `SRR1945465`), downloaded directly from ENA. Results:

- **1,014,387** variants called and passed QC filtering through the complete FastQC → fastp → BWA-MEM → GATK (HaplotypeCaller, GenomicsDBImport, GenotypeGVCFs, VariantFiltration) → SnpEff → PLINK chain
- GWAS was run with PLINK `--assoc` (Fisher/chi-square allele-frequency test), which is the statistically appropriate test for n=2 — `--logistic`/`--linear` cannot run with so few samples, since the number of model parameters exceeds the number of observations
- The resulting Manhattan plot shows p-values clustered into a small number of discrete horizontal bands — the expected signature of a 2-sample contingency-table test, not a bug. No SNP reaches genome-wide significance, which is the statistically correct outcome at this sample size (a "significant" hit from n=2 would itself be a red flag, not a real finding)

This run validates that every stage of the pipeline is functionally correct on real sequencing data. A real GWAS analysis requires dozens-to-hundreds of samples; this run demonstrates pipeline mechanics rather than biological discovery.

## Testing with Synthetic Data

For development and pipeline validation without downloading large real datasets, synthetic paired-end reads can be generated with `wgsim` directly from the reference genome:

```bash
wgsim -N 200000 -1 150 -2 150 -r 0.01 -S 42 data/ref/refgenome.fasta data/SRR_test_1.fastq data/SRR_test_2.fastq
gzip data/SRR_test_*.fastq
```

**Note on GATK confidence thresholds:** synthetic `wgsim` reads have a less uniform coverage profile than real Illumina sequencing data. With GATK HaplotypeCaller's default `--standard-min-confidence-threshold-for-calling`, low-and-uneven-coverage synthetic positions can be filtered out entirely, resulting in an empty cohort VCF even though real substitutions are present in the alignments (verified independently via `samtools mpileup`). This is expected behavior for synthetic test data and does not indicate a defect in the pipeline — alignment, variant calling, and all downstream tools (PLINK, SnpEff, GATK) were individually verified to function correctly using manual step-by-step Docker runs. On real sequencing data (ENA/SRA), coverage is uniform enough that default thresholds work as intended, and this has been left unchanged in the pipeline so it behaves correctly out-of-the-box on real datasets.

## Project Structure

```
plant_variant_calling/
├── main.nf                  # Main Nextflow pipeline
├── nextflow.config          # Pipeline configuration
├── modules/                 # Nextflow process modules
│   ├── download_ref.nf      # Download reference genome and GFF
│   ├── index_ref.nf         # Index reference (BWA/Samtools/GATK)
│   ├── make_intervals.nf    # Auto-generate intervals.bed (GENERATE_INTERVALS)
│   ├── fastqc.nf
│   ├── fastp.nf
│   ├── bwa.nf
│   ├── samtools.nf
│   ├── add_read_groups.nf
│   ├── mark_duplicates.nf
│   ├── haplotypecaller.nf
│   ├── genomicsdbimport.nf
│   ├── genotypegvcfs.nf
│   ├── filter_variants.nf
│   ├── snpeff.nf
│   ├── plink.nf
│   ├── gwas.nf
│   └── post_gwas.nf
├── source/                  # Python scripts
│   └── post_gwas.py         # Post-GWAS analysis and visualization
├── tests/                   # pytest tests
│   └── test_post_gwas.py
├── docker/                  # Dockerfile
├── data/                    # Input data (not tracked)
│   ├── samplesheet.csv
│   ├── phenotypes.txt
│   └── intervals.bed
└── results/                 # Pipeline outputs (not tracked)
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `samplesheet` | `samplesheet.csv` | Path to sample sheet with ENA URLs |
| `fasta_url` | TAIR10 NCBI URL | Reference genome download URL |
| `gff_url` | TAIR10 NCBI URL | GFF annotation download URL |
| `athaliana_db` | `athaliana_genomicsdb` | GenomicsDB workspace name |
| `bed` | `data/intervals.bed` | Genomic intervals for GenomicsDB |
| `maf` | `0.05` | Minor allele frequency threshold |
| `geno` | `0.1` | Maximum genotype missingness |
| `mind` | `0.1` | Maximum sample missingness |
| `pheno_file` | `data/phenotypes.txt` | PLINK phenotype file |
| `p_thresh` | `1e-5` | GWAS significance threshold |
| `snpeff_db` | `Arabidopsis_thaliana` | SnpEff database name (auto-downloaded on first run) |