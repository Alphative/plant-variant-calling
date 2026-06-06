process BWA_MEM {
    tag "$id"

    input:
    tuple val(id), path(reads)
    path ref_fasta
    path ref_indices

    output:
    tuple val(id), path("${id}.aligned.bam")

    script:
    """
    bwa mem -t ${task.cpus} $ref_fasta ${reads[0]} ${reads[1]} | samtools view -Sb - > ${id}.aligned.bam
    """
}