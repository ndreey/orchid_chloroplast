#!/usr/bin/env nextflow

// Validation
include { VALIDATE_PE as VALIDATE_PE_RAW }                from '../modules/validate_fastq.nf'
include { MERGE_VALI_RES as MERGE_VALI_RES_RAW }          from '../modules/validate_fastq.nf'

include { VALIDATE_PE as VALIDATE_PE_TRIM }               from '../modules/validate_fastq.nf'
include { MERGE_VALI_RES as MERGE_VALI_RES_TRIM }         from '../modules/validate_fastq.nf'

// Stats
include { FASTQ_STATS as FASTQ_STATS_SR_RAW }             from '../modules/seq_stats.nf'
include { FASTQ_STATS as FASTQ_STATS_SR_TRIM }            from '../modules/seq_stats.nf'


workflow FASTQ_VALIDATION_STATS {

    take:
        short_reads_raw
        short_reads_trim

    main:

    ////////////////////////////////////////////////////////////////////////////////
    // Raw reads
    ////////////////////////////////////////////////////////////////////////////////

    VALIDATE_PE_RAW(short_reads_raw.map { m, r1, r2 -> tuple(r1, r2, "sr-raw") })
    MERGE_VALI_RES_RAW(VALIDATE_PE_RAW.out.validate.collect().map { f -> tuple(f, "sr-raw") })

    FASTQ_STATS_SR_RAW(short_reads_raw.flatMap { m, r1, r2 -> [r1, r2] }.collect().map { f -> tuple(f, "sr-raw") })

    ////////////////////////////////////////////////////////////////////////////////
    // Trimmed
    ////////////////////////////////////////////////////////////////////////////////

    VALIDATE_PE_TRIM(short_reads_trim.map { m, r1, r2 -> tuple(r1, r2, "sr-trim") })
    MERGE_VALI_RES_TRIM(VALIDATE_PE_TRIM.out.validate.collect().map { f -> tuple(f, "sr-trim") })

    FASTQ_STATS_SR_TRIM(short_reads_trim.flatMap { m, r1, r2 -> [r1, r2] }.collect().map { f -> tuple(f, "sr-trim") })

   
    emit:
        raw_validation      = MERGE_VALI_RES_RAW.out.validate_csv
        trim_validation     = MERGE_VALI_RES_TRIM.out.validate_csv

        raw_stats_sr        = FASTQ_STATS_SR_RAW.out.seq_stats_csv
        trim_stats          = FASTQ_STATS_SR_TRIM.out.seq_stats_csv
}