#!/bin/bash

set -e
set -o pipefail
# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Run R script to generate json file containing pathology_diagnosis for neurocytoma subsetting
Rscript 00-neurocytoma-select-pathology-dx.R

# Run notebook to get molecular subtype for Neurocytoma samples 
Rscript -e "rmarkdown::render('01-neurocytoma-subtyping.Rmd')"
