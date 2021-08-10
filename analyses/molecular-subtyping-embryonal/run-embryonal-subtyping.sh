#!/bin/bash
#
# Jaclyn Taroni for ALSF CCDL 2020
#
# This shell script runs the analysis module for molecularly subtyping embryonal
# tumors.

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# This option controls whether on not the step that generates the subset
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# Generate JSON file with strings for inclusion/exclusion criteria
Rscript --vanilla 00-embryonal-select-pathology-dx.R

# Run the first script in this module that identifies non-ATRT and non-MB
# embryonal tumors and those tumors with TTYH1 fusions for the purposes of
# subsetting files downstream
Rscript --vanilla 01-samples-to-subset.Rmd

# Run the second script in this module that subset files using the samples in
# the output file generated with `01-samples-to-subset.Rmd`.
if [ "$SUBSET" -gt "0" ]; then
  Rscript --vanilla 02-generate-subset-files.R
fi

# Run C19mc notebook
Rscript --vanilla 03-clean-c19mc-data.R

# Run notebook that wrangles all the relevant data
Rscript --vanilla 04-table-prep.R

echo "done in ${BASH_SOURCE[0]}"
