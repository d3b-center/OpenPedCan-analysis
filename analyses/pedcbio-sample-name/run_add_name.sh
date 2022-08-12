#!/bin/bash
# PediatricOpenTargets 2021

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
# copied from https://github.com/AlexsLemonade/OpenPBTA-analysis/blob/master/scripts/run_in_ci.sh
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

hist_dir="../../data"

# Compare all methods and
Rscript --vanilla pedcbio_sample_name_col.R \
--hist_dir $hist_dir