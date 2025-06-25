#!/bin/bash
# Module author: Aditya Lahiri
# Shell script author: Jo Lynne Rokita
# 2022

# This script runs the steps for generating manuscript tables.

set -e
set -o pipefail

# run the notebook to create manuscript tables
Rscript -e "rmarkdown::render('01-output_tables.Rmd')"

# run the R script to create molecular tables
Rscript --vanilla 02-module-descriptions.R

# run the R script to create molecular tables
Rscript --vanilla 03-molecular_subtype_table.R

# run the Rscript to create QC table
Rscript -e "rmarkdown::render('04-rna_dna_qc_table.Rmd')"

# run the R script to create software tables
Rscript -e "rmarkdown::render('05-software_version.Rmd')"

