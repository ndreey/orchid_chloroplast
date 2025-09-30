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

    publishDir "${params.res.get_org}/${meta.sample}", mode: 'symlink'

    conda params.mamba.GetOrganelle

    input:
    tuple val(meta), path(read1), path(read2)
    path database_flag

    output:
    tuple val(meta), path("${meta.sample}_results/"), emit: results
    tuple val(meta), path("${meta.sample}_results/*.fasta"), emit: assemblies, optional: true

    script:
    """    
    echo "\$(date) [INFO]   GetOrganelle run for sample: ${meta.sample}"
    
    # Run GetOrganelle
    get_organelle_from_reads.py \\
        -1 ${read1} \\
        -2 ${read2} \\
        -o ${meta.sample}_results \\
        -t ${task.cpus} \\
        -k ${params.getorg.kmer_init} \\
        -F embplant_pt \\
        --prefix "${meta.sample}_" \\
        --overwrite
    
    echo "\$(date) [INFO]   GetOrganelle run complete"
    """
}