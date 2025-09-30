#!/usr/bin/env nextflow

process GETORGANELLE_SETUP {

    label "setup"
    
    tag "getorganelle-setup"

    conda params.mamba.GetOrganelle

    output:
    path "getOrganelle_status.txt", emit: getorg_flag

    script:
    """
    # Setup GetOrganelle databases
    echo "Setting up GetOrganelle databases..."
    
    # Download the databases (embryophyte plastid, Embryophyte mitcochondrion)
    get_organelle_config.py --add embplant_pt
    
    # Verify setup completed successfully
    if get_organelle_config.py --list | grep -q "embplant"; then
        echo "GetOrganelle databases successfully configured on \$(date)"
        get_organelle_from_reads.py --version > getOrganelle_status.txt
        get_organelle_config.py --list >> getOrganelle_status.txt
    else
        echo "ERROR: Database setup failed" > getOrganelle_status.txt
        exit 1
    fi
        
    echo "GetOrganelle setup completed successfully"
    """
}

process GETORGANELLE_RUN {

    label "get_org"
    tag "${meta.sample}"

    publishDir "${params.res.get_org}", mode: 'symlink'

    conda params.mamba.GetOrganelle

    input:
    tuple val(meta), path(read1), path(read2)
    path database_flag

    output:
    tuple val(meta), path("${meta.sample}_results/"), emit: results
    tuple val(meta), path("${meta.sample}_results/*graph1.1.path_sequence.fasta"), emit: assembly
    tuple val(meta), path("${meta.sample}_results/.status.txt"), emit: status     // PASS or FAIL
    tuple val(meta), path("${meta.sample}_results/.class.txt"),  emit: class      // complete / nearly-complete / scaffolds

    script:
    """
    set -euo pipefail

    echo "\$(date) [INFO]   GetOrganelle run for sample: ${meta.sample}"

    COMP="${params.res.chloroplasts}/complete"
    NC="${params.res.chloroplasts}/nearly-complete"
    SCAFF="${params.res.chloroplasts}/scaffolds"
    mkdir -p "\$COMP" "\$NC" "\$SCAFF"
    mkdir -p "${meta.sample}_results"

    # ---------- First pass ----------
    get_organelle_from_reads.py \\
        -1 "${read1}" \\
        -2 "${read2}" \\
        -o "${meta.sample}_results" \\
        -t ${task.cpus} \\
        -k "${params.getorg.kmer_init}" \\
        -F embplant_pt \\
        --prefix "${meta.sample}_" \\
        --overwrite

    echo "\$(date) [INFO]   First pass complete"

    # Find first-pass assembly (take the first match if multiple)
    GENOME=\$(ls -1 ${meta.sample}_results/*graph1.1.path_sequence.fasta 2>/dev/null | head -n1 || true)

    # Parse type from filename.
    RESULT_TYPE=\$(echo "\$GENOME" | grep -Eo 'complete|nearly-complete|scaffolds' | head -n1)

    if [ "\$RESULT_TYPE" = "complete" ]; then
        # Complete on first pass -> PASS, keep results as-is
        STATUS="PASS"
        cp "\$GENOME" "\$COMP/"

        echo "\$STATUS" > "${meta.sample}_results/.status.txt"
        echo "\$RESULT_TYPE" > "${meta.sample}_results/.class.txt"
        echo -e "${meta.sample}\\t\$RESULT_TYPE\\tNA" >> "${params.stats.get_org}"

        echo "\$(date) [INFO]   Classified COMPLETE (PASS) on first pass"
        exit 0
    fi

    echo "\$(date) [INFO]   Starting polish pass"

    # ---------- Polish pass ----------
    get_organelle_from_reads.py \\
        -1 "${read1}" \\
        -2 "${read2}" \\
        -o "${meta.sample}_polish" \\
        -t ${task.cpus} \\
        -w "${params.getorg.wordsize}" \\
        -k "${params.getorg.kmer_polish}" \\
        -F embplant_pt \\
        --prefix "${meta.sample}_" \\
        --overwrite

    POLISH=\$(ls -1 ${meta.sample}_polish/*graph1.1.path_sequence.fasta 2>/dev/null | head -n1 || true)

    if [ -z "\$POLISH" ]; then
        # No polish output — keep first-pass result
        if [ "\$RESULT_TYPE" = "nearly-complete" ]; then
            STATUS="PASS"
            cp "\$GENOME" "\$NC/"
        else
            # scaffolds
            STATUS="FAIL"
            cp "\$GENOME" "\$SCAFF/"
        fi

        echo "\$STATUS" > "${meta.sample}_results/.status.txt"
        echo "\$RESULT_TYPE" > "${meta.sample}_results/.class.txt"
        echo -e "${meta.sample}\\t\$RESULT_TYPE\\tNA" >> "${params.stats.get_org}"

        echo "\$(date) [INFO]   No polish assembly; keeping first-pass (\$RESULT_TYPE -> \$STATUS)"
        exit 0
    fi

    POLISH_BASENAME=\$(basename "\$POLISH")
    RESULT_TYPE2=\$(echo "\$POLISH" | grep -Eo 'complete|nearly-complete|scaffolds' | head -n1)

    # ---------- Promotion / cleanup logic (your original intent) ----------
    # If nearly-complete -> scaffolds, discard polish
    if [ "\$RESULT_TYPE" = "nearly-complete" ] && [ "\$RESULT_TYPE2" = "scaffolds" ]; then
        rm -rf "${meta.sample}_polish"
        cp \$GENOME \$NC
    fi

    # If nearly-complete -> complete, promote polish to results
    if [ "\$RESULT_TYPE" = "nearly-complete" ] && [ "\$RESULT_TYPE2" = "complete" ]; then
        cp \$POLISH \$COMP
        rm -rf "${meta.sample}_results"
        mv "${meta.sample}_polish" "${meta.sample}_results"
    fi

    # If scaffolds -> not scaffolds, promote polish to results
    if [ "\$RESULT_TYPE" = "scaffolds" ] && [ "\$RESULT_TYPE2" != "scaffolds" ]; then
        cp \$POLISH ${params.res.chloroplasts}/\$RESULT_TYPE2
        rm -rf "${meta.sample}_results"
        mv "${meta.sample}_polish" "${meta.sample}_results"
    fi

    # Write small status/class files for the outputs you want to emit
    echo "\$STATUS" > "${meta.sample}_results/.status.txt"
    echo "\$RESULT_TYPE_FINAL" > "${meta.sample}_results/.class.txt"

    # Append run summary to your stats tsv
    echo -e "${meta.sample}\\t\$RESULT_TYPE\\t\$RESULT_TYPE2" >> "${params.stats.get_org}" 2>/dev/null || \\
    echo -e "${meta.sample}\\t\$RESULT_TYPE\\tNA" >> "${params.stats.get_org}"

    echo "\$(date) [INFO]   Final: type=\$RESULT_TYPE_FINAL, status=\$STATUS"
    """
}


########## TO DO ##########
1. Check the logic in the end. Maybe we do not have to remove the _polish and it can be submitted to its own publishDir.
2. Check the PASS/FAIL logic and how its emitted.
3. Check the type logic and how its emitted.
4. Update the workflow and subworkflow.
5.