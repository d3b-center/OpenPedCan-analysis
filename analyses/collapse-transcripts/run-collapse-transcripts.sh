#!/bin/bash
# Module author: Jo Lynne Rokita
# 

# Usage: bash run-collapse-transcripts.sh

# This script runs the steps for generating collapsed RNA-seq matrices
# and analyzing the correlation levels of multi-mapped Ensembl genes

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# create results directory if it doesn't already exist
mkdir -p results

# generate collapsed matrices


Rscript --vanilla 01-collapse-transcripts-test.R \
  -i ../../data/rna-isoform-expression-rsem-tpm.rds \
  -g ../../data/gencode.v27.primary_assembly.annotation.gtf.gz \
  -m results/rna-isoform-expression-rsem-tpm-collapsed.rds \
  -t results/rna-isoform-expression-rsem-tpm-collapsed_table.rds


# run the notebook for analysis of dropped genes
#Rscript -e "rmarkdown::render(input = '02-analyze-drops.Rmd', output_file = paste0('02-analyze-drops','-${quantificationType}'),params = list(annot.table = 'results/gene-${expr_count}-rsem-${quantificationType}-collapsed_table.rds'), clean = TRUE)"


