#!/usr/bin/env nextflow

process PLASTOME_ASSESSMENT {
    label 'plastome_assessment'
    tag 'plastome_assessment'

    // Publish final results to the requested location
    publishDir params.res.plastome_assessment, mode: 'copy', pattern: '*.txt'
    publishDir 'results/stats', mode: 'copy', pattern: 'plastome-assessment-summary.tsv'
    conda params.mamba.PlastidHub

    input:
        file references
        file annotations

    output:
        // Expect the Perl script to write out a folder named "plastome_structure"
        path '*.txt', emit: assessments
        path 'plastome-assessment-summary.tsv', emit: assessment_summary

    script:
    """
    set -euo pipefail

    # workspace subfolders
    mkdir -p annotated_plastomes ref_plastomes

    # stage input FASTAs
    for f in ${annotations}
    do
        mv "\$f" annotated_plastomes/
    done

    # stage input Genbanks
    for f in ${references}
    do
        mv "\$f" ref_plastomes/
    done

    # Absolute path to the PlastidHub script
    PLASTIDHUB_PATH="../../../scripts/PlastidHub"

    # Run the PlastidHub script on staged FASTAs
    perl \${PLASTIDHUB_PATH}/2.1.assess_gene_number_v1.pl \\
        -target annotated_plastomes \\
        -reference ref_plastomes \\
        -o plastome_assessment
    
    # Write header
    echo -e "sample\ttotal\tn.hit\tperc.hit\tn.miss\tperc.miss\tn.redundant\tperc.redundant\tn.PCGs\tn.miss.PCGs\tn.red.PCGs\tn.hit.tRNA\tn.miss.tRNA\tn.red.tRNA\tn.hit.rRNA\tn.miss.rRNA\tn.red.rRNA" > plastome-assessment-summary.tsv

    for f in plastome_assessment/*.txt; do
      
        sampleID=\$(basename "\$f" -plastome.txt | cut -f 4- -d "_")
        # Number of genes in target
        nHit=\$(grep '(nH)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        pHit=\$(grep '(pH)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)

        # Number of genes missing in target
        nMiss=\$(grep '(nM)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        pMiss=\$(grep '(pM)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)

        # Number of redundant genes in target
        nRed=\$(grep '(nR)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        pRed=\$(grep '(pR)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)

        # Number of protein coding genes in target.
        nHP=\$(grep '(nHP)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        # Number of missing protein coding genes in target
        nMP=\$(grep '(nMP)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        # Number of redundant protein coding genes in target
        nRP=\$(grep '(nRP)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)

        # Number of tRNA genes in target.
        nHT=\$(grep '(nHT)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        # Number of missing tRNA genes in target
        nMT=\$(grep '(nMT)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        # Number of redundant tRNA genes in target
        nRT=\$(grep '(nRT)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)

        # Number of rRNA genes in target.
        nHR=\$(grep '(nHR)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        # Number of missing rRNA genes in target
        nMR=\$(grep '(nMR)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)
        # Number of redundant rRNA genes in target
        nRR=\$(grep '(nRR)' "\$f" | tr -d "|" | cut -f 1 -d " " || true)

        # Total numbers of genes in reference.
        total=\$(( nHit + nMiss + nRed ))

        printf "%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "\$sampleID" "\$total" \
        "\$nHit" "\$pHit" \
        "\$nMiss" "\$pMiss" \
        "\$nRed" "\$pRed" \
        "\$nHP" "\$nMP" "\$nRP" \
        "\$nHT" "\$nMT" "\$nRT" \
        "\$nHR" "\$nMR" "\$nRR" \
        >> plastome-assessment-summary.tsv

        mv "\$f" \$sampleID.txt
    done
    
    # Clear workspace
    rm -r annotated_plastomes plastome_assessment ref_plastomes

    echo "Plastome annotation assessment completed."
    """
}