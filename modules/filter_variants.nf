process FILTER_VARIANTS {
    tag "$id"
    publishDir "${params.output}/filter_variants", mode: 'copy'

    input: 
    path "genome.fasta"
    path "genome.fasta.fai"
    tuple val(id), path(vcf), path(idx)

    output:
    tuple val(id), path("${id}.filtered.vcf"), path("${id}.filtered.vcf.idx")

    script:
    """
    gatk VariantFiltration \\
        -R genome.fasta \\
        -V $vcf \\
        -O ${id}.filtered.vcf \\
        --filter-expression "QD < 2.0" \\
        --filter-name "LowQD" \\
        --filter-expression "FS > 60.0" \\
        --filter-name "StrandBias" \\
        --filter-expression "MQ < 40.0" \\
        --filter-name "LowMappingQual"
    """
}