#!/bin/bash
# Module author: Aditya Lahiri
# Shell script author: Jo Lynne Rokita
# 2022

# This script runs the steps for generating manuscript tables.

set -e
set -o pipefail

# run the notebook to create manuscript tables
Rscript -e "rmarkdown::render('output_tables.Rmd')"