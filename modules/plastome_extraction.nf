#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process PLASTOME_EXTRACTION {
    label 'plastome_extraction'
    tag 'plastome_extraction'

    // Publish final results to the requested location
    publishDir params.res.plastome_extraction, mode: 'copy'

    conda params.mamba.PlastidHub

    input:
        file annotations

    output:
        path 'pattern*_fastas', emit: extractions
        path 'pattern*_beds', emit: bed_files

    script:
    """
    set -euo pipefail

    mkdir -p annotated_plastomes

    # Stage input annotation files
    for f in ${annotations}; do
        mv "\$f" annotated_plastomes/
    done

    PLASTIDHUB_PATH="../../../scripts/PlastidHub"

    for i in {1..3}; do
        perl "\${PLASTIDHUB_PATH}/5.extraction_v1.pl" \\
            -input annotated_plastomes \\
            -pattern \$i \\
            -output plastome_extraction_p\$i

        mkdir -p pattern\${i}_beds pattern\${i}_fastas
        mv plastome_extraction_p\$i/*.bed pattern\${i}_beds/ || true
        mv plastome_extraction_p\$i/*.fasta pattern\${i}_fastas/ || true
    done

    # Cleanup
    rm -rf annotated_plastomes plastome_extraction_p*
    """
    
    stub:
    """
    mkdir -p pattern1_beds pattern1_fastas
    touch pattern1_beds/dummy.bed pattern1_fastas/dummy.fasta
    mkdir -p pattern2_beds pattern2_fastas
    touch pattern2_beds/dummy.bed pattern2_fastas/dummy.fasta
    mkdir -p pattern3_beds pattern3_fastas
    touch pattern3_beds/dummy.bed pattern3_fastas/dummy.fasta
    echo "PlastidHub: 1.0.0" > versions.yml
    """
}