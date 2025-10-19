#!/usr/bin/env nextflow

process RENAME_PLASTOME {
    tag { meta.sample ?: 'unknown' }

    input:
        tuple val(meta), file(fasta), val(status), val(type)

    output:
        tuple val(meta), file('*plastome.fasta'), val(type), val(status), emit: renamed_plastomes

    script:
    """
    sample='${meta.sample ?: 'unknown'}'
    genus='${meta.genus ?: 'unknown'}'
    taxon='${meta.taxon ?: 'unknown'}'
    type_tag='${type ?: 'unknown'}'

    # Build filename as: sample-genus.taxon-<type>.plastome.fasta
    new_name="\${sample}-\${genus}_\${taxon}-\${type_tag}.plastome.fasta"

    mv "${fasta}" "\$new_name"
    """
}