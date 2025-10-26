#!/usr/bin/env nextflow

/*
 * Publishers: small helper processes that take a renamed FASTA and publish it
 * to the configured results paths.
 */


process SORT_GENOMES {
    publishDir params.res.genomes.complete, mode: 'copy', pattern: '*.complete.fasta'
    publishDir params.res.genomes.nearly_complete, mode: 'copy', pattern: '*.nearly-complete.fasta'
    publishDir params.res.genomes.scaffolds, mode: 'copy', pattern: '*.scaffolds.fasta'

    input:
        tuple val(meta), file(fasta), val(type), val(status)
    output:
        path "${fasta}", emit: sorted_fasta
        
    script:
    """
    # no-op; file is staged by Nextflow and publishDir will copy it
    ls -l ${fasta} || true
    """
}

