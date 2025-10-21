#!/usr/bin/env nextflow

process PGA_V2 {
    label 'plastome_annotation'
    tag 'plastome_annotation'

    // Publish final results to the requested location
    publishDir params.res.plastome_annotation, mode: 'copy', pattern: '*.gb'
    publishDir 'results/stats', mode: 'copy', pattern: 'plastome_annotation_warnings.log'

    conda params.mamba.PlastidHub

    input:
        file fastas
        file references

    output:
        // Expect the Perl script to write out a folder named "plastome_structure"
        path '*.gb', emit: annotations
        path 'plastome_annotation_warnings.log', emit: annotation_log

    script:
    """
    set -euo pipefail

    # workspace subfolders
    mkdir -p passed_plastomes ref_plastomes

    # stage input FASTAs
    for f in ${fastas}
    do
        mv "\$f" passed_plastomes/
    done

    # stage input Genbank References
    for f in ${references}
    do
        mv "\$f" ref_plastomes/
    done

    # Absolute path to the PlastidHub script
    PLASTIDHUB_PATH="/home/andbou/orchid_chloroplast/scripts/PlastidHub"

    # Run the PlastidHub script on staged FASTAs
    perl \${PLASTIDHUB_PATH}/1.2.PGA_v2.pl \\
        -target passed_plastomes \\
        -reference ref_plastomes \\
        -o plastome_annotation

    # Move contents into working directory.
    cp plastome_annotation/* . || true

    rm -r passed_plastomes plastome_annotation ref_plastomes

    mv warning.log plastome_annotation_warnings.log || true

    echo "Plastome annotation completed."
    """
}