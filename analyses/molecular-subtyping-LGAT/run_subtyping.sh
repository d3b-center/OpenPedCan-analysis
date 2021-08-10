#!/bin/bash

set -e
set -o pipefail
# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# This option controls whether on not the step that generates the LGAT only mutation
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# subset by SNV
Rscript --vanilla 01-subset-files-for-LGAT.R
# subset by Fusion
Rscript --vanilla 02-subset-fusion-files-LGAT.R


if [ "$SUBSET" -gt "0" ]; then
# subset by CNV
  Rscript --vanilla 03-subset-cnv-files-LGAT.R
fi


# compile subtypes
Rscript --vanilla 04-LGAT-compile-subtypes.R

echo "done in ${BASH_SOURCE[0]}"
