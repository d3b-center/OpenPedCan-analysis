#!/bin/bash
# PediatricOpenTargets 2021
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


###################### Filter mutation frequencies tables #######################
printf '\nFiltering mutation frequencies tables...'

Rscript -e "rmarkdown::render('filter-mutation-frequencies-tables.Rmd', \
  clean = TRUE)"

###################### Convert JSON to JSON Lines (JSONL) #######################
printf '\nConvert JSON files to JSONL files...\n'

jq --compact-output '.[]' \
  ${results_path}/variant-level-snv-consensus-annotated-mut-freq.json \
  > ${results_path}/variant-level-snv-consensus-annotated-mut-freq.jsonl

jq --compact-output '.[]' \
  ${results_path}/gene-level-snv-consensus-annotated-mut-freq.json \
  > ${results_path}/gene-level-snv-consensus-annotated-mut-freq.jsonl

jq --compact-output '.[]' \
  ${results_path}/gene-level-cnv-consensus-annotated-mut-freq.json \
  > ${results_path}/gene-level-cnv-consensus-annotated-mut-freq.jsonl

jq --compact-output '.[]' \
  ${results_path}/putative-oncogene-fused-gene-freq.json \
  > ${results_path}/putative-oncogene-fused-gene-freq.jsonl

jq --compact-output '.[]' \
  ${results_path}/putative-oncogene-fusion-freq.json \
  > ${results_path}/putative-oncogene-fusion-freq.jsonl

############################ Removing JSON file ###############################
printf '\nRemove JSON files...\n'

rm ${results_path}/*.json

########################### Compressing JSONL files ###########################
printf '\nCompressing JSONL files...\n'

if ls ${results_path}/*.jsonl.gz &>/dev/null
then 
  rm ${results_path}/*.jsonl.gz 
fi

gzip -v --no-name ${results_path}/*.jsonl

printf '\nAnalysis Done...\n'
