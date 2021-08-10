#!/bin/bash
#
# Krutika Gaonkar D3b
#
# Integrate molecular subtyping results

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Add molecular_subtype,	integrated_diagnosis, short_histology,
# broad_histology and	Notes from `compiled_molecular_subtypes_with_clinical_pathology_feedback.tsv`.
# Check for changes and duplicates and save a final file
Rscript --vanilla 01-integrate-subtyping.R

echo "done in ${BASH_SOURCE[0]}"
