#!/bin/bash
# Module author: Komal S. Rathi
# 2020

# This script runs the steps for molecular subtyping of Medulloblastoma samples

set -e
set -o pipefail

# This option controls whether on not the step that generates the MB only
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

if [ "$SUBSET" -gt "0" ]; then
  # filter to MB samples and/or batch correct
  Rscript --vanilla 01-filter-and-batch-correction.R \
  --batch_col RNA_library \
  --output_prefix medulloblastoma-exprs \
  --output_dir input
fi

# classify MB subtypes
Rscript --vanilla 02-classify-mb.R \
--corrected_mat input/medulloblastoma-exprs-batch-corrected.rds \
--uncorrected_mat input/medulloblastoma-exprs.rds \
--output_prefix mb-classified

# summarize output from both classifiers and expected classification
Rscript --vanilla 03-compare-classes.R

echo "done in ${BASH_SOURCE[0]}"
