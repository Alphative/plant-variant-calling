process GWAS {
    publishDir "${params.output}/gwas_results", mode: 'copy'
    input:
    tuple path(bed), path(bim), path (fam)
    path pheno_file

    output:
    path("gwas_results.assoc")

    script:
    """
    plink \\
    --bfile ${bed.baseName} \\
    --pheno ${pheno_file} \\
    --assoc \\
    --allow-no-sex \\
    --allow-extra-chr \\
    --out gwas_results
    """
}