#!/usr/bin/env nextflow

process VALIDATE_PE {

    label 'validate'
    tag "validate-${read1}-${type}"

    conda params.mamba.STATS

    input:
    tuple path(read1), path(read2), val(type)

    output:
    path("*.validate"), emit: validate

    script:
    """
    SAMPLE_NAME=${read1.getSimpleName()}
    
    biopet-validatefastq -i ${read1} -j ${read2} &> \${SAMPLE_NAME}-${type}-validate.txt

    if grep -q "no errors found" \${SAMPLE_NAME}-${type}-validate.txt; then
        echo "\${SAMPLE_NAME}-${type},PASSED" > \${SAMPLE_NAME}-passed.validate
    else
        echo "\${SAMPLE_NAME}-${type},FAILED" > \${SAMPLE_NAME}-failed.validate
    fi
    """
}



process MERGE_VALI_RES {

    label "stats"
    tag "merge-${id}-validate-csv"

    publishDir "./results/stats", mode: "copy"

    input:
    tuple path(validate_files), val(id)

    output:
    path("${id}-validate.csv"), emit: validate_csv

    script:
    """
    # Write header
    echo "sample,status" > ${id}-validate.csv

    # Append all validate lines
    cat ${validate_files} >> ${id}-validate.csv
    """
}