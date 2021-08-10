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







Rscript --vanilla run-DESeq-analysis.R \
        --hist_file ../../data/v7/histologies.tsv \
        --counts_file ../../data/v7/gene-counts-rsem-expected_count-collapsed.rds \
        --tpm_file ../../data/v7/gene-expression-rsem-tpm-collapsed.rds  \
        --efo_mondo_file ../../data/v7/efo-mondo-map.tsv \
        --gtex_subgroup_uberon ../../data/v7/uberon-map-gtex-subgroup.tsv \
        --ensg_hugo_file ../../data/v7/ensg-hugo-rmtl-mapping.tsv \
        --outdir results







