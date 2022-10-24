#!/bin/bash
# PediatricOpenTargets 2021
# Eric Wafula
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

printf '\nStarting Analysis...\n'

# Create tmp/ directory for R scripts
mkdir -m777 ./tmp

####################### Create methylation array probe annotations ########################
TMP=./tmp TMPDIR=./tmp Rscript --vanilla 01-create-methylation-annotation-table.R

######################## Create Beta-value  and M-values matrices #########################
TMP=./tmp TMPDIR=./tmp Rscript --vanilla 02-create-methylation-matrices.R

###################### Calculate probe-level Beta-value quantiles #########################
TMP=./tmp TMPDIR=./tmp Rscript --vanilla 03-calculate-beta-quantiles.R

############ Calculate probe-level correlations between Beta and TPM values ###############
python3 04-beta-tpm-correlation.py

############################ Create methylation summary table #############################
TMP=./tmp TMPDIR=./tmp Rscript --vanilla 05-create-methylation-summary-table.R

########################### Convert JSON to JSON Lines (JSONL) ############################
python3 06-methly-summary-tsv2jsonl.py

printf '\nAnalysis Done...\n'
