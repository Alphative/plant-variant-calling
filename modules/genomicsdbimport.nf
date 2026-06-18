process GDBIMPORT {
    input:
    path gvcfs

    path tbis

    path beds


    output:
    path "${params.athaliana_db}"


    script:
    """
    gatk GenomicsDBImport \\
    -V ${gvcfs.join(' -V ')} \\
    --genomicsdb-workspace-path ${params.athaliana_db} \\
    -L ${beds} \\
    --batch_size 50 
    """
}