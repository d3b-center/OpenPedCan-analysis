#!/bin/bash

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# This determines whether the analysis run in CI or not
# Default (1) is to run the full dataset
SUBSET=${OPENPBTA_SUBSET:-1}

Rscript -e "rmarkdown::render('01-fusion-summary.Rmd', clean = TRUE, params=list(ci_run = $SUBSET))"
