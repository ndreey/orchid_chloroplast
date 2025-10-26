# Orchid Chloroplast
_Excuse the mess, pipeline still in progress_

Nextflow pipeline for processing chloroplast short read data. 

## Overview
Orchid Chloroplast is a Nextflow-based pipeline for plastome assembly, annotation, QC and comparative analyses. The workflow orchestrates read QC, trimming, plastome assembly ([GetOrganelle](https://github.com/Kinggerm/GetOrganelle)), annotation ([PGA2](https://github.com/quxiaojian/PGA2) / [PlastidHub](https://github.com/quxiaojian/PlastidHub)), sequence extraction and downstream comparative analyses used in plastid phylogenomics.

## Workflow

The pipeline consists of the following main steps:

1. **Read Trimming** 
2. **Quality Control** - Pre and post-trimming assessment and validate fastq files
3. **Chloroplast Assembly**
5. **Annotation**
6. **Assessment**
6. **Amplicon extraction**
7. tba

## Tools and Dependencies

### Core Tools
- **[GetOrganelle](https://github.com/Kinggerm/GetOrganelle)** (v1.7.7.1) - Plastome Assembler
- **[FASTP](https://github.com/OpenGene/fastp)** (v1.0.1) - Ultra-fast all-in-one FASTQ preprocessor
- **[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)** (v0.12.1) - Quality control tool for high throughput sequence data
- **[MultiQC](https://multiqc.info/)** (v1.19) - Aggregate results from bioinformatics analyses
- **[SeqKit](https://github.com/shenwei356/seqkit)** (v2.10.1) - Cross-platform toolkit for FASTA/Q file manipulation
- **[PlastidHub](https://github.com/quxiaojian/PlastidHub)** (v1.0) - An integrated analysis platform for plastid phylogenomics and comparative genomics


### Environment Management
- **Conda/Mamba** - Package and environment management
- **Wave containers** - Containerized execution support (tba)

## Quick Start

### Prerequisites
- Nextflow (≥ 21.04.0)
- tba

### Installation
```bash
git clone https://github.com/ndreey/orchid_chloroplast.git
cd orchid_chloroplast
```
## Configuration

The pipeline uses several configuration files:
- `nextflow.config`: Main Nextflow configuration with profiles
- `parameters.yml`: Default parameter values and conda environments

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

## Output Structure

```
results/
├── 00-QC
│   ├── fastqc-raw
│   ├── fastqc-trim
│   ├── multiqc-fastp
│   ├── multiqc-raw
│   └── multiqc-trim
├── 01-trimmed
├── 02-get_organelle
├── 03-get_org_polish
├── 04-plastome-structure
├── 05-plastome-annotation
├── 06-plastome-assesment
├── 07-marker_pairs-amplicons
│   ├── bed
│   └── fasta
├── chloroplast_genomes
│   ├── complete
│   ├── nearly-complete
│   └── scaffolds
└── stats
```

## Citation
If you use this pipeline in your research, please cite:

**PlastidHub**: Na-Na Zhang, Gregory W. Stull, Xue-Jie Zhang, Shou-Jin Fan, Ting-Shuang Yi, Xiao-Jian Qu. PlastidHub: an integrated analysis platform for plastid phylogenomics and comparative genomics. Plant Diversity, 2025, https://doi.org/10.1016/j.pld.2025.05.005.

**SeqKit**: Wei Shen*, Botond Sipos, and Liuyang Zhao. 2024. SeqKit2: A Swiss Army Knife for Sequence and Alignment Processing. iMeta e191. doi:10.1002/imt2.191.

**fastp**: Shifu Chen. 2025. fastp 1.0: An ultra-fast all-round tool for FASTQ data quality control and preprocessing. iMeta 2025: https://doi.org/10.1002/imt2.107

**GetOrganelle**: Jian-Jun Jin*, Wen-Bin Yu*, Jun-Bo Yang, Yu Song, Claude W. dePamphilis, Ting-Shuang Yi, De-Zhu Li. GetOrganelle: a fast and versatile toolkit for accurate de novo assembly of organelle genomes. Genome Biology 21, 241 (2020). https://doi.org/10.1186/s13059-020-02154-5

**SPAdes**: Prjibelski, A., Antipov, D., Meleshko, D., Lapidus, A. and Korobeynikov, A. 2020. Using SPAdes de novo assembler. Current protocols in bioinformatics, 70(1), p.e102.

**Bowtie2**: Langmead, B. and S. L. Salzberg. 2012. Fast gapped-read alignment with Bowtie 2. Nature Methods 9: 357-359.

**BLAST+**: Camacho, C., G. Coulouris, V. Avagyan, N. Ma, J. Papadopoulos, K. Bealer and T. L. Madden. 2009. BLAST+: architecture and applications. BMC Bioinformatics 10: 421.

**Bandage**: Wick, R. R., M. B. Schultz, J. Zobel and K. E. Holt. 2015. Bandage: interactive visualization of de novo genome assemblies. Bioinformatics 31: 3350-3352.

**FastQC**: Andrews, S. (2010). FastQC. A quality control tool for high throughput sequence data. 
http://www.bioinformatics.babraham.ac.uk/projects/fastqc

**MultiQC**: Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: Summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 32(19), 3047
3048. https://doi.org/10.1093/bioinformatics/btw354

---

**Author**: André Bourbonnais (ndreey)  
**Pipeline**: Orchid Chloroplast Assembly  
**Nextflow Version**: ≥21.04.0