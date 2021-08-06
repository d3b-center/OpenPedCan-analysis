#!/bin/bash

# Pichai Raman - taken from --> (Chante Bethell for CCDL 2019)
#
# Run `01-run-ssgsea.R` and `02-analyze-plot-ssgsea-res.R`
# sequentially.

# This script should always run as if it were being called from
# the directory it lives in.

set -e
set -o pipefail

ANOVAPVALUE=${OPENPBTA_ANOVAPVALUE:-0.01}
TUKEYPVALUE=${OPENPBTA_TUKEYPVALUE:-0.05}
PERCKEEP=${OPENPBTA_PERCKEEP:-0.25}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

Rscript --vanilla 01-run-ssgsea.R
Rscript --vanilla 02-analyze-plot-ssgsea-res.R -a $ANOVAPVALUE -t $TUKEYPVALUE -p $PERCKEEP
