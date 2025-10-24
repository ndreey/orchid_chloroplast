#!/usr/bin/env nextflow

/*
 * Subworkflow for annotating and processing the plastid genomes
 * Author: André Bourbonnais (ndreey)
 */

include { RENAME_PLASTOME }             from '../modules/rename_plastome.nf'
include { PLASTOME_STRUCTURE }          from '../modules/plastome_structure.nf'
include { PGA_V2 }                      from '../modules/PGA_v2.nf'
include { PLASTOME_ASSESSMENT }         from '../modules/plastome_assessment.nf'
include { PLASTOME_EXTRACTION }         from '../modules/plastome_extraction.nf'
include { SORT_GENOMES }                from '../modules/sort_genomes.nf'
include { GET_AMPLICONS }               from '../modules/plastome_markers.nf'


workflow PLASTOME_ANNOTATION {
    take:
        plastome_ch   // channel: tuple val(meta), path(fasta), status, type

    main:
        // Run renaming on every incoming plastome tuple
        RENAME_PLASTOME(plastome_ch)

        // Grab the emitted renamed tuples
        renamed_plastomes = RENAME_PLASTOME.out.renamed_plastomes

        // Publish renamed plastomes into sorted directories based on their type
        SORT_GENOMES(renamed_plastomes)

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

        // Assessment of the plastome annotations
        PLASTOME_ASSESSMENT(ref_plastomes, PGA_V2.out.annotations)

        // Extract cds and intergenetic regions
        //PLASTOME_EXTRACTION(PGA_V2.out.annotations)

        // Make value channel for the marker pairs tsv file
        marker_pairs_ch = Channel.fromPath(params.marker_pairs, checkIfExists: true)

        // Run the marker extraction on the passes plastome assemblies
        GET_AMPLICONS(pass_fastas, marker_pairs_ch)


    emit:
        plastome_structure_results = PLASTOME_STRUCTURE.out.structured_fastas
        plastome_structure_summary = PLASTOME_STRUCTURE.out.structure_summary
        plastome_structure_coords = PLASTOME_STRUCTURE.out.structure_coord
        plastome_annotations = PGA_V2.out.annotations
        plastome_annotation_log = PGA_V2.out.annotation_log
        plastome_assessments = PLASTOME_ASSESSMENT.out.assessments
        plastome_assessment_summary = PLASTOME_ASSESSMENT.out.assessment_summary
        amplicon_fastas = GET_AMPLICONS.out.amplicon_fastas
        amplicon_results = GET_AMPLICONS.out.amplicon_results
        amplicon_beds = GET_AMPLICONS.out.amplicon_beds
}