#!/bin/bash
# Eric Wafula
# Pediatric OpenTargets 2021

# Purpose: Run a CNV consensus gene-level frequecies anaysis for PediatricOpenTargets

# Set this so the whole loop stops if there is an error
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Set up paths to data files consumed by analysis
data_dir="../../data"

# Set up paths to to write result files 
results_dir="./results"

# Histology file path 
histology_file="${data_dir}/histologies.tsv"

# CNV consensus file path
cnv_file="${data_dir}/consensus_wgs_plus_cnvkit_wxs.tsv.gz"

# All cohorts independent primary tumor samples file path
all_cohorts_primary_tumors="${data_dir}/independent-specimens.wgswxspanel.primary.prefer.wgs.tsv"

# All cohorts independent relapse tumor samples file path
all_cohorts_relapse_tumors="${data_dir}/independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv"

# Each cohort independent primary tumor samples file path
each_cohort_primary_tumors="${data_dir}/independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv"

# Each cohort independent relapse tumor samples file path
each_cohort_relapse_tumors="${data_dir}/independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv"

####### remove previous results if they exsist ##########################
rm -f ${results_dir}/gene-level-cnv-consensus-annotated-mut-freq.jsonl.gz
rm -f ${results_dir}/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz

####### compute CNV frequencies #########################################
python3 01-cnv-frequencies.py \
	$histology_file \
	$cnv_file \
	$all_cohorts_primary_tumors \
	$all_cohorts_relapse_tumors \
	$each_cohort_primary_tumors \
	$each_cohort_relapse_tumors

####### compress the result files #######################################
gzip ${results_dir}/gene-level-cnv-consensus-annotated-mut-freq*

####### remove intermediate temporary and log files #####################
rm -f ${results_dir}/annotator.log
rm -f ${results_dir}/gene-level-cnv-consensus-mut-freq.tsv
