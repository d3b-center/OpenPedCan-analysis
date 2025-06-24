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

# This option controls whether on not the step that generates the HGG only
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

scratch_path="../../scratch/"
data_dir="../../data"

# select MB samples
Rscript -e "rmarkdown::render('00-mb-select-pathology-dx.Rmd', clean = TRUE)"

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

echo "classify samples with no RNA as MB, To be classified"
Rscript --vanilla 04-subtype-mb-samples.R

if [ "$SUBSET" -gt "0" ]; then
  echo "classify SHH samples into alpha, beta, delta, gamma"
  Rscript --vanilla 05-subtype-mb-shh.R
 
  echo "check whether methylation files exist"
  URL="https://d3b-openaccess-us-east-1-prd-pbta.s3.amazonaws.com/open-targets"
  RELEASE="v15"
  BETA="methyl-beta-values.rds"
  if [ -f "${data_dir}/${BETA}" ]; then
      echo "${BETA} exists, skip downloading"
  else 
      echo "${BETA} does not exist, downloading..."
      wget ${URL}/${RELEASE}/${BETA} -P ${data_dir}/${RELEASE}/
      cd ${data_dir}
      ln -sfn ${RELEASE}/${BETA} ./${BETA}
      cd ../analyses/molecular-subtyping-MB
  fi

  echo "run umap with methylation"
  Rscript -e "rmarkdown::render('06-mb-shh-umap.Rmd', clean = TRUE)"
  
  echo "compare RNA and methylation-derived molecular subtypes"
  Rscript --vanilla 07-compare-rna-methyl-subtypes.R
fi


