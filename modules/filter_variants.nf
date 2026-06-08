process FILTER_VARIANTS {
    publishDir "${params.output}/filter_variants", mode: 'copy'

    input: 
    path "genome.fasta"
    path "genome.fasta.fai"
    tuple path(vcf), path(idx)

    output:
    tuple path("cohort.filtered.vcf"), path("cohort.filtered.vcf.idx")

    script:
    """
    gatk VariantFiltration \\
        -R genome.fasta \\
        -V $vcf \\
        -O cohort.filtered.vcf \\
        --filter-expression "QD < 2.0" \\
        --filter-name "LowQD" \\
        --filter-expression "FS > 60.0" \\
        --filter-name "StrandBias" \\
        --filter-expression "MQ < 40.0" \\
        --filter-name "LowMappingQual"
    """
}