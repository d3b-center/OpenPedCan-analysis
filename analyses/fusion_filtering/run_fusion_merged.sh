#!/bin/bash

# K S Gaonkar

# Run fusion_filtering
# Takes one environment variable, `OPENPBTA_BASE_SUBTYPING`, if value is 1 then
# uses pbta-histologies-base.tsv for subtyping if value is 0 runs all modules (Default)
# with pbta-histologies.tsv

set -e
set -o pipefail

RUN_FOR_SUBTYPING=${OPENPBTA_BASE_SUBTYPING:-0}

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Set up paths to data files consumed by analysis, and path to result output
data_path="../../data"
scratch_path="../../scratch"
results_path="results/"


# fusion files before and after standardization
arriba_file="${data_path}/fusion-arriba.tsv.gz"
starfusion_file="${data_path}/fusion-starfusion.tsv.gz"
annofuse_file="${data_path}/fusion-annoFuse.tsv.gz"


# general filtering parameters
artifact_filter="DGD_PARALOGS|Normal|BodyMap"
reading_frame_filter="in-frame|frameshift|other"
spanningFragCountFilter=100


# relevant gene expression files
rna_expression_file="${data_path}/gene-expression-rsem-tpm-collapsed.rds"

# reference expression file
gtex_file="${data_path}/gtex_gene-expression-rsem-tpm-collapsed.rds"

# independent sample list
independent_RNA_primary="${data_path}/independent-specimens.rnaseq.primary-pre-release.tsv"
independent_RNA_relapse="${data_path}/independent-specimens.rnaseq.relapse-pre-release.tsv"
   
# metadata files
if [[ "$RUN_FOR_SUBTYPING" -eq "0" ]]
then
   histologies_file="${data_path}/histologies.tsv"
else
   histologies_file="${data_path}/histologies-base.tsv"
fi

# data release files to use for recurrent fusion/fused genes detection

putative_oncogenic_fusion="${results_path}/fusion-putative-oncogenic.tsv"


# Project specific filtering
Rscript -e "rmarkdown::render('04-project-specific-filtering.Rmd',params=list(base_run = $RUN_FOR_SUBTYPING))"

# QC filter putative oncogene found in more than 4 histologies
Rscript -e "rmarkdown::render('05-QC_putative_onco_fusion_distribution.Rmd',params=list(base_run = $RUN_FOR_SUBTYPING))"

# Recurrent fusion/fused genes
Rscript 06-recurrent-fusions-sample-group.R --standardFusionCalls $putative_oncogenic_fusion \
                                            --clinicalFile $histologies_file \
                                            --cohortInterest "PBTA,GMKF,TARGET" \
                                            --outputfolder $results_path \
                                            --independentPrimary $independent_RNA_primary \
                                            --independentRelapse $independent_RNA_relapse

