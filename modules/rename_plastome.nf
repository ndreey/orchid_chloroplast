#!/usr/bin/env nextflow

process RENAME_PLASTOME {
    
    tag "${meta.sample}-rename"

    input:
        tuple val(meta), file(fasta), val(status), val(type)

    output:
        tuple val(meta), file('*.fasta'), val(type), val(status), emit: renamed_plastomes

    script:
    """
    sample='${meta.sample ?: 'unknown'}'
    genus='${meta.genus ?: 'unknown'}'
    taxon='${meta.taxon ?: 'unknown'}'
    type_tag='${type ?: 'unknown'}'

    # Construct base name
    base="\${sample}-\${genus}_\${taxon}"
    new_name="\${base}.\${type_tag}.fasta"

    # Replace headers in the FASTA file
    awk -v name="\${base}" 'BEGIN{n=0} /^>/ { if(n==0) {print ">"name} else {print ">"name"_"n} n++; next } {print}' "${fasta}" > "\${new_name}"

    # remove the original file so only the renamed FASTA remains
    rm -f "${fasta}"

    """
}