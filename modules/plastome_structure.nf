#!/usr/bin/env nextflow

process PLASTOME_STRUCTURE {
    label 'plastome_structure'
    tag 'plastome_structure'

    // publish only FASTA files from the plastome_structure/ folder
    publishDir params.res.plastome_structure, mode: 'symlink', pattern: '*_LSC_IRb_SSC_IRa.fasta'
    // publish the summary TSV to the stats folder
    publishDir 'results/stats', mode: 'copy', pattern: 'plastome-structure_summary.tsv'
    publishDir 'results/stats', mode: 'copy', pattern: 'quadripartite_structure_coordinate.txt'

    conda params.mamba.PlastidHub

    input:
        file fastas

    output:
        // publish individual FASTA files (NOT the whole folder)
        path '*_LSC_IRb_SSC_IRa.fasta', emit: structured_fastas
        // publish the TSV summary to stats
        path 'plastome-structure_summary.tsv', emit: structure_summary
        path 'quadripartite_structure_coordinate.txt', emit: structure_coord


    script:
    """
    set -euo pipefail

    # workspace subfolders
    mkdir -p passed_plastomes

    # stage input FASTAs
    for f in ${fastas}
    do
        mv "\$f" passed_plastomes/
    done

    # Absolute path to the PlastidHub script
    PLASTIDHUB_PATH="../../../scripts/PlastidHub"

    # Run the PlastidHub script on staged FASTAs
    perl \${PLASTIDHUB_PATH}/1.1.quadripartite_standardization_v1.pl \\
        -i passed_plastomes \\
        -r N \\
        -s N \\
        -l 500 \\
        -o plastome_structure

    # Build a TSV summary of region lengths per fasta using the coordinate file
    # Keep only the Post-adjustment lines and compute lengths from ranges like 1-83153
    if [ -s plastome_structure/quadripartite_structure_coordinate.txt ]; then
        grep -v 'Pre-adjustment' plastome_structure/quadripartite_structure_coordinate.txt | tail -n +2 | \\
        awk -F'\\t' 'BEGIN { OFS = "\\t"; print "FastaFileNames", "total", "LSC", "IRb", "SSC", "IRa" }
        {
            name = \$1
            lsc  = \$3
            irb  = \$4
            ssc  = \$5
            ira  = \$6

            # helper to compute length from "start-end"
            split(lsc, a, "-"); L = (a[2] != "" ? a[2] - a[1] + 1 : 0)
            split(irb, b, "-"); Rb = (b[2] != "" ? b[2] - b[1] + 1 : 0)
            split(ssc, c, "-"); S = (c[2] != "" ? c[2] - c[1] + 1 : 0)
            split(ira, d, "-"); Ra = (d[2] != "" ? d[2] - d[1] + 1 : 0)

            total = L + Rb + S + Ra
            print name, total, L, Rb, S, Ra
        }' > plastome-structure_summary.tsv
    else
        echo -e "FastaFileNames\\ttotal\\tLSC\\tIRb\\tSSC\\tIRa" > plastome-structure_summary.tsv
    fi

    # Move contents into working directory.
    cp plastome_structure/*LSC_IRb_SSC_IRa.fasta . || true
    cp plastome_structure/*.txt . || true

    rm -r passed_plastomes plastome_structure
    
    echo "Plastome structure analysis and summary completed."
    """
}