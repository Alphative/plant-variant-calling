process HTC {
    tag "$id"
    publishDir "${params.output}/variants", mode: 'copy'

    input:
    path "genome.fasta"
    path "genome.fasta.fai"
    path "genome.dict"
    tuple val(id), path(bam), path(bai)

    output:
    tuple val(id), path("${id}.htc.vcf"), path("${id}.htc.vcf.idx")

    script:
    """
    gatk HaplotypeCaller \
        -R genome.fasta \
        -I $bam \
        -O ${id}.htc.vcf
    """
}