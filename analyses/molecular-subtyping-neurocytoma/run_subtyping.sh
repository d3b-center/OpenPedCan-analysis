#!/bin/bash

set -e
set -o pipefail
# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Run notebook to get molecular subtype for Neurocytoma samples
Rscript --vanilla 01-neurocytoma-subtyping.R

echo "done in ${BASH_SOURCE[0]}"
