#!/bin/bash

set -e
set -o pipefail

# set up running directory
cd "$(dirname "${BASH_SOURCE[0]}")" 

# Run script to select pathology diagnoses
Rscript --vanilla 00-select-diagnoses.R

# Run script to subset CNV and TPM files for MYCN calls
Rscript -e "rmarkdown::render('01-subset-for-NBL.Rmd')"

# Match DNA and RNA biospecimens
Rscript -e "rmarkdown::render('02-find-matched-biospecimen.Rmd')"

# Find non-matching specimens
Rscript -e "rmarkdown::render('03-find-non-matching-biospecimen.Rmd')"

# Perform subtyping
Rscript -e "rmarkdown::render('04-subtyping.Rmd')"

# Run QC checks
Rscript -e "rmarkdown::render('05-qc-checks.Rmd')"

echo 'NBL Subtyping Completed'

