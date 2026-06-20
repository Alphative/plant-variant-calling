nextflow.enable.dsl=2

include { ADD_RG } from './modules/add_read_groups.nf'
include { BWA_MEM } from './modules/bwa.nf'
include { DOWNLOADREF } from './modules/download_ref.nf'
include { FASTP } from './modules/fastp.nf'
include { FASTQC } from './modules/fastqc.nf'
include { FILTER_VARIANTS } from './modules/filter_variants.nf'
include { GENERATE_INTERVALS } from './modules/make_intervals.nf'
include { GDBIMPORT } from './modules/genomicsdbimport.nf'
include { GGVCFS } from './modules/genotypegvcfs.nf'
include { GWAS } from './modules/gwas.nf'
include { HTC } from './modules/haplotypecaller.nf'
include { PREPARE_GENOME } from './modules/index_ref.nf'
include { MD } from './modules/mark_duplicates.nf'
include { PLINK } from './modules/plink.nf'
include { POSTGWAS } from './modules/post_gwas.nf'
include { SAMTOOLS_SORT } from './modules/samtools.nf'
include { SNPEFF } from './modules/snpeff.nf'

workflow {
    // ----- 1. Strict validation of ALL required parameters -----
    if (!params.samplesheet)  error "Missing required parameter: samplesheet"
    if (!params.fasta_url)    error "Missing required parameter: fasta_url"
    if (!params.gff_url)      error "Missing required parameter: gff_url"
    if (!params.pheno_file)   error "Missing required parameter: pheno_file"
    if (!params.athaliana_db) error "Missing required parameter: athaliana_db"
    if (!params.snpeff_db)    error "Missing required parameter: snpeff_db"

    // ----- 2. Input data initialization -----
    ch_samplesheet = channel.fromPath(params.samplesheet).splitCsv(header: true)

    // ----- 3. Reference downloading and channel distribution -----
    ch_ref_out = DOWNLOADREF(params.fasta_url, params.gff_url)
    ch_genome_ref = ch_ref_out[0]
    ch_gff        = ch_ref_out[1]

    // ----- 4. Genome indexing and safe file extraction -----
    ch_genome_idx = PREPARE_GENOME(ch_genome_ref).first()

    ch_fasta       = ch_genome_idx.map { idx -> idx[0] }
    ch_fai         = ch_genome_idx.map { idx -> idx[1] }
    ch_dict        = ch_genome_idx.map { idx -> idx[2] }
    ch_bwa_indices = ch_genome_idx.map { idx -> idx[3..7] }

    // ----- 5. Raw reads processing (QC and Trimming) -----
    ch_formatted_reads = ch_samplesheet.map { row -> 
        [ row.sample_id, [ file(row.fastq_1_url), file(row.fastq_2_url) ] ] 
    }

    FASTQC(ch_formatted_reads)
    ch_trimmed_reads = FASTP(ch_formatted_reads)

    // ----- 6. Alignment to reference genome (BWA MEM) -----
    ch_bwa_inputs = ch_trimmed_reads.map { id, r1, r2, _html, _json -> [id, [r1, r2]] }
    ch_aligned_bams = BWA_MEM(ch_bwa_inputs, ch_fasta, ch_bwa_indices)

    // ----- 7. BAM post-processing (Sort, Read Groups, Mark Duplicates) -----
    ch_sorted_bams = SAMTOOLS_SORT(ch_aligned_bams)
    ch_rg_bams     = ADD_RG(ch_sorted_bams)
    ch_md_bams     = MD(ch_rg_bams)

    // ----- 8. Per-sample variant calling (HaplotypeCaller) -----
    ch_htc_bam_inputs = ch_md_bams.map { id, bam, _metrics, bai -> [id, bam, bai] }
    ch_gvcfs = HTC(ch_fasta, ch_fai, ch_dict, ch_htc_bam_inputs)

    // ----- 9. Safe splitting and collection of GVCFs for GenomicsDB -----
    ch_split_gvcfs = ch_gvcfs.multiMap { _id, vcf, idx ->
        vcf_ch: vcf
        tbi_ch: idx
    }
    ch_all_gvcfs = ch_split_gvcfs.vcf_ch.collect()
    ch_all_tbis  = ch_split_gvcfs.tbi_ch.collect()

    ch_gdb_bed = GENERATE_INTERVALS(ch_fai)

    // ----- 10. Cohort analysis (GDBIMPORT arguments aligned with module) -----
    ch_genomics_db = GDBIMPORT(ch_all_gvcfs, ch_all_tbis, ch_gdb_bed)
    ch_cohort_vcf  = GGVCFS(ch_genomics_db, ch_fasta, ch_fai, ch_dict)

    // ----- 11. Variant filtration and functional annotation -----
    ch_filtered_vcf = FILTER_VARIANTS(ch_fasta, ch_fai, ch_dict, ch_cohort_vcf)
    
    ch_filtered_tuple = ch_filtered_vcf.map { vcf -> [vcf, file(vcf.toString() + ".idx")] } 
    
    ch_annotated_vcf = SNPEFF(params.snpeff_db, ch_filtered_tuple)

    // ----- 12. Genetic analysis (PLINK and GWAS) -----
    ch_plink_out = PLINK(ch_annotated_vcf[0])
    ch_pheno     = channel.fromPath(params.pheno_file).first()
    
    ch_gwas_results = GWAS(ch_plink_out, ch_pheno)

    // ----- 13. Final visualization (Manhattan and QQ plots) -----
    POSTGWAS(ch_gwas_results, ch_gff)
}