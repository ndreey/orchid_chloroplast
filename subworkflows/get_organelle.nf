#!/usr/bin/env nextflow

/*
 * GetOrganelle subworkflow for organelle genome assembly
 * Author: André Bourbonnais (ndreey)
 */

include { GETORGANELLE_SETUP } from '../modules/getorganelle.nf'
include { GETORGANELLE_RUN }   from '../modules/getorganelle.nf'

workflow GET_ORGANELLE {
    
    take:
    reads_ch    // channel: tuple val(meta), path(read1), path(read2)
    
    main:
    
    // Setup GetOrganelle databases (runs once)
    GETORGANELLE_SETUP()
    
    // Run GetOrganelle on each sample (waits for setup to complete)
    GETORGANELLE_RUN(
        reads_ch,
        GETORGANELLE_SETUP.out.getorg_flag
    )
    
    emit:
    results    = GETORGANELLE_RUN.out.results     // tuple val(meta), path(results_dir)
    assemblies = GETORGANELLE_RUN.out.assemblies  // tuple val(meta), path(*.fasta)
}