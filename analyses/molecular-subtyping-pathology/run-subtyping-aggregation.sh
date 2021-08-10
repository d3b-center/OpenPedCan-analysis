#!/bin/bash
#
# J. Taroni for ALSF CCDL 2020
#
# Run aggregation of molecular subtyping/reclassification results and the
# incorporation of pathology feedback

set -e
set -o pipefail

# We're using this to tie the clinical file to a specific release when this
# is not run in CI
IS_CI=${OPENPBTA_TESTING:-0}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Run the first notebook that compiles all the results from other modules into
# a single table
Rscript --vanilla 01-compile-subtyping-results.R --is_ci ${IS_CI}

# Recoding ACP samples
Rscript --vanilla pathology-subtyping-craniopharyngioma.R

# Run the second notebook to incorporate clinical review to the compiled subtyping
Rscript --vanilla 02-incorporate-clinical-feedback.R

# Run the third notebook that incorporates pathology feedback into final labels
Rscript --vanilla 03-incorporate-pathology-feedback.R --is_ci ${IS_CI}

# Run the meningioma pathology-free-text based subtyping step
Rscript --vanilla pathology_free_text-subtyping-meningioma.R

# Glialneuronal tumors
Rscript --vanilla pathology-harmonized-diagnosis-glialneuronal-tumors.R

# Choroid plexus papilloma
Rscript --vanilla pathology-subtyping-choroid-plexus-papilloma.R

echo "done in ${BASH_SOURCE[0]}"
