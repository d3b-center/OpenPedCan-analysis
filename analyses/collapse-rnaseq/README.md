## Collapse RNA-seq matrices

Many downstream modules require RNA-seq data that have gene symbols as gene identifiers.
Multiple Ensembl gene identifiers map to the same gene symbol in a small proportion of cases.
This module contains the script used to create RSEM matrices with duplicate gene symbols removed, by first filtering to only genes with [FPKM/TPM] > 0 and then selecting the instance of the gene symbol with the maximum mean [FPKM/TPM/Expected_count] value across samples.
It produces the files with below naming patterns included in the data download:

```
gene-[expression/counts]-rsem-[fpkm/tpm/expected_count]-collapsed.rds
```

This script also runs the notebook for analysis of the dropped genes, and produces a markdown report.

```
gene-[expression/counts]-rsem-[fpkm/tpm/expected_count]-collapsed_table.rds
```

To run the steps that generate the matrices and display the results of a correlation analysis, use the following command (assuming you are in this directory):

```sh
bash run-collapse-rnaseq.sh -q <quatification_type> -x <'type_of_data'>
```

Acceptable values for the options are below:

<quatification_type> : 'fpkm', 'tpm', 'expected_count' <br>
<type_of_data> : 'expression', 'counts' <br>


### R scripts and notebook

* `00-create-rsem-files.R` - this script is used to split RSEM files into two matrices, one for each library strategy. This step occurs upstream of this repository to produce the RSEM files included in the data download. 
This script is not run via `run-collapse-rnaseq.sh`.
* `01-summarize_matrices.R` - this script generates the collapsed matrices as described above.
In addition, this script calculates the average Pearson correlation between the values of the gene symbol that is kept and those duplicates that are discarded.
* `02-analyze-drops.Rmd` - this is used to display tables from `01-summarize_matrices.R`.

## CWL Tools and scripts
This contains a cwl workflow wrapper (to run using cwlrunner or on a cwl-enabled platform, like CAVATICA).
The workflow runs a liftover step and a convert-to-red step.
The wrapper `.sh` script runs the python script and gzips the outputs in the end.
The python script does the liftover and collapse with no compression.
Since it uses base python packages, one can run it in any environment with a standard python3 installation.
The convert-to-rds step is for downstream compatibility with modules
```
cwl
├── scripts
│   ├── convert_to_rds.R
│   ├── liftover_collapse_rnaseq.py
│   └── liftover_collapse_rnaseq_wrapper.sh
├── tools
│   ├── convert_to_rds.cwl
│   └── liftover_collapse_rnaseq.cwl
└── workflows
    └── liftover_collapse_exp_wf.cwl
```

### analyses/collapse-rnaseq/cwl/workflows/liftover_collapse_exp_wf.cwl
This workflow wrapper runs all of the tools described below

### analyses/collapse-rnaseq/cwl/scripts/liftover_collapse_rnaseq.py
```
usage: liftover_collapse_rnaseq.py [-h] [-t TABLE] [-o OUT] [-i GTF] [-g GENE_ID] [-n GENE_NAME] [-s SKIP] [-c]

Script to use a GTF and expression matrix with ENSG to liftover gene symbols.

optional arguments:
  -h, --help            show this help message and exit
  -t TABLE, --table TABLE
                        Input expression matrix. Can be gzipped or plain tsv
  -o OUT, --output-basename OUT
                        output basename of liftover and collapse if flag given
  -i GTF, --input-gtf GTF
                        GTF file to use as liftover reference. Can be gzipped or plain tsv
  -g GENE_ID, --gene-id GENE_ID
                        NAME of gene ID (ENSG values) column
  -n GENE_NAME, --gene-name GENE_NAME
                        NAME of gene name column, if present to keep if not found
  -s SKIP, --skip SKIP  Number of lines to skip if needed
  -c, --collapse        If set, will collapse on gene_symbol
```
Examples:
`python3 liftover_collapse_rnaseq.py -t TCGA_gene_counts.tsv -o TCGA -i gencode.v39.primary_assembly.gtf -g Gene_id -n Gene_name --collapse 2> errs.log` will generate:
```
├── TCGA.collapsed.tsv
├── TCGA.liftover.tsv
```
### analyses/collapse-rnaseq/cwl/tools/ubuntu_gzip.cwl
gzips the output from liftover step

### analyses/collapse-rnaseq/cwl/scripts/convert_to_rds.R
```
Usage: convert_to_rds.R [options]


Options:
	--input-tsv=INPUT-TSV
		tsv RNA expression matrix

	--gene-col=GENE-COL
		Name of column with gene symbol

	--output-filename=OUTPUT-FILENAME
		Output file name, should fit pattern gene-[expression/counts]-rsem-[fpkm/tpm/expected_count]-collapsed.rds

	-h, --help
		Show this help message and exit
```
Example run with collapsed TCGA output:
`Rscript convert_to_rds.R --gene-col gene_name --input-tsv TCGA_v36_TEST.collapsed.tsv.gz --output-filename fancy_long_filename.rds`