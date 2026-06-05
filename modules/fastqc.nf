process FASTQC {
    tag "$id"
    publishDir "${params.output}/qc/fastqc", mode: 'copy'

    input:
    tuple val(id), path(reads)

    output:
    path "*{html,zip}"

    script:
    """
    fastqc $reads
    """
}