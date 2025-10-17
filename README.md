# Orchid Chloroplast Assembly Pipeline

A Nextflow pipeline for assembling chloroplast genomes from Illumina paired-end sequencing data, specifically designed for orchid species.

## Overview

This pipeline processes raw Illumina sequencing data to assemble complete chloroplast genomes using GetOrganelle. The workflow includes quality control, read trimming, chloroplast genome assembly, and comprehensive reporting with detailed statistics generation.

## Workflow

The pipeline consists of the following main steps:

1. **Read Trimming** - Quality-based trimming and adapter removal using FASTP
2. **Quality Control** - Pre and post-trimming assessment using FastQC
3. **FASTQ Validation & Statistics** - Comprehensive sequence statistics generation
4. **Chloroplast Assembly** - Targeted assembly using GetOrganelle with database setup
5. **Report Generation** - MultiQC summary report compilation

## Tools and Dependencies

### Core Tools
- **[GetOrganelle](https://github.com/Kinggerm/GetOrganelle)** (v1.7.7.0) - Organellar genome assembly toolkit
- **[FASTP](https://github.com/OpenGene/fastp)** (v0.23.4) - Ultra-fast all-in-one FASTQ preprocessor
- **[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)** (v0.12.1) - Quality control tool for high throughput sequence data
- **[MultiQC](https://multiqc.info/)** (v1.19) - Aggregate results from bioinformatics analyses
- **[SeqKit](https://bioinf.shenwei.me/seqkit/)** (v2.6.1) - Cross-platform toolkit for FASTA/Q file manipulation

### Environment Management
- **Conda/Mamba** - Package and environment management
- **Wave containers** - Containerized execution support

## Quick Start

### Prerequisites
- Nextflow (≥ 21.04.0)
- Conda or Mamba
- Docker (optional)

### Installation
```bash
git clone https://github.com/ndreey/orchid_chloroplast.git
cd orchid_chloroplast
```

### Usage
```bash
# Basic usage
nextflow run main.nf -profile local -params-file parameters.yml

# With custom parameters
nextflow run main.nf -profile local -params-file parameters.yml --trim.cut_right_qual 25

```

## Input Requirements

### Sample Sheet Format
The pipeline requires a CSV file with the following columns:
- `sample`: Sample identifier
- `genus`: Genus
- `taxon`: Taxa
- `group`: Group identifier
- `country`: Sample country 
- `read1`: Path to R1 FASTQ file
- `read2`: Path to R2 FASTQ file

Example:
```csv
sample,genus,taxon,group,country,r1,r2
2769,Gymnadenia,frivaldii,frivaldii,GRE,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
2759,Pseudorchis,tricuspis,Pseudorchis,SUI,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
2774,Gymnadenia,frivaldii,frivaldii,GRE,/path/to/sample3_R1.fastq.gz,/path/to/sample3_R2.fastq.gz

```

## Parameters

### Main Parameters

### Trimming Parameters
- `--trim_quality`: Quality threshold for trimming (default: 20)
- `--min_length`: Minimum read length after trimming (default: 36)

### Assembly Parameters
- `--organelle_type`: Target organelle type for GetOrganelle (default: 'embplant_pt')
- `--getorg_config`: GetOrganelle configuration file path
- `--getorg_memory`: Memory allocation for GetOrganelle (default: '8.GB')

### Quality Control Parameters
- `--skip_fastqc`: Skip FastQC steps (default: false)
- `--skip_multiqc`: Skip MultiQC report generation (default: false)

## Output Structure

```
results/
├── 00-QC
│   ├── fastqc-raw
│   ├── fastqc-trim
│   ├── multiqc-fastp
│   │   └── multiqc_data -> /home/andbou/orchid_chloroplast/work/cd/a84e8cd4aadef22632d6fb5849b9fa/multiqc_data
│   ├── multiqc-raw
│   │   └── multiqc_data -> /home/andbou/orchid_chloroplast/work/bf/8468879f926252eebb81fc032fbf3d/multiqc_data
│   └── multiqc-trim
│       └── multiqc_data -> /home/andbou/orchid_chloroplast/work/fa/6db1c1d1295bebeec427aada054788/multiqc_data
├── 01-trimmed
├── 02-get_organelle
│   ├── 12240_results
│   ├── 1658_results 
│   ├── 2759_results
│   ├── 2769_results
│   ├── 2774_results 
│   ├── 3173_results
│   ├── 3174_results 
│   ├── 3312_results 
│   ├── 4204_results 
│   ├── 544_results 
│   ├── 561_results 
│   └── 671_results
├── 03-get_org_polish
│   ├── 3173_polish 
│   ├── 3174_polish 
│   └── 4204_polish 
├── chloroplast_genomes
│   ├── complete
│   ├── nearly-complete
│   └── scaffolds
└── stats
```

## Key Output Files

- **MultiQC Report**: `results/multiqc/multiqc_report.html` - Comprehensive quality control summary
- **Chloroplast Assemblies**: `results/chloroplast_genomes/[sample]/` - Complete chloroplast genome assemblies
- **Assembly Statistics**: `results/stats/` - Detailed sequence statistics for all processing steps
- **Trimmed Reads**: `results/01-trimmed/` - Quality-trimmed FASTQ files

## Pipeline Architecture

### Subworkflows
- **TRIM_READS**: Handles read trimming using FASTP
- **FASTQ_VALIDATION_STATS**: Generates comprehensive sequence statistics
- **QC_REPORTS**: Compiles quality control reports using FastQC and MultiQC
- **GET_ORGANELLE**: Manages GetOrganelle database setup and assembly execution

### Modules
- **fastp.nf**: Read trimming and quality filtering
- **fastqc.nf**: Quality control assessment
- **getorganelle.nf**: Chloroplast genome assembly
- **multiqc.nf**: Report aggregation
- **seq_stats.nf**: Sequence statistics generation
- **validate_fastq.nf**: FASTQ file validation

## Configuration

The pipeline uses several configuration files:
- `nextflow.config`: Main Nextflow configuration with profiles
- `parameters.yml`: Default parameter values and conda environments

### Resource Requirements
- **CPU**: 4-8 cores recommended per sample
- **Memory**: 8-16 GB RAM (configurable via `--getorg_memory`)
- **Storage**: ~5-10x input data size for intermediate files

## Assembly Quality Assessment

The pipeline provides multiple quality metrics:
- **Assembly completeness**: Complete vs. nearly-complete vs. scaffolds
- **Assembly status**: PASS/FAIL based on GetOrganelle criteria
- **Quality scores**: Pre and post-trimming quality metrics



## Citation
If you use this pipeline in your research, please cite:
- **GetOrganelle**: Jin, J.J., Yu, W.B., Yang, J.B., Song, Y., dePamphilis, C.W., Yi, T.S. and Li, D.Z., 2020. GetOrganelle: a fast and versatile toolkit for accurate de novo assembly of organellar genomes. *Genome biology*, 21(1), pp.1-31.
- **FASTP**: Chen, S., Zhou, Y., Chen, Y. and Gu, J., 2018. fastp: an ultra-fast all-in-one FASTQ preprocessor. *Bioinformatics*, 34(17), pp.i884-i890.
- **FastQC**: Andrews, S. (2010). FastQC: a quality control tool for high throughput sequence data. Available online at: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- **MultiQC**: Ewels, P., Magnusson, M., Lundin, S. and Käller, M., 2016. MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*, 32(19), pp.3047-3048.


## Changelog

### Version 1.0.0
- Initial release
- Basic chloroplast assembly workflow using GetOrganelle
- Quality control and reporting features with FastQC and MultiQC
- Comprehensive sequence statistics generation
- Modular subworkflow architecture
- Support for conda and container execution

---

**Author**: André Bourbonnais (ndreey)  
**Pipeline**: Orchid Chloroplast Assembly  
**Nextflow Version**: ≥21.04.0