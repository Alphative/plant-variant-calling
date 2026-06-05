process FASTP {
    tag "$id"
    publishDir "${params.output}/fastp", mode: 'copy'

    input:
    tuple val(id), path(reads)

    output:
    tuple val(id), path("${id}_trimmed_R1.fastq.gz"), path("${id}_trimmed_R2.fastq.gz"), path("${id}.fastp.html"), path("${id}.fastp.json")

    script:
    """
    fastp \
        -i ${reads[0]} -I ${reads[1]} \
        -o ${id}_trimmed_R1.fastq.gz -O ${id}_trimmed_R2.fastq.gz \
        --html ${id}.fastp.html --json ${id}.fastp.json \
        --thread ${task.cpus}
    """
}