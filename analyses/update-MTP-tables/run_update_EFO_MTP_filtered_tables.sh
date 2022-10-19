#!/bin/bash

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit


# Use the OpenPedCan bucket as the default.
URL=${OPENPEDCAN_URL:-https://s3.amazonaws.com/d3b-openaccess-us-east-1-prd-pbta/open-targets}
FILE_PATH=${MTP_TABLES:-mtp-tables/filtered-for-gencode-v39-and-OT}


filelist=("putative-oncogene-fusion-freq.tsv.gz" "putative-oncogene-fused-gene-freq.tsv.gz" "variant-level-snv-consensus-annotated-mut-freq.tsv.gz" "gene-level-snv-consensus-annotated-mut-freq.tsv.gz" "gene-level-cnv-consensus-annotated-mut-freq.tsv.gz" )


for file in ${filelist[@]}; do
  curl $URL/$FILE_PATH/$file -o $file
done


# Run R script to read files and replace relevant data 
Rscript --vanilla 'update_EFO_MTP_filtered_tables.R'

# Convert resulting jsonl and tsv files to jsonl and compressed files respectively
# Remove the jsonl and tsv files once final files are generated
echo '\n Convert JSON files to JSONL files...'

jq --compact-output '.[]' putative-oncogene-fusion-freq.json > putative-oncogene-fusion-freq.jsonl
  
jq --compact-output '.[]' putative-oncogene-fused-gene-freq.json > putative-oncogene-fused-gene-freq.jsonl
  
jq --compact-output '.[]' variant-level-snv-consensus-annotated-mut-freq.json > variant-level-snv-consensus-annotated-mut-freq.jsonl
  
jq --compact-output '.[]' gene-level-snv-consensus-annotated-mut-freq.json > gene-level-snv-consensus-annotated-mut-freq.jsonl
  
jq --compact-output '.[]' gene-level-cnv-consensus-annotated-mut-freq.json > gene-level-cnv-consensus-annotated-mut-freq.jsonl

jq --compact-output '.[]' long_n_tpm_mean_sd_quantile_gene_wise_zscore.json > long_n_tpm_mean_sd_quantile_gene_wise_zscore.jsonl
  
jq --compact-output '.[]' long_n_tpm_mean_sd_quantile_group_wise_zscore.json > long_n_tpm_mean_sd_quantile_group_wise_zscore.jsonl


echo '\n Remove JSON files...'

rm putative-oncogene-fusion-freq.json
rm putative-oncogene-fused-gene-freq.json
rm variant-level-snv-consensus-annotated-mut-freq.json
rm gene-level-snv-consensus-annotated-mut-freq.json
rm gene-level-cnv-consensus-annotated-mut-freq.json
rm long_n_tpm_mean_sd_quantile_gene_wise_zscore.json
rm long_n_tpm_mean_sd_quantile_group_wise_zscore.json


####### remove previous results if they exsist ##########################
rm -f putative-oncogene-fusion-freq.tsv.gz
rm -f putative-oncogene-fused-gene-freq.tsv.gz
rm -f variant-level-snv-consensus-annotated-mut-freq.tsv.gz
rm -f gene-level-snv-consensus-annotated-mut-freq.tsv.gz
rm -f gene-level-cnv-consensus-annotated-mut-freq.tsv.gz
rm -f long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz
rm -f long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz


# The --no-name option stops the filename and timestamp from being stored in the
# output file. So rerun will have the same file.
echo '\n gzip TSV and JSONL files...'
gzip --no-name putative-oncogene-fusion-freq.tsv
gzip --no-name putative-oncogene-fusion-freq.jsonl

gzip --no-name putative-oncogene-fused-gene-freq.tsv
gzip --no-name putative-oncogene-fused-gene-freq.jsonl

gzip --no-name variant-level-snv-consensus-annotated-mut-freq.tsv
gzip --no-name variant-level-snv-consensus-annotated-mut-freq.jsonl

gzip --no-name gene-level-snv-consensus-annotated-mut-freq.tsv
gzip --no-name gene-level-snv-consensus-annotated-mut-freq.jsonl

gzip --no-name gene-level-cnv-consensus-annotated-mut-freq.tsv
gzip --no-name gene-level-cnv-consensus-annotated-mut-freq.jsonl

gzip --no-name long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv
gzip --no-name long_n_tpm_mean_sd_quantile_gene_wise_zscore.jsonl

gzip --no-name long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv
gzip --no-name long_n_tpm_mean_sd_quantile_group_wise_zscore.jsonl

echo '\n Done running update_EFO_MTP_filtered_tables.sh'




