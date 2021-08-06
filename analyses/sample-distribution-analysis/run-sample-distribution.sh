#!/bin/bash

# Chante Bethell for CCDL 2019
#
# Run `01-filter-across-types.R` and `02-multilayer-plots.R`
# sequentially.

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

Rscript --vanilla 01-filter-across-types.R
Rscript --vanilla 02-multilayer-plots.R
Rscript -e "rmarkdown::render('03-tumor-descriptor-and-assay-count.Rmd', clean = TRUE)"
