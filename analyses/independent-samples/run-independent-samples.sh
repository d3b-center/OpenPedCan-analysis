#!/bin/bash

# Josh Shapiro for CCDL 2019
#
# Takes one environment variable, `OPENPBTA_BASE_SUBTYPING`, if value is 1 then
# uses histologies-base.tsv and generates only rna-seq independent samples
# for fusion filtering. If value is 0, runs all modules with histologies.tsv (Default).

set -e
set -o pipefail

RUN_FOR_SUBTYPING=${OPENPBTA_BASE_SUBTYPING:-0}

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ "$RUN_FOR_SUBTYPING" -eq "1" ]]
then
	# Run rna-seq only
	Rscript 04-generate-independent-specimens-rnaseq-pre-release.R
else 
	# run initial script
	Rscript -e "rmarkdown::render('00-repeated-samples.Rmd',params=list(base_run = ${RUN_FOR_SUBTYPING}), clean = TRUE)"

	# run script to generate wgs-only lists
	Rscript 01-generate-independent-specimens-wgs-only.R

	# run script to generate wgs-preferred lists
	Rscript 01-generate-independent-specimens-wgs-preferred.R

	# run script to generate wxs-preferred lists
	Rscript 01-generate-independent-specimens-wxs-preferred.R 

	# run script to generate rnaseq lists
	Rscript 02-generate-independent-rnaseq.R
	
	# run script to generate methylation lists
	Rscript 05-generate-independent-specimens-methyl.R
  
	# run summary on output files
	Rscript -e "rmarkdown::render('03-qc-independent-samples.Rmd', clean = TRUE)"
fi
