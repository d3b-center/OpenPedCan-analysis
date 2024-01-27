#!/bin/bash
# J. Taroni for CCDL 2019
# Updated by Eric Wafula for Pediatric Open Targets 2022
# Create subset files for continuous integration

set -e
set -o pipefail

# Set defaults for release and biospecimen file name
BIOSPECIMEN_FILE=${BIOSPECIMEN_FILE:-biospecimen_ids_for_subset.RDS}
RELEASE=${RELEASE:-v13}
NUM_MATCHED=${NUM_MATCHED:-15}

# This option controls whether or not the two larger MAF files are skipped as
# part of subsetting -- the idea is that setting RUN_LOCAL=1 will allow for
# local testing
RUN_LOCAL=${RUN_LOCAL:-0}

# Use SKIP_SUBSETTING=1 to skip the subsetting steps and only copy full files
# and generate a new md5sum.txt file - this can be useful if the only files
# getting updated in a release are those that are copied in full
SKIP_SUBSETTING=${SKIP_SUBSETTING:-0}

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# directories that hold the full files for the release and the subset files
# generated via these scripts
DATA_DIRECTORY=../../data
FULL_DIRECTORY=../../data/$RELEASE
SUBSET_DIRECTORY=../../data/testing/$RELEASE
# If run subsetting only, we need to make this directory
if [ ! -d ${SUBSET_DIRECTORY} ]; then
    mkdir -p ${SUBSET_DIRECTORY}
fi

# download Illumina methylation annotations file if does not exist in data
# from the data release s3 bucket
URL="https://d3b-openaccess-us-east-1-prd-pbta.s3.amazonaws.com/open-targets"
PROBES="infinium.gencode.v39.probe.annotations.tsv.gz"
if [ -f "${DATA_DIRECTORY}/${PROBES}" ]; then
    echo "${PROBES} exists, skip downloading"
else 
    echo "${PROBES} does not exist, downloading..."
    wget ${URL}/${RELEASE}/${PROBES} -P ${FULL_DIRECTORY}/
    # create symlink to data
    ln -sfn $RELEASE/$PROBES ../../data/$PROBES
fi



#### generate subset files -----------------------------------------------------

# overide system /tmp directory and create ./tmp directory for the R script
# in some case system /tmp directory is too small
RTMP_DIRECTORY=./tmp
if [ ! -d ${RTMP_DIRECTORY} ]; then
    mkdir -m777 ${RTMP_DIRECTORY}
fi

if [ "$SKIP_SUBSETTING" -lt "1" ]; then

  # get list of biospecimen ids for subset files
  TMPDIR=./tmp Rscript --vanilla 01-get_biospecimen_identifiers.R \
      --data_directory $FULL_DIRECTORY \
      --output_file $BIOSPECIMEN_FILE \
      --num_matched $NUM_MATCHED \
      --local $RUN_LOCAL

  # subset the files
  TMPDIR=./tmp Rscript --vanilla 02-subset_files.R \
    --biospecimen_file $BIOSPECIMEN_FILE \
    --output_directory $SUBSET_DIRECTORY

fi

rm -rf $RTMP_DIRECTORY

#### copy files that are not being subset --------------------------------------

# histologies file
cp $FULL_DIRECTORY/histologies.tsv $SUBSET_DIRECTORY

# base histologies file
cp $FULL_DIRECTORY/histologies-base.tsv $SUBSET_DIRECTORY

# annotation files
cp $FULL_DIRECTORY/uberon-map-gtex-*.tsv $SUBSET_DIRECTORY
cp $FULL_DIRECTORY/efo-mondo-map.tsv $SUBSET_DIRECTORY
cp $FULL_DIRECTORY/ensg-hugo-pmtl-mapping.tsv $SUBSET_DIRECTORY
cp $FULL_DIRECTORY/infinium.gencode.v39.probe.annotations.tsv.gz $SUBSET_DIRECTORY

# GISTIC output
cp $FULL_DIRECTORY/cnv-consensus-gistic.zip $SUBSET_DIRECTORY

# all bed files
cp $FULL_DIRECTORY/*.bed $SUBSET_DIRECTORY

# DGD fusion file
cp $FULL_DIRECTORY/fusion-dgd.tsv.gz $SUBSET_DIRECTORY

# All proteomic files
cp $FULL_DIRECTORY/*protein* $SUBSET_DIRECTORY

# miRNA files
cp $FULL_DIRECTORY/*mirna* $SUBSET_DIRECTORY

# Full tumor only MAF (for now, it is small)
cp $FULL_DIRECTORY/snv-mutect2-tumor-only-plus-hotspots.maf.tsv.gz $SUBSET_DIRECTORY

# if the md5sum.txt file already exists, get rid of it
cd $SUBSET_DIRECTORY
rm -f md5sum.txt
# create a new md5sum.txt file
md5sum * > md5sum.txt
cd "$script_directory" || exit

# the release notes are not included in md5sum.txt
cp $FULL_DIRECTORY/release-notes.md $SUBSET_DIRECTORY

# Upload all testing files s3 bucket in their respective folders (example)
# aws s3 cp data/testing/$RELEASE s3://d3b-openaccess-us-east-1-prd-pbta/open-targets/testing --recursive

