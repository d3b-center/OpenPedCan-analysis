#!/bin/bash

# R. Corbett (adapted from J. Taroni for ALSF CCDL)
# December 2022

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# In CI we'll run an abbreviated version of the de novo signatures extraction
ABBREVIATED_MUTSIGS=${OPC_QUICK_MUTSIGS:-0}

# Run the SBS mutational signatures analysis using existing signatures
Rscript -e "rmarkdown::render('01-known_signatures.Rmd', clean = TRUE)"

# Run the mutational signatures analysis using COSMIC DBS signatures (v3.3)
Rscript -e "rmarkdown::render('02-cosmic_dbs_signatures.Rmd', clean = TRUE)"

# Run analysis of adult CNS mutational signatures
Rscript --vanilla 03-fit_cns_signatures.R

# Run mutational signature summary of hypermutant tumors
Rscript -e "rmarkdown::render('04-explore_hypermutators.Rmd', clean = TRUE)"