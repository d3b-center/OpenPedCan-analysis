#!/bin/bash
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
# copied from the run_in_ci.sh file at
# <https://github.com/AlexsLemonade/OpenPBTA-analysis/blob/master/scripts/>
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

mkdir -p results

## Match ensembl to gene_symbol using gtf file

Rscript --vanilla 01-gene-ensembl-id-from-gtf.R --gtf_file input/gencode.v27.annotation.gtf.gz --output_file results/ensembl_gene_symbol_gtf_gencode_v27.tsv
Rscript --vanilla 01-gene-ensembl-id-from-gtf.R --gtf_file input/gencode.v28.annotation.gtf.gz --output_file results/ensembl_gene_symbol_gtf_gencode_v28.tsv
Rscript --vanilla 01-gene-ensembl-id-from-gtf.R --gtf_file input/gencode.v36.annotation.gtf.gz --output_file results/ensembl_gene_symbol_gtf_gencode_v36.tsv
Rscript --vanilla 01-gene-ensembl-id-from-gtf.R --gtf_file input/gencode.v39.annotation.gtf.gz --output_file results/ensembl_gene_symbol_gtf_gencode_v39.tsv

## Merge all gencode results and input/open_ped_can_v7_ensg-hugo-rmtl-mapping.tsv

Rscript --vanilla 02-merge-gencode-ensg-symbol-map.R
# creates gencode_ensg_symbol_map_merged.tsv

## Merge PMTL
Rscript -e "rmarkdown::render('03-add-pmtl-ensg-hugo.Rmd')"

Rscript -e "rmarkdown::render('04-qc-ensg-hugo-pmtl-mapping.Rmd', clean = TRUE)"
