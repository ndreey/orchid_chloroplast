#!/usr/bin/env nextflow

process GET_AMPLICONS {
    label 'extract_amplicons'
    tag 'extract_amplicons'

    // publish only FASTA files from the plastome_structure/ folder
    publishDir params.res.amplicons, mode: 'symlink', pattern: '*amplicon.fasta'
    // publish the summary TSV to the stats folder
    publishDir 'results/stats', mode: 'copy', pattern: 'amplicons_summary.tsv'

    conda params.mamba.STATS

    input:
        file fastas
        path marker_pairs // tsv with name, fwd_primer, rev_primer columns

    output:
        // publish individual FASTA files (NOT the whole folder)
        path '*amplicon.fasta', emit: amplicon_fastas
        // publish the TSV summary to stats
        path 'amplicons_summary.tsv', emit: amplicon_summary


    script:
    """
    set -euo pipefail

    # workspace subfolders
    mkdir -p passed_plastomes amplicons

    # stage input FASTAs
    for f in ${fastas}
    do
        mv "\$f" passed_plastomes/
    done

    cat passed_plastomes/*.fasta > all_passed_plastomes.fasta

    # Get fasta for each marker pairs across all given plastomes.
    while IFS='\t' read -r ID FW RV; do
        echo "Extracting marker: \$ID with primers FW: \$FW and RV: \$RV"
        seqkit amplicon -F "\$FW" -R "\$RV" -m 2 -o amplicons/"\${ID}.amplicon.fasta" all_passed_plastomes.fasta
    done < "${marker_pairs}"

    # Get stats for each file
    seqkit stats -T -b -o amplicons_summary.tsv amplicons/*.amplicon.fasta

    # Copy amplicon FASTAs to the output folder
    cp amplicons/*.amplicon.fasta .

    # Clear redundant files
    rm -r passed_plastomes all_passed_plastomes.fasta amplicons
    """

}