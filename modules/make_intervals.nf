process GENERATE_INTERVALS {
    container 'plant-variant-calling'

    input:
    path fai_file

    output:
    path "intervals.bed"

    script:
    """
    awk 'BEGIN {OFS="\t"} {print \$1, 0, \$2}' ${fai_file} > intervals.bed
    """
}