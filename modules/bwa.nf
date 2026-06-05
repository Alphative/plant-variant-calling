process BWA {
    tag "$id"

    input:
    tuple val(id), path(reads)
    path fasta
    path indices

    output:
    tuple val(id), path("${id}.aligned.bam")

    script:
    """
    bwa mem $fasta ${reads[0]} ${reads[1]} | samtools view -bS - > ${id}.aligned.bam
    """
}