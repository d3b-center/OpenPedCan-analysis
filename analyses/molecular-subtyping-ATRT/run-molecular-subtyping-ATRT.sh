#!/bin/bash

# Chante Bethell for CCDL 2019
#
# Run `01-ATRT-molecular-subtyping-data-prep.Rmd` and
# `02-ATRT-molecular-subtyping-plotting.R` sequentially.

set -e
set -o pipefail

# This option controls whether on not the step that generates the ATRT only
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

if [ "$SUBSET" -gt "0" ]; then
  Rscript --vanilla 00-subset-files-for-ATRT.R
fi

Rscript --vanilla 01-ATRT-molecular-subtyping-data-prep.R
Rscript --vanilla 02-ATRT-molecular-subtyping-plotting.R

echo "done in ${BASH_SOURCE[0]}"
