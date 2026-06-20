process POSTGWAS {
    input:
    path gwas_results
    path gff_annot

    output:
    path "barplot.png", emit: barplot
    path "qq.png", emit: qq
    path "manhattan.png", emit: manhattan
    path "postgwas.tsv", emit: postgwas

    script:
    """
    python /app/source/post_gwas.py \\
    --gwas $gwas_results \\
    --annot $gff_annot \\
    --output postgwas.tsv \\
    --plot barplot.png \\
    --manhattan manhattan.png \\
    --qq qq.png \\
    --p-thresh ${params.p_thresh}
    """
}