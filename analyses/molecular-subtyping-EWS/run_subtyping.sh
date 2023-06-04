#!/bin/bash

set -e
set -o pipefail

# set up running directory
cd "$(dirname "${BASH_SOURCE[0]}")" 

# Run R script to generate pathology JSON fiel for sample subsetting

Rscript 00-EWS-select-pathology-dx.R

# Run notebook to subtype EWS per sample_id if  hallmark fusion in RNAseq samples 

Rscript -e "rmarkdown::render('01-run-subtyping-ewings.Rmd')"


