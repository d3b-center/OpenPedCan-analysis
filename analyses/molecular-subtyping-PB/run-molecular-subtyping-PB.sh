#!/bin/bash 

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# This will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

scratch_path="../../scratch/"
data_dir="../../data"



# Run R script to generate JSON file
Rscript --vanilla 00-PB-select-pathology-dx.R

# Run R script to subtype PB using methylation data 
Rscript -e "rmarkdown::render('01-molecular-subtype-pineoblastoma.Rmd', clean = TRUE)"


if [ "$SUBSET" -gt "0" ]; then
  echo "check whether methylation files exist"
  URL="https://d3b-openaccess-us-east-1-prd-pbta.s3.amazonaws.com/open-targets"
  RELEASE="v15"
  BETA="methyl-beta-values.rds"
  if [ -f "${data_dir}/${BETA}" ]; then
      echo "${BETA} exists, skip downloading"
      echo "run pineoblastoma clustering"
      # add umap
      Rscript -e "rmarkdown::render('02-pineoblastoma-umap.Rmd', clean = TRUE)"
    else 
      echo "${BETA} does not exist, downloading..."
      wget ${URL}/${RELEASE}/${BETA} -P ${data_dir}/${RELEASE}/
      cd ${data_dir}
      ln -sfn ${RELEASE}/${BETA} ./${BETA}
      cd ../analyses/molecular-subtyping-MB
      echo "run pineoblastoma clustering"
      # add umap
      Rscript -e "rmarkdown::render('02-pineoblastoma-umap.Rmd', clean = TRUE)"
  fi
  