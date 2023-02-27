#!/bin/bash
# Dave Hill and Eric Wafula OPenPedCan 2023
# Run OpenPedCan modules to generate MTP tables

set -e
set -o pipefail

printf "Start generating mtp tables...\n\n"

# Set MTP Open Targets FTP download links for diseases and targets
version="22.11"
diseases_url="ftp://ftp.ebi.ac.uk/pub/databases/opentargets/platform/$version/output/etl/json/diseases"
targets_url="ftp://ftp.ebi.ac.uk/pub/databases/opentargets/platform/$version/output/etl/json/targets"


# This script should always run as if it were being called from the directory it lives in.
module_dir="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$module_dir" || exit

# Set sratch directory for dowloads and temporary files
scratch_dir="$module_dir/../../scratch"

# Set directories to download diseases and targets json files
json_diseases_dir="$scratch_dir/mtp-json"
mkdir -p $json_diseases_dir
json_targets_dir="$scratch_dir/mtp-json"
mkdir -p $json_targets_dir

# Set directories to convert diseases and targets json files json to csv format
export csv_diseases_dir="$scratch_dir/mtp-csv/diseases"
mkdir -p $csv_diseases_dir
export csv_targets_dir="$scratch_dir/mtp-csv/targets"
mkdir -p $csv_targets_dir

# Recursively download diseases and targets json files
wget -P $json_diseases_dir --recursive --no-parent --no-host-directories --cut-dirs 8 $diseases_url
wget -P $json_targets_dir --recursive --no-parent --no-host-directories --cut-dirs 8 $targets_url

# Convert diseases and targets json files to csv format
cd $json_diseases_dir/diseases
perl -e 'foreach (<*.json>){/(.*)\.json$/; $name = $1; system "dasel -r json -w csv < $_ > $ENV{csv_diseases_dir}/$name.csv";}'
cd $json_targets_dir/targets
perl -e 'foreach (<*.json>){/(.*)\.json$/; $name = $1; system "dasel -r json -w csv < $_ > $ENV{csv_targets_dir}/$name.csv";}'

# Create diseases and targets mapping files
cd $module_dir
Rscript --vanilla 01-mtp-annotations.R
