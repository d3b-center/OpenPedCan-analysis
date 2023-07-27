#!/bin/bash
# PediatricOpenTargets 2022
# Eric
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Set up paths results directory
results_path="results"

#remove all the files in results folder
rm $results_path/*

printf '\nStart data pre-release QC analysis...'

Rscript -e "rmarkdown::render('01-data-harmonization-qc.Rmd', clean = TRUE)"

printf '\nAnalysis Done...\n'
