process DOWNLOADREF {
    input:
    val fasta_url
    val gff_url

    output:
    path "reference.fasta", emit: fasta
    path "reference.gff", emit: gff

    script:
    """
    wget -O reference.fasta.gz \\
    "$fasta_url"

    wget -O reference.gff.gz \\
    "$gff_url"

    gunzip reference.fasta.gz
    gunzip reference.gff.gz
    """
}