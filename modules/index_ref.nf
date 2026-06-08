process PREPARE_GENOME {
    input:
    path "refgenome.fasta"

    output:
    tuple path("refgenome.fasta"),
          path("refgenome.fasta.fai"),
          path("refgenome.dict"),
          path("refgenome.fasta.amb"),
          path("refgenome.fasta.ann"),
          path("refgenome.fasta.bwt"),
          path("refgenome.fasta.pac"),
          path("refgenome.fasta.sa")

    script:
    """
    bwa index refgenome.fasta

    samtools faidx refgenome.fasta

    gatk CreateSequenceDictionary -R refgenome.fasta -O refgenome.dict
    """
}