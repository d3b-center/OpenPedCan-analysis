#!/bin/bash
# Module author: Komal S. Rathi
# 2020

# This script runs the steps for molecular subtyping of Medulloblastoma samples

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

scratch_path="../../scratch/"

# filter to MB samples and/or batch correct
Rscript --vanilla 01-filter-and-batch-correction.R \
  --output_prefix medulloblastoma-exprs \
  --scratch_dir $scratch_path

# classify MB subtypes
Rscript --vanilla 02-classify-mb.R \
--exprs_mat ${scratch_path}/medulloblastoma-exprs.rds \
--data_type 'uncorrected' \
--output_prefix mb-classified

# summarize output from both classifiers and expected classification
# Rscript -e "rmarkdown::render('03-compare-classes.Rmd', clean = TRUE)"

# classify samples with no RNA as "MB, To be classified"
Rscript --vanilla 04-subtype-mb-samples.R

