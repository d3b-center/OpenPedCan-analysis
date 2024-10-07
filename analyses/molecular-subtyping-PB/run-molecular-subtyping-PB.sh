#!/bin/bash 

set -e
set -o pipefail

# set up running directory
cd "$(dirname "${BASH_SOURCE[0]}")" 

# Run R script to generate JSON file
Rscript --vanilla 00-PB-select-pathology-dx.R

# Run R script to subtype PB using methylation data 
Rscript -e "rmarkdown::render('01-molecular-subtype-pineoblastoma.Rmd', clean = TRUE)"

# add umap
Rscript -e "rmarkdown::render('02-pineoblastoma-umap.Rmd', clean = TRUE)"
