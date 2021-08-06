#!/bin/bash
# Module author: Komal S. Rathi
# 2019

# This script runs the steps for immune deconvolution in PBTA histologies using xCell.
# xCell is the most comprehensive deconvolution method (with the largest number of cell types) and widely used in literature vs other deconvolution methods.
# Reference for benchmarking between xCell and other methods: PMID: 31641033

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# create results directory if it doesn't already exist
mkdir -p results
mkdir -p plots

# generate deconvolution output for poly-A and stranded datasets using xCell
Rscript --vanilla 01-immune-deconv.R \
--polyaexprs '../../data/pbta-gene-expression-rsem-fpkm-collapsed.polya.rds' \
--strandedexprs '../../data/pbta-gene-expression-rsem-fpkm-collapsed.stranded.rds' \
--clin '../../data/pbta-histologies.tsv' \
--method 'xcell' \
--outputfile 'results/deconv-output.RData'

echo "Deconvolution finished..."
echo "Create summary plots"

# Now, run the script to generate heatmaps of average normalized immune scores for xCell, stratified by histology and by molecular subtype
Rscript --vanilla 02-summary-plots.R \
--input 'results/deconv-output.RData' \
--output_dir 'plots'
