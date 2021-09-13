#!/bin/bash

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Module author: Sangeeta Shukla, Alvin Farrell
# Shell script author: Sangeeta Shukla
# 2021

#This script creates a subset of the histologies.tsv, to use for testing the deseq module.

module load R/4.1.0
Rscript --vanilla run-Generate_Hist_GTex_indices_file_SS.R \
        --hist_file ../../data/histologies.tsv \
        --counts_file ../../data/gene-counts-rsem-expected_count-collapsed.rds \
        --outdir Input_Data
