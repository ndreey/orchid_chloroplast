#!/usr/bin/env nextflow

/*
 * Subworkflow for annotating and processing the plastid genomes
 * Author: André Bourbonnais (ndreey)
 *
 * Behaviour:
 *  - Run RENAME_PLASTOME on every incoming plastome tuple
 *  - Collect renamed plastomes, keep only those with status == 'PASS'
 *  - Collect all passed FASTAs into a single list and pass that to PLASTOME_STRUCTURE
 */

include { RENAME_PLASTOME }             from '../modules/rename_plastome.nf'
include { PLASTOME_STRUCTURE }          from '../modules/plastome_structure.nf'
include { PGA_V2 }                      from '../modules/PGA_v2.nf'

workflow PLASTOME_ANNOTATION {
    take:
        plastome_ch   // channel: tuple val(meta), path(fasta), status, type

    main:
        // Run renaming on every incoming plastome tuple
        RENAME_PLASTOME(plastome_ch)

        // Grab the emitted renamed tuples
        renamed_plastomes = RENAME_PLASTOME.out.renamed_plastomes

        // Keep only PASS entries (destructure matches RENAME_PLASTOME output: meta, fasta, type, status)
        pass_renamed = renamed_plastomes
            .filter { meta, fasta, type, status -> status.equalsIgnoreCase('PASS') }

        // Extract fasta paths and collect them into a single list for the aggregator process
        pass_fastas = pass_renamed
            .map { meta, fasta, type, status -> fasta }
            .collect()

        // Run the structure module once on the collected PASS FASTAs
        PLASTOME_STRUCTURE(pass_fastas)

        // Collect all .gb files under the configured directory into a single emission.
        ref_plastomes = Channel
            .fromPath("${params.references.plastome_genbank}/*.gb", checkIfExists: true)
            .collect()

        // Annotate the plastomes on the collected PASS FASTAs using reference plastomes
        PGA_V2(pass_fastas, ref_plastomes)

    
    emit:
        plastome_structure_results = PLASTOME_STRUCTURE.out.structured_fastas
        plastome_structure_summary = PLASTOME_STRUCTURE.out.structure_summary
        plastome_structure_coords = PLASTOME_STRUCTURE.out.structure_coord
        plastome_annotations = PGA_V2.out.annotations
        plastome_annotation_log = PGA_V2.out.annotation_log

}