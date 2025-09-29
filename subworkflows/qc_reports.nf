#!/usr/bin/env nextflow

// FastQC and MultiQC reports with aliases for different stages
include { FASTQC as FASTQC_RAW }             from '../modules/fastqc.nf'
include { FASTQC as FASTQC_TRIM }            from '../modules/fastqc.nf'

include { MULTIQC as MULTIQC_RAW }           from '../modules/multiqc.nf'
include { MULTIQC as MULTIQC_TRIM }          from '../modules/multiqc.nf'
include { MULTIQC as MULTIQC_FASTP }         from '../modules/multiqc.nf'


workflow QC_REPORTS {

    take:
        short_reads_raw         // [meta, r1, r2]
        trimmed_reads           // [meta, r1, r2]
        fastp_reports           // [meta, html, json]

    main:
    ////////////////////////////////////////////////////////////////////////////////
    // Raw short reads
    ////////////////////////////////////////////////////////////////////////////////

    sr_raw_reads = short_reads_raw.flatMap { meta, r1, r2 -> 
        [ tuple(meta, r1), tuple(meta, r2) ] 
    }

    FASTQC_RAW(sr_raw_reads)
    MULTIQC_RAW(FASTQC_RAW.out.fastqc_files.collect().ifEmpty([]))

    ////////////////////////////////////////////////////////////////////////////////
    // Trimmed short reads
    ////////////////////////////////////////////////////////////////////////////////

    trimmed_reads_for_fastqc = trimmed_reads.flatMap { meta, r1, r2 -> 
        [ tuple(meta, r1), tuple(meta, r2) ] 
    }

    FASTQC_TRIM(trimmed_reads_for_fastqc)
    MULTIQC_TRIM(FASTQC_TRIM.out.fastqc_files.collect().ifEmpty([]))

    ////////////////////////////////////////////////////////////////////////////////
    // Fastp JSON reports (used by MultiQC)
    ////////////////////////////////////////////////////////////////////////////////

    multiqc_input_fastp = fastp_reports.map { meta, html, json -> json }.collect()
    MULTIQC_FASTP(multiqc_input_fastp)


    emit:
        fastqc_raw      = FASTQC_RAW.out.fastqc_files
        fastqc_trim     = FASTQC_TRIM.out.fastqc_files

        multiqc_raw     = MULTIQC_RAW.out.multiqc_report
        multiqc_trim    = MULTIQC_TRIM.out.multiqc_report
        multiqc_fastp   = MULTIQC_FASTP.out.multiqc_report
}