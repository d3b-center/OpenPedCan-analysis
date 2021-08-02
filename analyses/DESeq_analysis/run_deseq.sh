#!/bin/bash

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# create results directory if it doesn't already exist
mkdir -p results

# Module author: Sangeeta Shukla, Alvin Farrell
# Shell script author: Sangeeta Shukla
# 2021

# This script runs the steps for differential expression analysis
# for combinations of GTEx subgroup and histology type







Rscript --vanilla ./deseq_analysis/run-DESeq-analysis.R \
        --hist_file ../Data/histologies.tsv \
        --counts_file ../Data/gene-counts-rsem-expected_count-collapsed.rds \
        --tpm_file ../Data/gene-expression-rsem-tpm-collapsed.rds  \
        --efo_mondo_file ../Data/efo-mondo-map.tsv \
        --ensg_hugo_file ../Data/ensg-hugo-rmtl-mapping.tsv \
        --outdir Results







