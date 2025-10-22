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

    publishDir "${params.res.get_org}",        mode: 'symlink', pattern: "${meta.sample}_results"
    publishDir "${params.res.getorg_polish}",  mode: 'symlink', pattern: "${meta.sample}_polish"


    conda params.mamba.GetOrganelle

    input:
    tuple val(meta), path(read1), path(read2)
    path database_flag

    output:
    path("${meta.sample}_results/"), emit: results
    path("${meta.sample}_polish/"), optional: true, emit: polish
    // Emit a single tuple that bundles meta, assembly fasta, status and type files
    // downstream consumers can read status/type from the files or map them into strings
    tuple val(meta), path("${meta.sample}*1.1.path_sequence.fasta"), path("status.txt"), path("type.txt"), emit: assembly

    script:
    """
    set -euo pipefail

    echo "\$(date) [INFO]   GetOrganelle run for sample: ${meta.sample}"

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

    # Find first-pass assembly 
    GENOME=\$(ls ${meta.sample}_results/*1.1.path_sequence.fasta | head -n1)
    RESULT_TYPE=\$(echo "\$GENOME" | grep -Eo 'complete|nearly-complete|scaffolds' | head -n1)

    # Initialize variables for output
    STATUS="FAIL"
    RESULT_TYPE_FINAL="\$RESULT_TYPE"
    BEST_ASSEMBLY="\$GENOME"

    if [ "\$RESULT_TYPE" = "complete" ]; then
        # Complete on first pass -> PASS, keep results as-is
        STATUS="PASS"
        RESULT_TYPE_FINAL="complete"
        echo -e "${meta.sample}\\t\$RESULT_TYPE\\tNA" >> "../../../${params.stats.get_org}"
        echo "\$(date) [INFO]   Classified COMPLETE (PASS) on first pass"
        
        # Copy best assembly to working directory for output
        cp "\$GENOME" ./
        
        # Write output files for Nextflow
        echo "\$STATUS" > status.txt
        echo "\$RESULT_TYPE_FINAL" > type.txt
        
        exit 0
    fi

    echo "\$(date) [INFO]   Starting polish as first pass resulted with: \$RESULT_TYPE"

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

    POLISH=\$(ls ${meta.sample}_polish/*1.1.path_sequence.fasta | head -n1)

    if [ -z "\$POLISH" ]; then
        # No polish output — keep first-pass result
        if [ "\$RESULT_TYPE" = "nearly-complete" ]; then
            STATUS="PASS"
        else
            # scaffolds
            STATUS="FAIL"
        fi
        RESULT_TYPE_FINAL="\$RESULT_TYPE"
        BEST_ASSEMBLY="\$GENOME"
        echo -e "${meta.sample}\\t\$RESULT_TYPE\\tFAIL" >> "../../../${params.stats.get_org}"
        echo "\$(date) [INFO]   No polish assembly; keeping first-pass (\$RESULT_TYPE -> \$STATUS)"
    else
        # Polish succeeded, compare results
        RESULT_TYPE2=\$(echo "\$POLISH" | grep -Eo 'complete|nearly-complete|scaffolds' | head -n1)
        
        # Determine which result to use based on your logic
        USE_POLISH=false
        
        # If first pass scaffolds -> polish anything better, use polish
        if [ "\$RESULT_TYPE" = "scaffolds" ] && [ "\$RESULT_TYPE2" != "scaffolds" ]; then
            USE_POLISH=true
        fi
        
        # If first pass nearly-complete -> polish complete, use polish
        if [ "\$RESULT_TYPE" = "nearly-complete" ] && [ "\$RESULT_TYPE2" = "complete" ]; then
            USE_POLISH=true
        fi
        
        # If first pass nearly-complete -> polish scaffolds, use first pass
        if [ "\$RESULT_TYPE" = "nearly-complete" ] && [ "\$RESULT_TYPE2" = "scaffolds" ]; then
            USE_POLISH=false
        fi
        
        if [ "\$USE_POLISH" = "true" ]; then
            # Use polish results
            RESULT_TYPE_FINAL="\$RESULT_TYPE2"
            BEST_ASSEMBLY="\$POLISH"
            if [ "\$RESULT_TYPE2" = "complete" ]; then
                STATUS="PASS"
            elif [ "\$RESULT_TYPE2" = "nearly-complete" ]; then
                STATUS="PASS"
            else
                STATUS="FAIL"
            fi
        else
            # Use first pass results
            RESULT_TYPE_FINAL="\$RESULT_TYPE"
            BEST_ASSEMBLY="\$GENOME"
            if [ "\$RESULT_TYPE" = "nearly-complete" ]; then
                STATUS="PASS"
            else
                STATUS="FAIL"
            fi
        fi
        
        echo -e "${meta.sample}\\t\$RESULT_TYPE\\t\$RESULT_TYPE2" >> "../../../${params.stats.get_org}"
    fi

    # Copy the best assembly to working directory for output
    cp "\$BEST_ASSEMBLY" ./
    
    # Write final output files for Nextflow
    echo "\$STATUS" > status.txt
    echo "\$RESULT_TYPE_FINAL" > type.txt
    
    echo "\$(date) [INFO]   Final: type=\$RESULT_TYPE_FINAL, status=\$STATUS"
    """

    stub:
    """
    mkdir -p ${meta.sample}_results
    mkdir -p ${meta.sample}_polish
    touch ${meta.sample}_results/dummy.txt
    touch ${meta.sample}_polish/dummy.txt
    touch ${meta.sample}_complete.graph1.1.path_sequence.fasta
    echo "PASS" > status.txt
    echo "complete" > type.txt
    """
}