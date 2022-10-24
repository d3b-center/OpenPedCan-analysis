#!/bin/bash
# Module author: Komal S. Rathi, updated Kelsey Keith
# 2022-07

# This script runs the steps for immune deconvolution using xCell and quanTIseq. 

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

### xCell
# generate deconvolution output
echo "Deconvolution xCell..."
Rscript --vanilla 01-immune-deconv.R \
--expr_mat '../../data/gene-expression-rsem-tpm-collapsed.rds' \
--clin_file '../../data/histologies.tsv' \
--deconv_method 'xcell' \
--output_dir 'results'

# generate heatmaps of average normalized immune scores per cancer or gtex group
echo "Create summary plots xCell"
Rscript --vanilla 02-summary-plots.R \
--deconv_output 'results/xcell_output.rds' \
--output_dir 'plots'

### quanTIseq
# generate deconvolution output
echo "Deconvolution quanTIseq..."
Rscript --vanilla 01-immune-deconv.R \
--expr_mat '../../data/gene-expression-rsem-tpm-collapsed.rds' \
--clin_file '../../data/histologies.tsv' \
--deconv_method 'quantiseq' \
--output_dir 'results'

# generate heatmaps of average normalized immune scores per cancer or gtex group
echo "Create summary plots quanTIseq"
Rscript --vanilla 02-summary-plots.R \
--deconv_output 'results/quantiseq_output.rds' \
--output_dir 'plots'


