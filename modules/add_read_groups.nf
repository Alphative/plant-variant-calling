process ADD_RG {
    tag "$id"

    input:
    tuple val(id), path(bam), path(bai)

    output:
    tuple val(id), path("${id}.rg.bam")

    script:
    """
    gatk AddOrReplaceReadGroups \\
        -I $bam \\
        -O ${id}.rg.bam \\
        -RGID $id \\
        -RGLB lib1 \\
        -RGPL illumina \\
        -RGPU unit1 \\
        -RGSM $id
    """
}