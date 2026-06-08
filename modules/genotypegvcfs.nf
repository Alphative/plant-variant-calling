process GGVCFS {
    input:
    path db
    path refgenome
    path refgenomefai
    path refgenomedict

    output:
    tuple path("cohort.vcf"), path("cohort.vcf.idx")
    script:
    """
    gatk GenotypeGVCFs \\
    -R ${refgenome} \\
    -V gendb://${db} \\
    -O "cohort.vcf"
    """
}