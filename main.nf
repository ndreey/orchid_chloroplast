#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Orchid Chloroplast Project
    Author: André Bourbonnais (ndreey)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INIT }          from './subworkflows/init.nf'
include { ORCL_PIPELINE } from './workflow/orchid_chloro.nf'

// Generate timestamp to label results/output folders
params.timestamp = new Date().format('yyyyMMdd-HH-mm-ss')

workflow {

    log.info "STARTING: Orchid Chloroplast Project"
    log.info "Timestamp: ${params.timestamp}"

    // Run init subworkflow to prepare input data
    def init_outputs = INIT()

    // Read in short reads
    def short_reads_ch      = init_outputs.short_reads

    // Launch main analysis pipeline
    ORCL_PIPELINE(
        short_reads_ch,
    )
}
