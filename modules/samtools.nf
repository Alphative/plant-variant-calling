process SAMTOOLS_SORT {
    tag "$id"
    publishDir "${params.output}/st_sorted", mode: 'copy'

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}.st_sorted.bam*") 

    script:
    """
    samtools sort $bam -o ${id}.st_sorted.bam
    samtools index ${id}.st_sorted.bam
    """
}