#!/usr/bin/env nextflow

process TRIM {

    label "trim"

    tag "${meta.sample}"

    publishDir params.res.trim, mode: 'symlink', pattern: "*.fastq.gz"

    container params.images.QC

    input:
    tuple val(meta), path(read1), path(read2)

    output:
    tuple val(meta),
        path("${meta.sample}-R1.trim.fastq.gz"),
        path("${meta.sample}-R2.trim.fastq.gz"),
        emit: trimmed_reads

    tuple val(meta),
        path("${meta.sample}-fastp.html"),
        path("${meta.sample}-fastp.json"),
        emit: fastp_reports

    script:
    """
    fastp \\
        --in1 ${read1} \\
        --in2 ${read2} \\
        --out1 ${meta.sample}-R1.trim.fastq.gz \\
        --out2 ${meta.sample}-R2.trim.fastq.gz \\
        --html ${meta.sample}-fastp.html \\
        --json ${meta.sample}-fastp.json \\
        --thread ${task.cpus} \\
        --average_qual ${params.trim.avg_qual} \\
        --length_required ${params.trim.len_req} \\
        --trim_poly_x \\
        --detect_adapter_for_pe \\
        --dedup
    """
}
