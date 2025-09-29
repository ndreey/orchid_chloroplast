#!/usr/bin/env nextflow

/*
-------------------------------------------------------
 Subworkflow: INIT
 Purpose: Parse metadata
-------------------------------------------------------
*/

workflow INIT {

    main:

    short_reads_ch = Channel
        .fromPath(params.metadata, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                sample      : row.sample,
                genus       : row.genus,
                taxon       : row.taxon,
                group       : row.group,
                country     : row.country,
            ]
            tuple(meta, file(row.r1), file(row.r2))
        }
        .ifEmpty { error "❌ No short-read metadata entries found in: ${params.metadata}" }

    emit:
        short_reads     = short_reads_ch
}