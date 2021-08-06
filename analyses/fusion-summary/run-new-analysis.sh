#!/bin/bash

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

Rscript -e "rmarkdown::render('01-fusion-summary.Rmd', clean = TRUE)"
