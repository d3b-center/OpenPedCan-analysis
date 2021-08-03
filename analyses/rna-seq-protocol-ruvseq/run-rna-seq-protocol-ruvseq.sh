#!/bin/bash
# PediatricOpenTargets 2021
# Yuanchao Zhang
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
# copied from https://github.com/AlexsLemonade/OpenPBTA-analysis/blob/master/scripts/run_in_ci.sh
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# create results directory if it doesn't already exist
mkdir -p results
mkdir -p plots

for emp_neg_ctrl_gene_set in "stable" "DESeq2"; do
  for dataset in "match" "dipg" "nbl"; do
    echo "Run RUVSeq DESeq2 differential gene expression analysis on RNA-seq libraries with dataset $dataset and empirical negative control gene set $emp_neg_ctrl_gene_set ..."
    Rscript --vanilla '01-protocol-ruvseq.R' -d $dataset -e $emp_neg_ctrl_gene_set
  done
done

echo 'Done running run-rna-seq-protocol-ruvseq.sh.'
