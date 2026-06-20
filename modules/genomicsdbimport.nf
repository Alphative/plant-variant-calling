process GDBIMPORT {
    input:
    path gvcfs
    path tbis
    path bed

    output:
    path "${params.athaliana_db}"

    script:
    def vcf_args = gvcfs.collect { vcf -> "-V ${vcf}" }.join(' ')
    """
    gatk GenomicsDBImport \
        ${vcf_args} \
        --genomicsdb-workspace-path ${params.athaliana_db} \
        -L ${bed} \
        --batch-size 50
    """
}