# Chante Bethell for CCDL 2019
# Run 01-plot-oncoprint.R
#
# Usage: bash run-oncoprint.sh

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# For the genes lists
# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function join_by { local IFS="$1"; shift; echo "$*"; }

#### Files

maf_consensus=../../data/snv-consensus-plus-hotspots.maf.tsv.gz
# will be replaced by real data when fusion_filtering module is updated for OT
fusion_file=input/empty-fusion-putative-oncogenic.tsv
histologies_file=../../data/histologies.tsv
intermediate_directory=../../scratch/oncoprint_files
primary_filename="primary_only"
primaryplus_filename="primary-plus"
# # may be useful when focal-cn-file-preparation is updated for OT
# focal_directory=../focal-cn-file-preparation/results
# focal_cnv_file=${focal_directory}/consensus_seg_most_focal_cn_status.tsv.gz
focal_cnv_file=input/empty_consensus_seg_most_focal_cn_status.tsv

# each element of the array is a file that contains genes of interest
# Note by @logstar 06/24/2021:
# Use these two gene lists temporarily for generating plots. Output mutation
# frequency tables for all genes. These gene lists may be updated in the future
# using OT data release.
genes_list=("../interaction-plots/results/gene_disease_top50.tsv" \
            "../focal-cn-file-preparation/results/consensus_seg_focal_cn_recurrent_genes.tsv")
# join into a string, where file paths are separated by commas
genes_list=$(join_by , "${genes_list[@]}")

### Primary only samples mapping for oncoprint

Rscript --vanilla 00-map-to-sample_id.R \
  --maf_file ${maf_consensus} \
  --cnv_file ${focal_cnv_file} \
  --fusion_file ${fusion_file} \
  --metadata_file ${histologies_file} \
  --output_directory ${intermediate_directory} \
  --filename_lead ${primary_filename} \
  --independent_specimens ../independent-samples/results/independent-specimens.wgs.primary.tsv


#### Primary plus samples mapping for oncoprint

Rscript --vanilla 00-map-to-sample_id.R \
  --maf_file ${maf_consensus} \
  --cnv_file ${focal_cnv_file} \
  --fusion_file ${fusion_file} \
  --metadata_file ${histologies_file} \
  --output_directory ${intermediate_directory} \
  --filename_lead ${primaryplus_filename} \
  --independent_specimens ../independent-samples/results/independent-specimens.wgs.primary-plus.tsv

# Handle histologies in the R script
# # Print oncoprints by broad histology
# for histology in "Low-grade astrocytic tumor" \
# "Embryonal tumor" \
# "Diffuse astrocytic and oligodendroglial tumor" \
# "Ependymal tumor" \
# "Other CNS"
# do
#
#   --broad_histology "$histology"

# handle plot name in the r script
#   --png_name ${primary_filename}_"${histology}"_goi_oncoprint.png \


# primary only oncoprints plot and mutation tables
Rscript --vanilla 01-plot-oncoprint.R \
  --maf_file ${intermediate_directory}/${primary_filename}_maf.tsv \
  --cnv_file ${intermediate_directory}/${primary_filename}_cnv.tsv \
  --fusion_file ${intermediate_directory}/${primary_filename}_fusions.tsv \
  --metadata_file ${histologies_file} \
  --goi_list ${genes_list} \
  --output_prefix ${primary_filename}


# primary plus oncoprints plot and mutation tables
Rscript --vanilla 01-plot-oncoprint.R \
  --maf_file ${intermediate_directory}/${primaryplus_filename}_maf.tsv \
  --cnv_file ${intermediate_directory}/${primaryplus_filename}_cnv.tsv \
  --fusion_file ${intermediate_directory}/${primaryplus_filename}_fusions.tsv \
  --metadata_file ${histologies_file} \
  --goi_list ${genes_list} \
  --output_prefix ${primaryplus_filename}


# done
