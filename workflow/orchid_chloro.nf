#!/usr/bin/env nextflow

include { TRIM_READS }                  from '../subworkflows/trim_reads.nf'
include { FASTQ_VALIDATION_STATS }      from '../subworkflows/check_fastq.nf'
include { QC_REPORTS }                  from '../subworkflows/qc_reports.nf'

workflow ORCL_PIPELINE {

    take:
        short_reads

    main:

        ////////////////////////////////////////////////////////////////////////////
        // 1. Trim
        ////////////////////////////////////////////////////////////////////////////
        TRIM_READS(short_reads)

        ////////////////////////////////////////////////////////////////////////////
        // 4. Stats and QC
        ////////////////////////////////////////////////////////////////////////////
        FASTQ_VALIDATION_STATS(
            short_reads,
            TRIM_READS.out.trimmed_reads,
        )

        QC_REPORTS(
            short_reads,
            TRIM_READS.out.trimmed_reads,
            TRIM_READS.out.fastp_reports,
        )       
}