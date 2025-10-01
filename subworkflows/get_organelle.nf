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
    
    // Convert status and type files to string values
    status_ch = GETORGANELLE_RUN.out.status_file
        .map { file -> file.text.trim() }
    
    type_ch = GETORGANELLE_RUN.out.type_file
        .map { file -> file.text.trim() }
    
    emit:
    results    = GETORGANELLE_RUN.out.results      // path(sample_results/)
    polish     = GETORGANELLE_RUN.out.polish       // path(sample_polish/) - optional
    assemblies = GETORGANELLE_RUN.out.assembly     // tuple val(meta), path(*.best.fasta)
    status     = status_ch                         // string values: PASS/FAIL
    type       = type_ch                           // string values: complete/nearly-complete/scaffolds
}