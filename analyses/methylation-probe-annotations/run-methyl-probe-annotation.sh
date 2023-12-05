#!/bin/bash
# PediatricOpenTargets 2023
# Eric Wafula
set -e
set -o pipefail


# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit


# Set up paths to input and output directories for the analysis
absolute_path=$(cd "$(dirname "$0")"; pwd -P)
data_dir="${absolute_path}/../../data"
inputs_dir="inputs"
results_dir="results"

# create tmp/ directory for R scripts
mkdir -p -m775 ${results_dir}


printf '\nStarting Analysis...\n\n'


# download Illumina methylation CpG probe manifest to the inputs directory
# from the OpenPedCan data v12 data release s3 bucket
URL="https://d3b-openaccess-us-east-1-prd-pbta.s3.amazonaws.com/open-targets"
RELEASE="v12"
MANIFEST="infinium-methylationepic-v-1-0-b5-manifest-file-csv.zip"
if [ -f "${inputs_dir}/${MANIFEST}" ]; then
    echo "${MANIFEST} exists, skip downloading"
else 
    echo "${MANIFEST} does not exist, downloading..."
    wget ${URL}/${RELEASE}/${MANIFEST} -P ${inputs_dir}/
fi


# set up paths output files
gencode_introns_gff="${inputs_dir}/gencode.v39.primary_assembly.introns.annotation.gff3.gz"
bedtools_intersect="${results_dir}/infinium.gencode.v39.probe.annotations.bedtools.tsv.gz"


# add intron coordinates to gencode gff
gt gff3 -retainids -addintrons \
  ${inputs_dir}/gencode.v39.primary_assembly.annotation.gff3.gz \
  | gzip -f \
  > $gencode_introns_gff 


# create gencode features and cpg probe coordinates bed files
Rscript --vanilla 01-create-bed-files.R \
  --gencode_gtf ${data_dir}/gencode.v39.primary_assembly.annotation.gtf.gz \
  --gencode_gff ${inputs_dir}/gencode.v39.primary_assembly.introns.annotation.gff3.gz \
  --cpg_map ${inputs_dir}/infinium-methylationepic-v-1-0-b5-manifest-file-csv.zip


# create intersection bed file between gene features and cpg grch38 liftover bed files
bedtools intersect -loj \
  -a ${inputs_dir}/infinium-methylationepic-v-1-0-b5-manifest-file-grch38.bed \
  -b ${inputs_dir}/gencode.v39.primary_assembly.gene_features.annotation.bed \
  | gzip -f \
  > $bedtools_intersect


# create methyl probe annotations file
Rscript --vanilla 02-parse-bedtools-intersect.R \
  --bed_intersect ${results}/infinium.gencode.v39.probe.annotations.bedtools.tsv.gz


printf '\nAnalysis Done...\n'
