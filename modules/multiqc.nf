#!/usr/bin/env nextflow

process MULTIQC {

    label "qc"
    tag "multiqc"

    container params.images.QC

    input:
    file('reports/*')

    output:
    tuple path("multiqc_report.html"), path("multiqc_data"), 
    emit:multiqc_report

    script:
    """
    multiqc reports
    """
}