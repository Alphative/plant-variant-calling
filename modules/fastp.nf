process FASTP {
    tag "$id"
    publishDir "${params.output}/trimmed", mode: 'copy'

    input:
    tuple val(id), path(reads)

    output:
    tuple val(id), path("${id}_{1,2}.trimmed.fastq.gz")

    script:
    """
    fastp \
    -i ${reads[0]} \
    -I ${reads[1]} \
    -o ${id}_1.trimmed.fastq.gz \
    -O ${id}_2.trimmed.fastq.gz
    """
}