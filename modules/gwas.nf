process GWAS {
    publishDir "${params.output}/gwas_results", mode: 'copy'
    input:
    tuple path(bed), path(bim), path (fam)
    path pheno_file

    output:
    path("gwas_results.assoc.linear")

    script:
    """
    plink \\
    --bfile ${bed.baseName} \\
    --pca 10 \\
    --allow-extra-chr \\
    --out pca_results

    plink \\
    --bfile ${bed.baseName} \\
    --pheno ${pheno_file} \\
    --linear \\
    --covar pca_results.eigenvec \\
    --allow-extra-chr \\
    --out gwas_results
    """
}