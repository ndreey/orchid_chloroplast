#!/usr/bin/env nextflow

process GET_AMPLICONS {
    label 'extract_amplicons'
    tag 'extract_amplicons'

    // publish only FASTA files from the plastome_structure/ folder
    publishDir params.res.amplicons.fasta, mode: 'symlink', pattern: '*amplicon.fasta'
    publishDir params.res.amplicons.bed, mode: 'symlink', pattern: '*amplicon.bed'
    // publish the summary TSV to the stats folder
    publishDir 'results/stats', mode: 'copy', pattern: 'amplicon_results.tsv'

    conda params.mamba.STATS

    input:
        file fastas
        path marker_pairs // tsv with name, fwd_primer, rev_primer columns

    output:
        // publish individual FASTA files (NOT the whole folder)
        path '*.amplicon.fasta', emit: amplicon_fastas
        // publish individual BED files (NOT the whole folder)
        path '*.amplicon.bed', emit: amplicon_beds
        // publish the TSV summary to stats
        path 'amplicon_results.tsv', emit: amplicon_results
        // publish the FASTA stats summary to stats

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

    # Concatenate all passed plastome FASTAs into a single file
    cat passed_plastomes/*.fasta > all_passed_plastomes.fasta

    # Create headers for amplicon results
    echo -e "marker\\tsample\\tstart\\tend\\tstrand\\length\\tsequence" > amplicon_results.tsv

    # Get fasta for each marker pairs across all given plastomes.
    while IFS='\t' read -r ID FW RV; do
        echo "Extracting marker: \$ID with primers FW: \$FW and RV: \$RV"
    
        # Extract fasta
        seqkit amplicon -F "\$FW" -R "\$RV" -m 2 -o amplicons/"\${ID}.amplicon.fasta" all_passed_plastomes.fasta
    
        # Extract as BED to get coordinates
        seqkit amplicon -F "\$FW" -R "\$RV" -m 2 --bed -o amplicons/"\${ID}.amplicon.bed" all_passed_plastomes.fasta

        # Create summary of all hits
        cat amplicons/"\${ID}.amplicon.bed" | awk -v id="\$ID" 'BEGIN {OFS="\\t"} {print id, \$1, \$2, \$3, \$6, length(\$7), \$7}' >> amplicon_results.tsv

    done < "${marker_pairs}"

    # Copy amplicon FASTAs to the output folder
    mv amplicons/*.amplicon.fasta .
    mv amplicons/*.amplicon.bed .

    # Clear redundant files
    rm -r passed_plastomes all_passed_plastomes.fasta amplicons
    """

}