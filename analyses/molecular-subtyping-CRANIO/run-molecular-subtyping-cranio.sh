#!/bin/bash

set -e
set -o pipefail
# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Run rscript to generate json file for cranio subsetting
Rscript --vanilla 00-CRANIO-select-pathology-dx.R

# Run notebook
Rscript -e "rmarkdown::render('01-craniopharyngiomas-molecular-subtype.Rmd')"
