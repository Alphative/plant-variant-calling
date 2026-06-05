process FASTQC {
    tag "$id"
    publishDir "${params.output}/fastqc", mode: 'copy'

    input:
    tuple val(id), path(reads)

    output:
    tuple val(id), path("*.html"), path("*.zip")

    script:
    """
    fastqc -o . -t ${task.cpus} ${reads[0]} ${reads[1]}
    """
}