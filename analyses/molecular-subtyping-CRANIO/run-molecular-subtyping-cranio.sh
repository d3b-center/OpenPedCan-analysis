#!/bin/bash

set -e
set -o pipefail
# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Run notebook
Rscript --vanilla 00-craniopharyngiomas-molecular-subtype.R

echo "done in ${BASH_SOURCE[0]}"
