process FILTER_VARIANTS {
    container 'plant-variant-calling'

    input:
    path genome
    path fai
    path dict
    tuple path(vcf), path(idx)

    output:
    path "cohort.filtered.vcf"

    script:
    """
    gatk VariantFiltration \
        -R ${genome} \
        -V ${vcf} \
        -O cohort.filtered.vcf \
        --filter-expression "QD < 2.0" \
        --filter-name "LowQD" \
        --filter-expression "FS > 60.0" \
        --filter-name "StrandBias" \
        --filter-expression "MQ < 40.0" \
        --filter-name "LowMappingQual"
    """
}