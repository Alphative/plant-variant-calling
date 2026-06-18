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

Create a `samplesheet.csv` with ENA FTP links:

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

`data/intervals.bed` — genomic regions for GenomicsDBImport:

```
1	1	30427671
2	1	19698289
3	1	23459830
4	1	18585056
5	1	26975502
```

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

## Project Structure

```
plant_variant_calling/
├── main.nf                  # Main Nextflow pipeline
├── nextflow.config          # Pipeline configuration
├── modules/                 # Nextflow process modules
│   ├── download_ref.nf      # Download reference genome
│   ├── download_reads.nf    # Download FASTQ from ENA
│   ├── index_ref.nf         # Index reference (BWA/Samtools/GATK)
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
| `snpeff_db` | `athalianaTair10` | SnpEff database name |