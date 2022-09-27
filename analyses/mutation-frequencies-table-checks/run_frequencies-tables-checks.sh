#!/bin/bash
# OPenPedCan 2022
# Eric Wafula
set -e
set -o pipefail


printf "Start QC and Summary checks...\n\n"


# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit


# Set up paths to output directory for the analysis
results_dir="results"


######################### Checking cnv gene-level frequencies table #############################
printf "Checking cnv gene-level frequencies...\n\n"

Rscript -e "rmarkdown::render(
            '01-frequencies-tables-checks.Rmd',
            params = list(
              current_table = 'current/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz', 
              previous_table = 'previous/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz'),  
              output_file = 'gene-level-cnv-consensus-annotated-mut-freq-checks.nb.html',
              clean = TRUE)"

# remove intermediate files
rm ${results_dir}/*.tsv

             
######################### Checking snv gene-level frequencies table #############################
printf "Checking snv gene-level frequencies...\n\n"

Rscript -e "rmarkdown::render(
            '01-frequencies-tables-checks.Rmd',
            params = list(
              current_table = 'current/gene-level-snv-consensus-annotated-mut-freq.tsv.gz', 
              previous_table = 'previous/gene-level-snv-consensus-annotated-mut-freq.tsv.gz'),  
              output_file = 'gene-level-snv-consensus-annotated-mut-freq-checks.nb.html',
              clean = TRUE)"            

# remove intermediate files
rm ${results_dir}/*.tsv

              
######################### Checking snv variant-level frequencies table ##########################
printf "Checking snv variant-level frequencies...\n\n"

Rscript -e "rmarkdown::render(
            '01-frequencies-tables-checks.Rmd',
            params = list(
              current_table = 'current/variant-level-snv-consensus-annotated-mut-freq.tsv.gz', 
              previous_table = 'previous/variant-level-snv-consensus-annotated-mut-freq.tsv.gz'),  
              output_file = 'variant-level-snv-consensus-annotated-mut-freq-checks.nb.html',
              clean = TRUE)"

# remove intermediate files
rm ${results_dir}/*.tsv


######################### Checking putative fused gene frequencies table ##########################
printf "Checking putative fused gene frequencies...\n\n"

Rscript -e "rmarkdown::render(
            '01-frequencies-tables-checks.Rmd',
            params = list(
              current_table = 'current/putative-oncogene-fused-gene-freq.tsv.gz', 
              previous_table = 'previous/putative-oncogene-fused-gene-freq.tsv.gz'),  
              output_file = 'putative-oncogene-fused-gene-freq-checks.nb.html',
              clean = TRUE)"

# remove intermediate files
rm ${results_dir}/*.tsv


######################### Checking putative fused gene frequencies table ##########################
printf "Checking putative fused gene frequencies...\n\n"

Rscript -e "rmarkdown::render(
            '01-frequencies-tables-checks.Rmd',
            params = list(
              current_table = 'current/putative-oncogene-fusion-freq.tsv.gz', 
              previous_table = 'previous/putative-oncogene-fusion-freq.tsv.gz'),  
              output_file = 'putative-oncogene-fusion-freq-checks.nb.html',
              clean = TRUE)"  
              
# remove intermediate files
rm ${results_dir}/*.tsv

              
printf "Analysis Done...\n"  
