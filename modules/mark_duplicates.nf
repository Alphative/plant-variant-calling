process MD {
    tag "$id"
    publishDir "${params.output}/qc/mark_duplicates", mode: 'copy', pattern: "*.txt"

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}.md.bam"), path("${id}.metrics.txt"), path("${id}.md.bai")
    
    script:
    """
    gatk MarkDuplicates \\
        -I $bam \\
        -O ${id}.md.bam \\
        -M ${id}.metrics.txt \\
        --CREATE_INDEX true
    """
}