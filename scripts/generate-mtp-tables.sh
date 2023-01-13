#!/bin/bash
# Eric Wafula, OPenPedCan 2022
# Run OpenPedCan modules to generate MTP tables

set -e
set -o pipefail

printf "Start generating mtp tables...\n\n"

# Use the bucket that contains mtp files
URL="s3://d3b-openaccess-us-east-1-prd-pbta/open-targets"
RELEASE="v11"   
MTP_DIR="mtp-tables"

# This script should always run as if it were being called from
# the directory it lives in.
SCRIPT_DIR="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$SCRIPT_DIR" || exit

# Set directories for modules that generate mtp tables
FUSION_MODULE_DIR=$SCRIPT_DIR/../analyses/fusion-frequencies
SNV_MODULE_DIR=$SCRIPT_DIR/../analyses/snv-frequencies
CNV_MODULE_DIR=$SCRIPT_DIR/../analyses/cnv-frequencies
TPM_MODULE_DIR=$SCRIPT_DIR/../analyses/rna-seq-expression-summary-stats

# Compile all the files that need to be included in the release in one place
# in the scratch directory
SCRATCH_DIR=$SCRIPT_DIR/../scratch
RELEASE_DIR="$SCRATCH_DIR/$MTP_DIR"
mkdir -p $RELEASE_DIR 

# Run fusion-frequencies module and copy over to mpt-tables/ directory on scratch/ 
printf "\n\nGenerating mtp fusion frequencies tables...\n\n"
cd $FUSION_MODULE_DIR
bash run-frequencies.sh
cp results/*.tsv.gz $RELEASE_DIR
cp results/*.jsonl.gz $RELEASE_DIR

# Run snv-frequencies module and copy over to mpt-tables/ directory on scratch/ 
printf "\n\nGenerating mtp snv frequencies tables...\n\n"
cd $SNV_MODULE_DIR
bash run-snv-frequencies.sh
cp results/*.tsv.gz $RELEASE_DIR
cp results/*.jsonl.gz $RELEASE_DIR

# Run cnv-frequencies module
printf "\n\nGenrating mtp cnv frequencies tables...\n\n"
cd $CNV_MODULE_DIR
bash run-cnv-frequencies-analysis.sh
cp results/*.tsv.gz $RELEASE_DIR
cp results/*.jsonl.gz $RELEASE_DIR

# Run rna-seq-expression-summary-stats module
printf "\n\nGenrating mtp tpm tables...\n\n"
cd $TPM_MODULE_DIR
bash run-rna-seq-expression-summary-stats.sh
cp results/*_zscore.tsv.gz $RELEASE_DIR
cp results/*.jsonl.gz $RELEASE_DIR

# Create an md5sum file for all the files in mtp-tables directory
cd $RELEASE_DIR
# Remove old md5sum release file if it exists
rm -f md5sum.txt
# Create a new md5sum release file
md5sum * > md5sum.txt

# Upload all release and commit files s3 bucket in their respective folders
aws s3 cp $RELEASE_DIR/ $URL/$RELEASE/$MTP_DIR --recursive

printf "\nDone generating mtp tables...\n\n"
