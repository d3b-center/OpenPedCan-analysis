#!/bin/bash

set -e
set -o pipefail

# set up running directory
cd "$(dirname "${BASH_SOURCE[0]}")" 

# Run R script to subtype ATRT using methylation data 

Rscript --vanilla 00-ATRT_subtyping.R

