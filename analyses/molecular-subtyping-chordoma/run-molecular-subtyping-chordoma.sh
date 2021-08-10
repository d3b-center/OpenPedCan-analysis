#!/bin/bash

# Written originally Chante Bethell 2019
# (Adapted for this module by Candace Savonen 2020)
#
# Run `00-subset-files-for-chordoma.R` and
# `01-Subtype-chordoma.Rmd` sequentially.

set -e
set -o pipefail

# This option controls whether on not the step that generates the Chordoma only
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

if [ "$SUBSET" -gt "0" ]; then
  Rscript --vanilla 00-subset-files-for-chordoma.R
fi

Rscript --vanilla 01-Subtype-chordoma.R

echo "done in ${BASH_SOURCE[0]}"
