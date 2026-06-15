process DOWNLOADREF {
    input:
    val fasta_url
    val gff_url

    output:
    path "reference.fasta"
    path "reference.gff"

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