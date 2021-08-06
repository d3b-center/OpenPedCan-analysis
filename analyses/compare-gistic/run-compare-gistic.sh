#!/bin/bash

# Chante Bethell for CCDL 2020
#
# Run the GISTIC comparison R notebooks in this module sequentially.

set -e
set -o pipefail

IS_CI=${OPENPBTA_TESTING:-0}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

Rscript -e "rmarkdown::render('01-GISTIC-cohort-vs-histology-comparison.Rmd', clean = TRUE)"
Rscript -e "rmarkdown::render('02-GISTIC-tidy-data-prep.Rmd', clean = TRUE)"
Rscript -e "rmarkdown::render('03-GISTIC-gene-level-tally.Rmd', clean = TRUE, params = list(is_ci = ${IS_CI}))"
