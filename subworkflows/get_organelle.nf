#!/usr/bin/env nextflow

include { GETORGANELLE_SETUP } from '../modules/getorganelle.nf'
include { GETORGANELLE_RUN }   from '../modules/getorganelle.nf'


workflow GET_ORGANELLE {
    take:
        reads_ch

    main:
        GETORGANELLE_SETUP()

        GETORGANELLE_RUN(
            reads_ch,
            GETORGANELLE_SETUP.out.getorg_flag
        )

        // Get the emitted tuple channel (meta, fasta_file, status.txt, type.txt)
        assembly_ch = GETORGANELLE_RUN.out.assembly

        // Map to convert the status/type files into trimmed strings and emit one plastome tuple
        plastome = assembly_ch.map { meta, fasta_path, status_file, type_file ->
            tuple(meta, fasta_path, status_file.text.trim(), type_file.text.trim())
        }

    emit:
        plastome = plastome
}