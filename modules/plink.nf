process PLINK {
    publishDir "${params.output}/plink_qc", mode: 'copy'

    input:
    path cohort_vcf

   output:
   tuple path("cohort.qc.bed"), path("cohort.qc.bim"), path("cohort.qc.fam")

    script:
    """
    plink \\
    --vcf ${cohort_vcf} \\
    --maf ${params.maf} \\
    --geno ${params.geno} \\
    --mind ${params.mind} \\
    --allow-extra-chr \\
    --make-bed \\
    --out cohort.qc
    """
}