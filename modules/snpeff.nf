process SNPEFF {
    publishDir "${params.output}/snpeff", mode: 'copy'
    
    input:
    val db_name 
    tuple path(filtredvcf), path(filtredidx)

    output:
    path("cohort.ann.vcf")
    path("snpEff_summary.html")

    script:
    """
    snpEff -v ${db_name} \\
    -s snpEff_summary.html \\
    ${filtredvcf} > cohort.ann.vcf
    """
}