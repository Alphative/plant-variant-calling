process DOWNLOADREADS {
    input:
    tuple val(sample_id), val(fastq_1_url), val(fastq_2_url)

    output:
    tuple val(sample_id), path("${sample_id}_1.fastq.gz"), path("${sample_id}_2.fastq.gz")

    script:
    """
    wget -O ${sample_id}_1.fastq.gz "$fastq_1_url"
    wget -O ${sample_id}_2.fastq.gz "$fastq_2_url"
    """
}