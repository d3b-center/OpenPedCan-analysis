#!/bin/bash

set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Module author: Sangeeta Shukla, Alvin Farrell
# Shell script author: Sangeeta Shukla
# 2021

# This script verifies if all the expected histology+cancer_group  DESeq comparisons were performed successfully


# Initialize variables with filenames
deseq_results_file="gene-counts-rsem-expected_count-collapsed-deseq.tsv"
deseq_comparisonid_file="deseq_v12_comparisonId_final_qc.txt"

deseq_expected_comparisonid_file="Input_Data/filelist_expected.txt"

spotcheck_out_file="deseq_v12_qc_spotcheck.tsv"

hist_index_limit="Input_Data/Hist_Index_limit.txt"
gtex_index_limit="Input_Data/GTEx_Index_limit.txt"

printf "Extracting list of processed comparisonIds\n"

# Copy all the comaparisonId from the final merged deseq result table into a file
awk -F "\t" 'NR >1 {print $10}' ${deseq_results_file} | uniq | sort | uniq > $deseq_comparisonid_file

printf "Verifying list of expected and processed comparisonIds\n"


# Parse both expected and processed list of comparison IDs to R script to compare
module load R/4.1.0
Rscript --vanilla QC_DESeq_results.R  \
	--expected_comparisonid $deseq_expected_comparisonid_file \
	--processed_comparisonid $deseq_comparisonid_file \
	--HIST_i_file $hist_index_limit \
	--GTEX_i_file $gtex_index_limit

# Generate a file with Deseq results for specific comparisons to be used for spot checking
printf "ComparisonID\tGene_Symbol\tbaseMean\tlog2FoldChange\tlfcStstat\tpvalue\tpadj\n" > $spotcheck_out_file

printf "Extracting data for Osteosarcoma in Cells - Cultured fibroblasts\n"
awk -F "\t" -v OFS="\t" '$4 =="MYCN" && $10 =="all_cohorts_Osteosarcoma_v_Cells_-_Cultured_fibroblasts" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="PHOX2B" && $10 =="all_cohorts_Osteosarcoma_v_Cells_-_Cultured_fibroblasts" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="TBX2" && $10 =="all_cohorts_Osteosarcoma_v_Cells_-_Cultured_fibroblasts" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="GATA3" && $10 =="all_cohorts_Osteosarcoma_v_Cells_-_Cultured_fibroblasts" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="IGF2BP1" && $10 =="all_cohorts_Osteosarcoma_v_Cells_-_Cultured_fibroblasts" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="IGF2BP3" && $10 =="all_cohorts_Osteosarcoma_v_Cells_-_Cultured_fibroblasts" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file




printf "Extracting data for Neuroblastoma in Adipose - Subcutaneous\n"
awk -F "\t" -v OFS="\t" '$4 =="MYCN" && $10 =="all_cohorts_Neuroblastoma_v_Adipose_-_Subcutaneous" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="PHOX2B" && $10 =="all_cohorts_Neuroblastoma_v_Adipose_-_Subcutaneous" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="TBX2" && $10 =="all_cohorts_Neuroblastoma_v_Adipose_-_Subcutaneous" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="GATA3" && $10 =="all_cohorts_Neuroblastoma_v_Adipose_-_Subcutaneous" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="IGF2BP1" && $10 =="all_cohorts_Neuroblastoma_v_Adipose_-_Subcutaneous" {print $10,$4,$17,$18,$19,$20,$21,$22}' $deseq_results_file >> $spotcheck_out_file

awk -F "\t" -v OFS="\t" '$4 =="IGF2BP3" && $10 =="all_cohorts_Neuroblastoma_v_Adipose_-_Subcutaneous" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}



printf "Extracting data for Osteosarcoma in Kidney - Cortex\n"
awk -F "\t" -v OFS="\t" '$4 =="MYCN" && $10 =="all_cohorts_Osteosarcoma_v_Kidney_-_Cortex" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}

awk -F "\t" -v OFS="\t" '$4 =="PHOX2B" && $10 =="all_cohorts_Osteosarcoma_v_Kidney_-_Cortex" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}

awk -F "\t" -v OFS="\t" '$4 =="TBX2" && $10 =="all_cohorts_Osteosarcoma_v_Kidney_-_Cortex" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}

awk -F "\t" -v OFS="\t" '$4 =="GATA3" && $10 =="all_cohorts_Osteosarcoma_v_Kidney_-_Cortex" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}

awk -F "\t" -v OFS="\t" '$4 =="IGF2BP1" && $10 =="all_cohorts_Osteosarcoma_v_Kidney_-_Cortex" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}

awk -F "\t" -v OFS="\t" '$4 =="IGF2BP3" && $10 =="all_cohorts_Osteosarcoma_v_Kidney_-_Cortex" {print $10,$4,$17,$18,$19,$20,$21,$22}' ${deseq_results_file} >> ${spotcheck_out_file}


printf "DESeq QC complete.\n"
