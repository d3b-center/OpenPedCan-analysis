#!/bin/bash
# OPenPedCan 2022
# Eric Wafula
set -e
set -o pipefail

printf "Start methylation pre-processing...\n\n"

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Set up paths to input and output directories for the analysis
absolute_path=$(cd "$(dirname "$0")"; pwd -P)
data_path="${absolute_path}/data"
results_path="results"

######################### Process `NBL` samples for Illumina 450k arrays ############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/NBL \
  --controls_present TRUE \
  --snp_filter TRUE

######################### Process `CCSK` samples for Illumina 450k arrays ############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CCSK \
  --controls_present FALSE \
  --snp_filter TRUE

######################### Process `OS` samples for Illumina 450k arrays ##############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/OS \
  --controls_present FALSE \
  --snp_filter TRUE

######################### Process `WT` samples for Illumina 450k arrays ##############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/WT \
  --controls_present FALSE \
  --snp_filter TRUE

######################### Process `AML` samples for Illumina 450k arrays #############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/AML \
  --controls_present TRUE \
  --snp_filter TRUE

######################### Process `CBTN` samples for Illumina 850k arrays ############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CBTN \
  --controls_present TRUE \
  --snp_filter TRUE

######################### Merge methyl matrices for all datasets #####################################
Rscript --vanilla 02-merge-methyl-matrices.R

######################### Remove intermediate analysis results #######################################
rm ${results_path}/*-methyl-beta-values.rds
rm ${results_path}/*-methyl-m-values.rds
rm ${results_path}/*-methyl-cn-values.rds

printf "\nAnalysis Done...\n\n"
