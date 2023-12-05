# OpenPedCan Methylation Array Probe Annotations

## Purpose

This module create Illumina Infinium Human Methylation array CpG probe annotations based on the `Human Build 38 (GRCh38/hg38)` and `GENCODE v39 release`.
The [450K and EPIC Illumina Infinium methylation array CpG probe coordinates](https://support.illumina.com/array/array_kits/infinium-methylationepic-beadchip-kit/downloads.html) are based on the `Human Build 37 (GRCh37/hg19)` genome assembly. 
Probe coordinates are converted to `Human Build 38 (GRCh38/hg38)` using the [ENSEMBL Assembly Converter tool](https://useast.ensembl.org/Homo_sapiens/Tools/AssemblyConverter). 
A probe annotation file, `infinium.gencode.v39.probe.annotations.tsv` is created by annotating all probes lifted over with associated gene features (i.e., `promoter`, `5' UTR`, `exon`, `intron`, `3'UTR`, `three_prime_UTR_extension`, and `intergenic`) based on [GENCODE v39 release](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/) that is currently utilized in the OpenPedCan data analyses. 
Intron coordinates, typically not included in the GFF3/GTF genome annotation formats, are added to the GENCODE annotations file using [GenomeTools](http://genometools.org/). Probe locations are then assigned with their intersecting gene annotation features using [bedtools](https://bedtools.readthedocs.io/en/latest/content/bedtools-suite.html). 


## Analysis scripts
1. **`01-create-bed-files.R`** script create GENCODE gene features and Illumina infinium methylation array CpG probe coordinates input BED files

```
Usage: 01-create-bed-files.R [options]

Options:
  --gencode_gtf=CHARACTER
    GENCODE GTF

  --gencode_gff=CHARACTER
    GENCODE GFF with intron coordinates

  --cpg_map=CHARACTER
    Illumina infinium methylation array CpG probe coordinates

  -h, --help
    Show this help message and exit
```

2. **`02-parse-bedtools-intersect.R`** script reformats the bedtools intersect of the GENCODE gene features and lifted over (GRCh38 to GRCh38) CpG probe coordinates to final OpenPedCan methylation array probe annotations.
```
Usage: 02-parse-bedtools-intersect.R [options]

Options:
  --bed_intersect=CHARACTER
    GENCODE gene fetures and CpG liftover intersect bed file

  -h, --help
    Show this help message and exit
```

3. `run-methyl-probe-annotation.sh` is a wrapper bash script for executing all the other analysis scripts in the module, including creating the GENCODE GFF file inserted intron coordinates and the primary assignment of CpG probe locations to GENCODE gene features. 
```
bash run-methyl-probe-annotation.sh
```

## Input datasets
OpenPedCan-analysis/blob/dev/download-data.sh). 
- `../../data/gencode.v39.primary_assembly.annotation.gtf.gz`
- `../../data/infinium-methylationepic-v-1-0-b5-manifest-file-csv.zip`
- `inputs/gencode.v39.primary_assembly.annotation.gff3.gz`
- `inputs/gencode.v39.primary_assembly.introns.annotation.gff3.gz`
- `inputs/gencode.v39.primary_assembly.gene_features.annotation.bed`
- `inputs/infinium-methylationepic-v-1-0-b5-manifest-file-grch37.bed`
- `inputs/infinium-methylationepic-v-1-0-b5-manifest-file-grch38.bed`

**`NOTE:`** The GpG probe coordinates liftover process is performed by running the running `01-create-bed-files.R` script to create GRCh37 array probe CpG BED file, `inputs/infinium-methylationepic-v-1-0-b5-manifest-file-grch37.bed`, which is then uploaded to the [ENSEMBL Assembly Converter tool](https://useast.ensembl.org/Homo_sapiens/Tools/AssemblyConverter) to generate GRCh38 array probe CpG BED file,`inputs/infinium-methylationepic-v-1-0-b5-manifest-file-grch38.bed`.


## Output datasets
- `results/infinium.gencode.v39.probe.annotations.bedtools.tsv.gz`
- `results/infinium.gencode.v39.probe.annotations.tsv.gz`

