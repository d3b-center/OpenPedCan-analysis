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

mkdir -p test

# Module author: Sangeeta Shukla, Alvin Farrell
# Shell script author: Sangeeta Shukla
# 2021

#This script creates a subset of the histologies.tsv, to use for testing the deseq module.

Rscript --vanilla process_test_input.R \
        --hist_file ../../data/histologies_original.tsv \
        --counts_file ../../data/gene-counts-rsem-expected_count-collapsed.rds \
        --outdir test


Rscript --vanilla run-DESeq-analysis.R \
        --hist_file test/histologies_subset.tsv \
        --counts_file ../../data/gene-counts-rsem-expected_count-collapsed.rds \
        --tpm_file ../../data/gene-expression-rsem-tpm-collapsed.rds  \
        --efo_mondo_file ../../data/efo-mondo-map.tsv \
        --gtex_subgroup_uberon ../../data/uberon-map-gtex-subgroup.tsv \
        --ensg_hugo_file ../../data/ensg-hugo-rmtl-mapping.tsv \
        --outdir results        
