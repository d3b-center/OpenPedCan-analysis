#!/bin/bash

# Bethell and Taroni for CCDL 2019
# Run the dimension reduction plotting pipeline. Samples will be colored by
# user-specified variable. It will be broad_histology by default.

set -e
set -o pipefail

COLORVAR=${COLOR:-broad_histology}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# PCA, UMAP, t-SNE step
bash 01-dimension-reduction.sh

# Generate plot lists to be used to make multipanel plots
COLOR=${COLORVAR} bash 02-get-dimension-reduction-plot-lists.sh
# Make multipanel plots and save as PDFs
bash 03-multipanel-plots.sh
