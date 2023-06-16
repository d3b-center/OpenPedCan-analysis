#!/bin/bash

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# This option controls whether on not the step that generates the EPN only
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# Define needed files
HISTOLOGIES=../../data/histologies-base.tsv
PATH_DX=epn-subset/EPN_subtyping_path_dx_strings.json
FULL_EXPRESSION=../../data/gene-expression-rsem-tpm-collapsed.rds
SUBSET_EXPRESSION=epn-subset/epn-gene-expression-rsem-tpm-collapsed.tsv.gz
DISEASE_GROUP_FILE=epn-subset/EPN_samples.tsv
GISTIC=../../data/cnv-consensus-gistic.zip
GISTIC_SUBFILE_BROAD=cnv-consensus-gistic/broad_values_by_arm.txt
GSVA=../gene-set-enrichment-analysis/results/gsva_scores.tsv
FUSION=../../data/fusion_summary_ependymoma_foi.tsv
BREAKPOINTS_CNV=../chromosomal-instability/breakpoint-data/cnv_breaks_densities.tsv
BREAKPOINTS_SV=../chromosomal-instability/breakpoint-data/sv_breaks_densities.tsv
FOCAL_GENE_CN=../../data/consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
GISTIC_SUBFILE_FOCALBYGENE=cnv-consensus-gistic/focal_data_by_genes.txt
SNVs=../../data/snv-consensus-plus-hotspots.maf.tsv.gz
EPN_TABLE=results/EPN_all_data.tsv

# make the subset and results directory if they don't exist
mkdir -p epn-subset
mkdir -p results

#generate JSON file
Rscript 00-EPN-select-pathology-dx.R

# subset gene expression data
if [ "$SUBSET" -gt "0" ]; then
  echo "Subsetting  for CI"
  Rscript 00-subset-for-EPN.R -i $HISTOLOGIES -p $PATH_DX -e $FULL_EXPRESSION -o $SUBSET_EXPRESSION
fi

# map DNA and RNA ID's for each participant and assign disease group
echo "Generating epn-subset/EPN_samples.tsv that maps DNA and RNA ID's and assigns disease group"
Rscript 01-assign-disease-group.R \
-p $PATH_DX \
--histology $HISTOLOGIES \
--outfile $DISEASE_GROUP_FILE

# combine data from various output files for EPN samples that can be used to categorize samples under different EPN subtypes
echo "Generating results/EPN_all_data.tsv that has all the relevant data needed for subtyping"
Rscript 02_ependymoma_generate_all_data.R \
--expr_dat=$SUBSET_EXPRESSION \
--disease_group_file=$DISEASE_GROUP_FILE \
--gistic=$GISTIC \
--subfile_gistic_broad=$GISTIC_SUBFILE_BROAD \
--gsva=$GSVA \
--fusion=$FUSION \
--breakpoints_cnv=$BREAKPOINTS_CNV \
--breakpoints_sv=$BREAKPOINTS_SV \
--focal_gene_cn=$FOCAL_GENE_CN \
--subfile_gistic_focalbygene=$GISTIC_SUBFILE_FOCALBYGENE \
--mutations=$SNVs \
--outfile=$EPN_TABLE

# summary of molecular subtypes
Rscript -e "rmarkdown::render('03-summary.Rmd', clean = TRUE)"
